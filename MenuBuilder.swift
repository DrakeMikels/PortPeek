//
//  MenuBuilder.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Cocoa

/// Builds the menu bar dropdown menu based on scan results
class MenuBuilder {
    
    weak var delegate: MenuBuilderDelegate?
    
    /// Builds a complete menu from scan results
    func buildMenu(scanResult: ScanResult, watchedPorts: [Int], showInactivePorts: Bool) -> NSMenu {
        let menu = NSMenu()
        
        // Header
        addHeader(to: menu, scanResult: scanResult)
        menu.addItem(NSMenuItem.separator())
        
        // Active Ports Section
        if scanResult.activePorts.isEmpty {
            if let error = scanResult.error {
                addErrorItem(to: menu, error: error)
            } else {
                addNoActivePortsItem(to: menu)
            }
        } else {
            addActivePortsSection(to: menu, activePorts: scanResult.activePorts)
        }
        
        // Inactive Ports Section (optional)
        if showInactivePorts {
            let inactivePorts = getInactivePorts(watchedPorts: watchedPorts, activePorts: scanResult.activePorts)
            if !inactivePorts.isEmpty {
                menu.addItem(NSMenuItem.separator())
                addInactivePortsSection(to: menu, inactivePorts: inactivePorts)
            }
        }
        
        // Footer
        menu.addItem(NSMenuItem.separator())
        addFooter(to: menu)
        
        return menu
    }
    
    // MARK: - Header
    
    private func addHeader(to menu: NSMenu, scanResult: ScanResult) {
        let titleItem = NSMenuItem(title: "PortPeek", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        let subtitle = scanResult.isSuccess ? "Updated \(scanResult.relativeTimeString)" : "Scan failed"
        let subtitleItem = NSMenuItem(title: subtitle, action: nil, keyEquivalent: "")
        subtitleItem.isEnabled = false
        
        // Make subtitle slightly smaller/grayed
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        subtitleItem.attributedTitle = NSAttributedString(string: subtitle, attributes: attributes)
        
        menu.addItem(subtitleItem)
    }
    
    // MARK: - Active Ports
    
    private func addActivePortsSection(to menu: NSMenu, activePorts: [PortInfo]) {
        var seen = Set<String>()
        let uniquePorts = activePorts.filter { info in
            let key = "\(info.port)-\(info.pid)-\(info.processName)"
            return seen.insert(key).inserted
        }
        let sortedPorts = uniquePorts.sorted { $0.port < $1.port }
        
        for portInfo in sortedPorts {
            let portItem = createPortMenuItem(portInfo: portInfo)
            menu.addItem(portItem)
        }
    }
    
    private func createPortMenuItem(portInfo: PortInfo) -> NSMenuItem {
        let title = "\(portInfo.port)  \(portInfo.processName)"
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        
        // Make port number bold
        let titleFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let boldFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        
        let portString = "\(portInfo.port)"
        let attributedTitle = NSMutableAttributedString(string: title)
        attributedTitle.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: portString.count))
        attributedTitle.addAttribute(.font, value: titleFont, range: NSRange(location: portString.count, length: title.count - portString.count))
        
        item.attributedTitle = attributedTitle
        
        // Create submenu with actions
        let submenu = NSMenu()
        
        // Subtitle (not in submenu, but we'll add it as disabled item for context)
        let pidText = portInfo.pid > 0 ? String(portInfo.pid) : "n/a"
        let subtitle = "PID \(pidText) • \(portInfo.user) • \(portInfo.protocolType)"
        let subtitleItem = NSMenuItem(title: subtitle, action: nil, keyEquivalent: "")
        subtitleItem.isEnabled = false
        
        let subtitleFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        subtitleItem.attributedTitle = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        submenu.addItem(subtitleItem)
        submenu.addItem(NSMenuItem.separator())
        
