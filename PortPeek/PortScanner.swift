//
//  PortScanner.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import Foundation
import Darwin

/// Scans for listening processes on specified ports using lsof
class PortScanner {
    
    private func resolveLsofURL() -> URL? {
        let candidates = ["/usr/sbin/lsof", "/usr/bin/lsof"]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    /// Scans the specified ports for listening processes
    /// - Parameter ports: Array of port numbers to check
    /// - Returns: ScanResult containing active ports or error information
    func scan(ports: [Int]) async -> ScanResult {
        let scanDate = Date()
        
        do {
            let allListeners = try await runLsof(watchedPorts: ports)
            let watchedPorts = Set(ports)
            
            // Filter to only watched ports
            let activePortInfos = allListeners.filter { watchedPorts.contains($0.port) }
            
            return ScanResult(activePorts: activePortInfos, scanDate: scanDate, error: nil)
        } catch {
            print("PortPeek scan error: \(error.localizedDescription)")
            return ScanResult(activePorts: [], scanDate: scanDate, error: error.localizedDescription)
        }
    }
    
    private func shouldTreatAsPartialResult(exitCode: Int32, stderr: String) -> Bool {
        guard exitCode != 0 else { return false }
        let lowered = stderr.lowercased()
        return lowered.contains("operation not permitted") || lowered.contains("permission denied")
    }
    
    private func lsofUserFilterArguments() -> [String] {
        let username = NSUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return [] }
        return ["-a", "-u", username]
    }
    
    private func debugLog(_ message: String) {
        _ = message
    }
    
