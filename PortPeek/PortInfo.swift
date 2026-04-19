//
//  PortInfo.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Foundation

/// Represents information about a listening process on a specific port
struct PortInfo: Equatable, Identifiable {
    let id = UUID()
    let port: Int
    let processName: String
    let pid: Int
    let user: String
    let protocolType: String
    
    init(port: Int, processName: String, pid: Int, user: String, protocolType: String = "TCP") {
        self.port = port
        self.processName = processName
        self.pid = pid
        self.user = user
        self.protocolType = protocolType
    }
    
    /// Returns the localhost URL for this port
    var url: String {
        "http://localhost:\(port)"
    }
    
    /// Returns the host:port string
    var hostPort: String {
        "localhost:\(port)"
    }
    
    static func == (lhs: PortInfo, rhs: PortInfo) -> Bool {
        lhs.port == rhs.port && lhs.pid == rhs.pid
    }
}

/// Result of a port scanning operation
struct ScanResult {
    let activePorts: [PortInfo]
    let scanDate: Date
    let error: String?
    
    var isSuccess: Bool {
        error == nil
    }
    
    /// Returns a relative time string for display (e.g., "just now", "5s ago")
    var relativeTimeString: String {
        let now = Date()
        let interval = now.timeIntervalSince(scanDate)
        
        if interval < 2 {
            return "just now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
}