        // Open in Browser
        let openURLItem = NSMenuItem(title: "Open in Browser", action: #selector(MenuBuilderDelegate.openURL(_:)), keyEquivalent: "")
        openURLItem.target = delegate
        openURLItem.representedObject = portInfo
        submenu.addItem(openURLItem)
        
        // Copy Host:Port
        let copyHostPortItem = NSMenuItem(title: "Copy Host:Port", action: #selector(MenuBuilderDelegate.copyHostPort(_:)), keyEquivalent: "")
        copyHostPortItem.target = delegate
        copyHostPortItem.representedObject = portInfo
        submenu.addItem(copyHostPortItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        if portInfo.pid > 0 {
            // Kill Process
            let killItem = NSMenuItem(title: "Kill Process (SIGTERM)", action: #selector(MenuBuilderDelegate.killProcess(_:)), keyEquivalent: "")
            killItem.target = delegate
            killItem.representedObject = portInfo
            submenu.addItem(killItem)
            
            // Force Kill
            let forceKillItem = NSMenuItem(title: "Force Kill (SIGKILL)", action: #selector(MenuBuilderDelegate.forceKillProcess(_:)), keyEquivalent: "")
            forceKillItem.target = delegate
            forceKillItem.representedObject = portInfo
            submenu.addItem(forceKillItem)
        } else {
            let unavailableItem = NSMenuItem(title: "Process controls unavailable", action: nil, keyEquivalent: "")
            unavailableItem.isEnabled = false
            submenu.addItem(unavailableItem)
        }
        
        item.submenu = submenu
        return item
    }
    
    // MARK: - Inactive Ports
    
    private func addInactivePortsSection(to menu: NSMenu, inactivePorts: [Int]) {
        let sectionTitle = NSMenuItem(title: "Inactive Ports", action: nil, keyEquivalent: "")
        sectionTitle.isEnabled = false
        menu.addItem(sectionTitle)
        
        let sortedPorts = inactivePorts.sorted()
        for port in sortedPorts {
            let item = NSMenuItem(title: "\(port) (inactive)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
            item.attributedTitle = NSAttributedString(string: "\(port) (inactive)", attributes: attributes)
            
            menu.addItem(item)
        }
    }
    
    private func getInactivePorts(watchedPorts: [Int], activePorts: [PortInfo]) -> [Int] {
        let activePorts = Set(activePorts.map { $0.port })
        return watchedPorts.filter { !activePorts.contains($0) }
    }
    
    // MARK: - Error/Empty States
    
    private func addNoActivePortsItem(to menu: NSMenu) {
        let item = NSMenuItem(title: "No active ports", action: nil, keyEquivalent: "")
        item.isEnabled = false
        
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        item.attributedTitle = NSAttributedString(string: "No active ports", attributes: attributes)
        
        menu.addItem(item)
    }
    
    private func addErrorItem(to menu: NSMenu, error: String) {
        let item = NSMenuItem(title: "Port scanning unavailable", action: nil, keyEquivalent: "")
        item.isEnabled = false
        
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.systemRed
        ]
        item.attributedTitle = NSAttributedString(string: "Port scanning unavailable", attributes: attributes)
        
        menu.addItem(item)
        
        // Add error detail as subtitle
        let errorItem = NSMenuItem(title: error, action: nil, keyEquivalent: "")
        errorItem.isEnabled = false
        
        let errorFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let errorAttributes: [NSAttributedString.Key: Any] = [
            .font: errorFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        errorItem.attributedTitle = NSAttributedString(string: error, attributes: errorAttributes)
        
        menu.addItem(errorItem)
    }
    
    // MARK: - Footer
    
    private func addFooter(to menu: NSMenu) {
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(MenuBuilderDelegate.refreshNow), keyEquivalent: "r")
        refreshItem.target = delegate
        menu.addItem(refreshItem)
        
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(MenuBuilderDelegate.openSettings), keyEquivalent: ",")
        settingsItem.target = delegate
        menu.addItem(settingsItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(MenuBuilderDelegate.quitApp), keyEquivalent: "q")
        quitItem.target = delegate
        menu.addItem(quitItem)
    }
}

// MARK: - Delegate Protocol

@objc protocol MenuBuilderDelegate: AnyObject {
    func openURL(_ sender: NSMenuItem)
    func copyHostPort(_ sender: NSMenuItem)
    func killProcess(_ sender: NSMenuItem)
    func forceKillProcess(_ sender: NSMenuItem)
    func refreshNow()
    func openSettings()
    func quitApp()
}
