//
//  SettingsWindowController.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Cocoa

class SettingsWindowController: NSWindowController {
    
    private var settingsViewController: SettingsViewController!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PortPeek Settings"
        window.center()
        
        self.init(window: window)
        
        settingsViewController = SettingsViewController()
        window.contentViewController = settingsViewController
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class SettingsViewController: NSViewController {
    
    private var portsTextView: NSTextView!
    private var portsScrollView: NSScrollView!
    private var refreshIntervalTextField: NSTextField!
    private var showInactiveCheckbox: NSButton!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 460))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        let contentView = view
        
        // Title
        let titleLabel = NSTextField(labelWithString: "PortPeek Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Watched Ports Section
        let portsLabel = NSTextField(labelWithString: "Watched Ports:")
        portsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(portsLabel)
        
        let portsHelpLabel = NSTextField(labelWithString: "Enter one port per line or comma-separated (e.g., 3000, 8080, 5432)")
        portsHelpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        portsHelpLabel.textColor = .secondaryLabelColor
        portsHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(portsHelpLabel)
        
        portsTextView = NSTextView(frame: .zero)
        portsTextView.isRichText = false
        portsTextView.isAutomaticQuoteSubstitutionEnabled = false
        portsTextView.isAutomaticDashSubstitutionEnabled = false
        portsTextView.isAutomaticTextCompletionEnabled = false
        portsTextView.isContinuousSpellCheckingEnabled = false
        portsTextView.font = NSFont.systemFont(ofSize: 13)
        
        portsScrollView = NSScrollView(frame: .zero)
        portsScrollView.borderType = .bezelBorder
        portsScrollView.hasVerticalScroller = true
        portsScrollView.autohidesScrollers = true
        portsScrollView.documentView = portsTextView
        portsScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(portsScrollView)
        
        // Refresh Interval Section
        let refreshLabel = NSTextField(labelWithString: "Refresh Interval:")
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(refreshLabel)
        
        let refreshHelpLabel = NSTextField(labelWithString: "How often to scan for changes (in seconds)")
        refreshHelpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        refreshHelpLabel.textColor = .secondaryLabelColor
        refreshHelpLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(refreshHelpLabel)
        
        refreshIntervalTextField = NSTextField(frame: .zero)
        refreshIntervalTextField.placeholderString = "5"
        refreshIntervalTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(refreshIntervalTextField)
        
        let secondsLabel = NSTextField(labelWithString: "seconds")
        secondsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(secondsLabel)
        
        // Show Inactive Ports Checkbox
        showInactiveCheckbox = NSButton(checkboxWithTitle: "Show inactive ports in menu", target: nil, action: nil)
        showInactiveCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(showInactiveCheckbox)
        
        // Buttons
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Return key
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)
        
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resetButton)
        
        // Layout
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Watched Ports
            portsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            portsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            portsHelpLabel.topAnchor.constraint(equalTo: portsLabel.bottomAnchor, constant: 4),
            portsHelpLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            portsHelpLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            portsScrollView.topAnchor.constraint(equalTo: portsHelpLabel.bottomAnchor, constant: 8),
            portsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            portsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            portsScrollView.heightAnchor.constraint(equalToConstant: 120),
            
            // Refresh Interval
            refreshLabel.topAnchor.constraint(equalTo: portsScrollView.bottomAnchor, constant: 20),
            refreshLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            refreshHelpLabel.topAnchor.constraint(equalTo: refreshLabel.bottomAnchor, constant: 4),
            refreshHelpLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            refreshIntervalTextField.topAnchor.constraint(equalTo: refreshHelpLabel.bottomAnchor, constant: 8),
            refreshIntervalTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            refreshIntervalTextField.widthAnchor.constraint(equalToConstant: 80),
            
            secondsLabel.centerYAnchor.constraint(equalTo: refreshIntervalTextField.centerYAnchor),
            secondsLabel.leadingAnchor.constraint(equalTo: refreshIntervalTextField.trailingAnchor, constant: 8),
            
            // Show Inactive Checkbox
            showInactiveCheckbox.topAnchor.constraint(equalTo: refreshIntervalTextField.bottomAnchor, constant: 20),
            showInactiveCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Buttons
            resetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            resetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -12),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
        ])
    }
    
    private func loadSettings() {
        let prefs = Preferences.shared
        
        // Load watched ports
        let portsString = prefs.watchedPorts.map(String.init).joined(separator: "\n")
        portsTextView.string = portsString
        
        // Load refresh interval
        refreshIntervalTextField.stringValue = String(Int(prefs.refreshInterval))
        
        // Load show inactive
        showInactiveCheckbox.state = prefs.showInactivePorts ? .on : .off
    }
    
    @objc private func saveSettings() {
        guard validateAndSave() else { return }
        view.window?.close()
    }
    
    @objc private func cancel() {
        view.window?.close()
    }
    
    @objc private func resetToDefaults() {
        Preferences.shared.resetToDefaults()
        loadSettings()
    }
    
    private func validateAndSave() -> Bool {
        // Parse ports
        let portsString = portsTextView.string
        let separators = CharacterSet(charactersIn: ",\n\r\t ")
        let portStrings = portsString
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
        
        var ports: [Int] = []
        var seen = Set<Int>()
        for portString in portStrings {
            guard let port = Int(portString), port > 0, port <= 65535 else {
                showError(message: "Invalid port number: \(portString)\n\nPorts must be between 1 and 65535.")
                return false
            }
            if seen.insert(port).inserted {
                ports.append(port)
            }
        }
        
        if ports.isEmpty {
            showError(message: "Please enter at least one port to watch.")
            return false
        }
        
        // Parse refresh interval
        guard let interval = Double(refreshIntervalTextField.stringValue), interval > 0 else {
            showError(message: "Invalid refresh interval.\n\nPlease enter a positive number of seconds.")
            return false
        }
        
        // Save preferences
        let prefs = Preferences.shared
        prefs.watchedPorts = ports
        prefs.refreshInterval = interval
        prefs.showInactivePorts = showInactiveCheckbox.state == .on
        
        // Post notification so AppDelegate can restart timer if needed
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        
        return true
    }
    
    private func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Invalid Settings"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Notification

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
}