    private func isNoMatchResult(exitCode: Int32, stdout: String, stderr: String) -> Bool {
        guard exitCode == 1 else { return false }
        return stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func runCommand(executable: URL, arguments: [String], environment: [String: String]? = nil) throws -> (stdout: String, stderr: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        if let environment = environment {
            process.environment = environment
        }
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        try process.run()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        return (stdout, stderr, process.terminationStatus)
    }
    
    private func runLsofCommand(arguments: [String]) throws -> (stdout: String, stderr: String, exitCode: Int32) {
        var firstError: Error?
        
        // 1) Try direct path resolution
        if let lsofURL = resolveLsofURL() {
            do {
                return try runCommand(executable: lsofURL, arguments: arguments)
            } catch {
                firstError = error
            }
        } else {
            firstError = PortScannerError.lsofNotFound
        }
        
        // 2) Fallback: use /usr/bin/env to locate lsof via PATH
        let envURL = URL(fileURLWithPath: "/usr/bin/env")
        if FileManager.default.fileExists(atPath: envURL.path) {
            do {
                let env = ["PATH": "/usr/sbin:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"]
                return try runCommand(executable: envURL, arguments: ["lsof"] + arguments, environment: env)
            } catch {
                // If fallback also fails, throw the first meaningful error if present
                if let firstError = firstError {
                    throw firstError
                }
                throw error
            }
        }
        
        // If we get here, neither method worked
        throw firstError ?? PortScannerError.lsofNotFound
    }
    
    private func runLsofPerWatchedPort(_ watchedPorts: [Int]) throws -> [PortInfo] {
        var portInfos: [PortInfo] = []
        
        for port in Set(watchedPorts).sorted() {
            var args = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-w"]
            args.append(contentsOf: lsofUserFilterArguments())
            args.append("-FpcLuPn")
            let (stdout, stderr, code) = try runLsofCommand(arguments: args)
            let parsed = parseLsofOutput(stdout)
            let trimmedStderr = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == 0 || shouldTreatAsPartialResult(exitCode: code, stderr: stderr) {
                debugLog("per-port \(port) code=\(code) parsed=\(parsed.count) stderr='\(trimmedStderr)'")
                portInfos.append(contentsOf: parsed)
                continue
            }
            
            if isNoMatchResult(exitCode: code, stdout: stdout, stderr: stderr) {
                debugLog("per-port \(port) no-match")
                continue
            }
            
            throw PortScannerError.lsofFailed(exitCode: code, stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        var seen = Set<String>()
        var deduped: [PortInfo] = []
        for info in portInfos {
            let key = "\(info.port)-\(info.pid)"
            if seen.insert(key).inserted {
                deduped.append(info)
            }
        }
        return deduped
    }
    
    private func parseLsofNameOnlyOutput(_ output: String) -> [Int] {
        let lines = output.components(separatedBy: .newlines)
        return lines.compactMap { line in
            guard line.hasPrefix("n") else { return nil }
            return extractPort(from: String(line.dropFirst()))
        }
    }
    
    private func runLsofNameOnlyPerWatchedPort(_ watchedPorts: [Int]) throws -> [PortInfo] {
        var detectedPorts = Set<Int>()
        
        for port in Set(watchedPorts).sorted() {
            var args = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-w"]
            args.append(contentsOf: lsofUserFilterArguments())
            args.append("-Fn")
            let (stdout, stderr, code) = try runLsofCommand(arguments: args)
            let names = parseLsofNameOnlyOutput(stdout)
            let trimmedStderr = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == 0 || shouldTreatAsPartialResult(exitCode: code, stderr: stderr) || isNoMatchResult(exitCode: code, stdout: stdout, stderr: stderr) {
                if !names.isEmpty {
                    debugLog("name-only \(port) code=\(code) parsed=\(names.count) stderr='\(trimmedStderr)'")
                }
                for detected in names {
                    detectedPorts.insert(detected)
                }
                continue
            }
            
            throw PortScannerError.lsofFailed(exitCode: code, stderr: trimmedStderr)
        }
        
        return detectedPorts.sorted().map {
            PortInfo(port: $0, processName: "unknown", pid: -1, user: "unknown", protocolType: "TCP")
        }
    }
    
    private func canConnectIPv4(port: Int) -> Bool {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        
        let conversion = "127.0.0.1".withCString { cString in
            inet_pton(AF_INET, cString, &address.sin_addr)
        }
        guard conversion == 1 else { return false }
        
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if result != 0 {
            let err = errno
            debugLog("socket-ipv4 \(port) errno=\(err) \(String(cString: strerror(err)))")
        }
        
        return result == 0
    }
    
    private func canConnectIPv6(port: Int) -> Bool {
        let fd = socket(AF_INET6, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        
        var address = sockaddr_in6()
        address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        address.sin6_family = sa_family_t(AF_INET6)
        address.sin6_port = in_port_t(port).bigEndian
        
        let conversion = "::1".withCString { cString in
            inet_pton(AF_INET6, cString, &address.sin6_addr)
        }
        guard conversion == 1 else { return false }
        
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }
        if result != 0 {
            let err = errno
            debugLog("socket-ipv6 \(port) errno=\(err) \(String(cString: strerror(err)))")
        }
        
        return result == 0
    }
    
    private func isLocalPortOpen(_ port: Int) -> Bool {
        guard port > 0 && port <= 65535 else { return false }
        return canConnectIPv4(port: port) || canConnectIPv6(port: port)
    }
    
    private func detectActivePortsViaLocalConnect(_ watchedPorts: [Int]) -> [PortInfo] {
        var active: [PortInfo] = []
        
        for port in Set(watchedPorts).sorted() {
            let isOpen = isLocalPortOpen(port)
            debugLog("socket-probe \(port)=\(isOpen)")
            guard isOpen else { continue }
            
            active.append(
                PortInfo(
                    port: port,
                    processName: "localhost",
                    pid: -1,
                    user: "unknown",
                    protocolType: "TCP"
                )
            )
        }
        
        return active
    }
    
    /// Runs lsof command and parses output
    private func runLsof(watchedPorts: [Int]) async throws -> [PortInfo] {
        var args = ["-nP", "-iTCP", "-sTCP:LISTEN", "-w"]
        args.append(contentsOf: lsofUserFilterArguments())
        args.append("-FpcLuPn")
        let (stdout, stderr, code) = try runLsofCommand(arguments: args)
        let parsed = parseLsofOutput(stdout)
        let trimmedStderr = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        debugLog("global code=\(code) parsed=\(parsed.count) stderr='\(trimmedStderr)'")
        
        if !parsed.isEmpty {
            return parsed
        }
        
        if isNoMatchResult(exitCode: code, stdout: stdout, stderr: stderr) {
            return []
        }
        
        // If broad scan returns no rows, try targeted per-port queries.
        // This avoids false negatives when broad scans are constrained.
        if !watchedPorts.isEmpty {
            let perPort = try runLsofPerWatchedPort(watchedPorts)
            if !perPort.isEmpty {
                return perPort
            }
            
            // If metadata fields are blocked, try a name-only lsof query.
            let nameOnly = try runLsofNameOnlyPerWatchedPort(watchedPorts)
            if !nameOnly.isEmpty {
                return nameOnly
            }
            
            // Last-resort fallback: detect local listeners by direct TCP connect.
            // Process metadata may be unavailable, but active localhost ports still show.
            let connectDetected = detectActivePortsViaLocalConnect(watchedPorts)
            if !connectDetected.isEmpty {
                let ports = connectDetected.map { String($0.port) }.joined(separator: ",")
                debugLog("socket-fallback active ports=\(ports)")
            }
            return connectDetected
        }
        
        // On macOS, broad lsof scans can be blocked by protected processes.
        // Fall back to per-port queries so watched ports (like 3000) still resolve.
        if shouldTreatAsPartialResult(exitCode: code, stderr: stderr) {
            return []
        }
        
        throw PortScannerError.lsofFailed(exitCode: code, stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Parses lsof output into PortInfo structures
    private func parseLsofOutput(_ output: String) -> [PortInfo] {
        let fieldParsed = parseLsofFieldOutput(output)
        if !fieldParsed.isEmpty {
            return fieldParsed
        }
        return parseLsofColumnOutput(output)
    }
    
    /// Parses lsof field output generated by -FpcLuPn
    private func parseLsofFieldOutput(_ output: String) -> [PortInfo] {
        let lines = output.components(separatedBy: .newlines)
        var portInfos: [PortInfo] = []
        
        var currentPID: Int?
        var currentCommand: String?
        var currentUser: String?
        
        for line in lines {
            guard !line.isEmpty, let key = line.first else { continue }
            let value = String(line.dropFirst())
            
            switch key {
            case "p":
                currentPID = Int(value)
                currentCommand = nil
                currentUser = nil
            case "c":
                currentCommand = value
            case "L":
                currentUser = value
            case "u":
                if currentUser == nil {
                    currentUser = value
                }
            case "n":
                guard
                    let port = extractPort(from: value)
                else { continue }
                
                // Under macOS privacy constraints, lsof may omit some metadata fields.
                // Keep the row so port activity is still visible.
                let pid = currentPID ?? -1
                let command = (currentCommand?.isEmpty == false) ? currentCommand! : "unknown"
                let user = (currentUser?.isEmpty == false) ? currentUser! : "unknown"
                
                let portInfo = PortInfo(
                    port: port,
                    processName: command,
                    pid: pid,
                    user: user,
                    protocolType: "TCP"
                )
                portInfos.append(portInfo)
            default:
                continue
            }
        }
        
        return portInfos
    }
    
    /// Parses legacy column-based lsof output into PortInfo structures
    private func parseLsofColumnOutput(_ output: String) -> [PortInfo] {
        let lines = output.components(separatedBy: .newlines)
        var portInfos: [PortInfo] = []
        
        for line in lines {
            // Skip header and empty lines
            guard !line.isEmpty, !line.hasPrefix("COMMAND") else { continue }
            
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            
            // Expected format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            // We need: COMMAND (0), PID (1), USER (2), NAME (8)
            guard components.count >= 9 else { continue }
            
            let command = String(components[0])
            guard let pid = Int(components[1]) else { continue }
            let user = String(components[2])
            let nameComponents = components.dropFirst(8)
            let name = nameComponents.map(String.init).joined(separator: " ")
            
            // Extract port from NAME column
            if let port = extractPort(from: name) {
                let portInfo = PortInfo(
                    port: port,
                    processName: command,
                    pid: pid,
                    user: user,
                    protocolType: "TCP"
                )
                portInfos.append(portInfo)
            }
        }
        
        return portInfos
    }
    
    /// Extracts port number from lsof NAME column
    /// Handles formats like "*:8080", "127.0.0.1:3000", "[::1]:5432"
    private func extractPort(from name: String) -> Int? {
        guard let colonRange = name.range(of: ":", options: .backwards) else {
            return nil
        }
        let afterColon = name[colonRange.upperBound...]
        let digits = afterColon.prefix { $0.isNumber }
        return Int(digits)
    }
}

// MARK: - Errors

enum PortScannerError: LocalizedError {
    case lsofFailed(exitCode: Int32, stderr: String)
    case invalidOutput
    case lsofNotFound
    
    var errorDescription: String? {
        switch self {
        case .lsofFailed(let exitCode, let stderr):
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return "lsof command failed with exit code \(exitCode)"
            } else {
                return "lsof failed (exit \(exitCode)): \(trimmed)"
            }
        case .invalidOutput:
            return "Could not parse lsof output"
        case .lsofNotFound:
            return "lsof command not found"
        }
    }
}
