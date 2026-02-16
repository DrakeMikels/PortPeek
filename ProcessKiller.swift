//
//  ProcessKiller.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Foundation

/// Handles terminating processes
class ProcessKiller {
    
    enum Signal {
        case term  // SIGTERM (15)
        case kill  // SIGKILL (9)
        
        var value: Int32 {
            switch self {
            case .term: return 15
            case .kill: return 9
            }
        }
        
        var displayName: String {
            switch self {
            case .term: return "SIGTERM"
            case .kill: return "SIGKILL"
            }
        }
    }
    
    /// Attempts to kill a process with the specified signal
    /// - Parameters:
    ///   - pid: Process ID to terminate
    ///   - signal: Signal to send (SIGTERM or SIGKILL)
    /// - Returns: Result indicating success or failure with error message
    func kill(pid: Int, signal: Signal) -> Result<Void, ProcessKillerError> {
        let result = Darwin.kill(pid_t(pid), signal.value)
        
        if result == 0 {
            return .success(())
        } else {
            let error = String(cString: strerror(errno))
            return .failure(.killFailed(pid: pid, signal: signal, reason: error))
        }
    }
}

// MARK: - Errors

enum ProcessKillerError: LocalizedError {
    case killFailed(pid: Int, signal: ProcessKiller.Signal, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .killFailed(let pid, let signal, let reason):
            return "Failed to send \(signal.displayName) to process \(pid): \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .killFailed(_, _, let reason):
            if reason.contains("Operation not permitted") {
                return "You may not have permission to terminate this process."
            } else if reason.contains("No such process") {
                return "The process may have already terminated."
            }
            return nil
        }
    }
}
