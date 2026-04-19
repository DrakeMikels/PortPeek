//
//  Preferences.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Foundation

/// Manages app preferences using UserDefaults
class Preferences {
    static let shared = Preferences()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let watchedPorts = "watchedPorts"
        static let refreshInterval = "refreshInterval"
        static let showInactivePorts = "showInactivePorts"
    }
    
    // Default values
    private let defaultWatchedPorts = [3000, 3001, 5173, 8080, 8000, 5000, 4000, 5432, 6379, 27017, 9200, 15672]
    private let defaultRefreshInterval: TimeInterval = 5.0
    private let defaultShowInactivePorts = false
    
    private init() {
        // Register defaults on first launch
        registerDefaults()
    }
    
    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.watchedPorts: defaultWatchedPorts,
            Keys.refreshInterval: defaultRefreshInterval,
            Keys.showInactivePorts: defaultShowInactivePorts
        ])
    }
    
    /// List of ports to monitor
    var watchedPorts: [Int] {
        get {
            defaults.array(forKey: Keys.watchedPorts) as? [Int] ?? defaultWatchedPorts
        }
        set {
            defaults.set(newValue, forKey: Keys.watchedPorts)
        }
    }
    
    /// Refresh interval in seconds
    var refreshInterval: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.refreshInterval)
            return value > 0 ? value : defaultRefreshInterval
        }
        set {
            defaults.set(newValue, forKey: Keys.refreshInterval)
        }
    }
    
    /// Whether to show inactive ports in the menu
    var showInactivePorts: Bool {
        get {
            defaults.bool(forKey: Keys.showInactivePorts)
        }
        set {
            defaults.set(newValue, forKey: Keys.showInactivePorts)
        }
    }
    
    /// Reset all preferences to defaults
    func resetToDefaults() {
        watchedPorts = defaultWatchedPorts
        refreshInterval = defaultRefreshInterval
        showInactivePorts = defaultShowInactivePorts
    }
}
