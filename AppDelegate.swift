//
//  AppDelegate.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private let scanner = PortScanner()
    private let processKiller = ProcessKiller()
    private let menuBuilder = MenuBuilder()
    private var refreshTimer: Timer?
    private var currentScanResult: ScanResult?
    private var settingsWindowController: SettingsWindowController?
    private var isMenuOpen = false
    private var pendingMenuRefresh = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 PortPeek: App launched!")
        
        // Observe preferences changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
        
        print("📍 PortPeek: Creating status item...")
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use a simple text icon for now (can be replaced with image later)
            button.title = "⚡︎"
            print("✅ PortPeek: Status item created with button!")
        } else {
            print("❌ PortPeek: Failed to create status item button!")
        }
        
        setPlaceholderMenu()
        
        // Set up menu builder delegate
        menuBuilder.delegate = self
        
        // Perform initial scan
        performScan()
        
        // Start refresh timer
        startRefreshTimer()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        stopRefreshTimer()
    }
    
    // MARK: - Status Item
    
    @objc private func statusItemClicked() {
        // Scan on menu open
        performScan()
    }
    
    // MARK: - Scanning
    
    private func performScan() {
        let watchedPorts = Preferences.shared.watchedPorts
        
        Task {
            let result = await scanner.scan(ports: watchedPorts)
            
            await MainActor.run {
                self.currentScanResult = result
                if self.isMenuOpen {
                    self.pendingMenuRefresh = true
                } else {
                    self.updateMenu()
                }
            }
        }
    }
    
    private func updateMenu() {
        guard let result = currentScanResult else { return }
        
        let watchedPorts = Preferences.shared.watchedPorts
        let showInactivePorts = Preferences.shared.showInactivePorts
        
        let menu = menuBuilder.buildMenu(
            scanResult: result,
            watchedPorts: watchedPorts,
            showInactivePorts: showInactivePorts
        )
        
        menu.delegate = self
        statusItem.menu = menu
    }
    
    // MARK: - Timer
    
    private func startRefreshTimer() {
        stopRefreshTimer()
        
        let interval = Preferences.shared.refreshInterval
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.performScan()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func setPlaceholderMenu() {
        let menu = NSMenu()
        let loadingItem = NSMenuItem(title: "Scanning…", action: nil, keyEquivalent: "")
        loadingItem.isEnabled = false
        menu.addItem(loadingItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
    }
    
    // MARK: - Alert Helper
    
    private func showAlert(title: String, message: String, style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showConfirmation(title: String, message: String, confirmButtonTitle: String, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: confirmButtonTitle)
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
}

// MARK: - MenuBuilderDelegate

extension AppDelegate: MenuBuilderDelegate {
    
    @objc func openURL(_ sender: NSMenuItem) {
        guard let portInfo = sender.representedObject as? PortInfo else { return }
        guard let url = URL(string: portInfo.url) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc func copyHostPort(_ sender: NSMenuItem) {
        guard let portInfo = sender.representedObject as? PortInfo else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(portInfo.hostPort, forType: .string)
    }
    
    @objc func killProcess(_ sender: NSMenuItem) {
        guard let portInfo = sender.representedObject as? PortInfo else { return }
        
        let title = "Kill Process?"
        let message = "Send SIGTERM to \(portInfo.processName) (PID \(portInfo.pid))?\n\nThis will attempt to gracefully terminate the process."
        
        showConfirmation(title: title, message: message, confirmButtonTitle: "Kill Process") { [weak self] confirmed in
            guard confirmed else { return }
            self?.performKill(portInfo: portInfo, signal: .term)
        }
    }
    
    @objc func forceKillProcess(_ sender: NSMenuItem) {
        guard let portInfo = sender.representedObject as? PortInfo else { return }
        
        let title = "Force Kill Process?"
        let message = "Send SIGKILL to \(portInfo.processName) (PID \(portInfo.pid))?\n\nThis will forcefully terminate the process immediately. Use this only if the process doesn't respond to normal termination."
        
        showConfirmation(title: title, message: message, confirmButtonTitle: "Force Kill") { [weak self] confirmed in
            guard confirmed else { return }
            self?.performKill(portInfo: portInfo, signal: .kill)
        }
    }
    
    private func performKill(portInfo: PortInfo, signal: ProcessKiller.Signal) {
        let result = processKiller.kill(pid: portInfo.pid, signal: signal)
        
        switch result {
        case .success:
            // Refresh after a short delay to show the process is gone
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.performScan()
            }
            
        case .failure(let error):
            var message = error.localizedDescription
            if let suggestion = error.recoverySuggestion {
                message += "\n\n\(suggestion)"
            }
            showAlert(title: "Couldn't Stop Process", message: message)
        }
    }
    
    @objc func refreshNow() {
        performScan()
    }
    
    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func preferencesDidChange() {
        // Restart timer with new interval
        startRefreshTimer()
        // Refresh to pick up new settings
        performScan()
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        performScan()
    }
    
    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
        guard pendingMenuRefresh else { return }
        pendingMenuRefresh = false
        updateMenu()
    }
}
