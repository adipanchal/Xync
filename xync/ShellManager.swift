//
//  ShellManager.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import Foundation
import Combine

class ShellManager: ObservableObject {
    static let shared = ShellManager()
    
    // Configurable paths
    var adbPath: String
    private var scrcpyPath: String
    
    init() {
        // Check bundled binaries first, then fall back to system PATH
        let bundledBinDir = DependencyManager.shared.binDir.path
        
        // Check for bundled adb
        let bundledAdb = "\(bundledBinDir)/adb"
        if FileManager.default.fileExists(atPath: bundledAdb) {
            self.adbPath = bundledAdb
        } else {
            self.adbPath = "/opt/homebrew/bin/adb"
        }
        
        // Check for bundled scrcpy
        let bundledScrcpy = "\(bundledBinDir)/scrcpy"
        if FileManager.default.fileExists(atPath: bundledScrcpy) {
            self.scrcpyPath = bundledScrcpy
        } else {
            self.scrcpyPath = "/opt/homebrew/bin/scrcpy"
        }
    }
    
    private let knownDevicesKey = "KnownWirelessDevices"
    
    // Save a successful wireless connection
    func saveKnownDevice(serial: String, model: String) {
        guard serial.contains(":") || serial.contains(".") else { return } // Only save wireless
        
        var known = getKnownDevicesDict()
        known[serial] = model
        UserDefaults.standard.set(known, forKey: knownDevicesKey)
    }
    
    func forgetDevice(serial: String) {
        // Disconnect the device via adb
        let _ = adbDisconnect(serial: serial)
        
        // Stop any active scrcpy session
        stopScrcpy(serial: serial)
        
        // Remove from known devices
        var known = getKnownDevicesDict()
        known.removeValue(forKey: serial)
        UserDefaults.standard.set(known, forKey: knownDevicesKey)
        
        print("🗑️ Forgot device: \(serial)")
    }
    
    private func getKnownDevicesDict() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: knownDevicesKey) as? [String: String] ?? [:]
    }

    func listDevices() -> [Device] {
        // Quote the path to handle spaces in "Application Support"
        let output = run("'\(adbPath)' devices -l")
        print("🔍 Raw adb output:")
        print(output)
        print("🔍 End of raw output")
        
        var currentDevices: [Device] = []
        var foundSerials: Set<String> = []
        
        // Output format usually:
        // List of devices attached
        // SERIAL       device product:X model:Y device:Z transport_id:N
        
        let lines = output.components(separatedBy: .newlines)
        print("🔍 Processing \(lines.count) lines")
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            print("🔍 Line: '\(line)' -> \(parts.count) parts")
            if parts.count >= 2 && parts[0] != "List" {
                let serial = parts[0]
                let state = parts[1]
                
                print("🔍 Checking serial: '\(serial)', state: '\(state)'")
                
                // Filter out invalid entries
                // Skip if serial contains shell-related text or invalid patterns
                // Also skip if serial has colon but is NOT an IP address (like zsh:1:)
                let isIPAddress = serial.contains(".") && serial.contains(":")
                let hasInvalidColon = serial.contains(":") && !isIPAddress
                
                guard !serial.contains("zsh"),
                      !serial.contains("bash"),
                      !serial.contains("attached"),
                      !hasInvalidColon,
                      serial.count > 2 else {
                    print("🔍 Skipping invalid serial: \(serial)")
                    continue
                }
                
                print("✅ Valid device found: \(serial) with state: \(state)")
                
                var model = "Unknown"
                if let modelPart = parts.first(where: { $0.starts(with: "model:") }) {
                    model = modelPart.replacingOccurrences(of: "model:", with: "")
                }
                
                let device = Device(id: serial, serial: serial, state: state, model: model)
                currentDevices.append(device)
                foundSerials.insert(serial)
                
                // Save if it's wireless and active
                if device.isWireless && state == "device" {
                    saveKnownDevice(serial: serial, model: model)
                }
            }
        }
        
        // Merge known devices that are missing (not currently connected)
        let known = getKnownDevicesDict()
        for (serial, model) in known {
            // Only add if NOT already in the current devices list
            if !foundSerials.contains(serial) {
                // Add as disconnected
                currentDevices.append(Device(id: serial, serial: serial, state: "disconnected", model: model))
            }
        }
        
        print("📱 listDevices: Found \(currentDevices.count) total devices")
        for dev in currentDevices {
            print("   - \(dev.serial): \(dev.state)")
        }
        
        return currentDevices.sorted { $0.isWireless && !$1.isWireless } // Keep wireless together or any sort logic
    }
    
    private func findExecutable(named name: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "which \(name)"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return path
            }
        } catch {
            print("Error finding \(name): \(error)")
        }
        return nil
    }

    func run(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"
        // Use clean environment without sourcing zshrc to avoid errors and latency
        // We rely on absolute paths or PATH being decent enough for system tools
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe // Capture error too
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func runAsync(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
            // We don't wait for exit for async UI apps like scrcpy
        } catch {
            print("Failed to launch async command: \(error)")
        }
    }

    func getDeviceIP(serial: String? = nil) -> String? {
        // Construct the base command with optional serial
        let adbCmd = (serial != nil && !serial!.isEmpty) ? "'\(adbPath)' -s \(serial!)" : "'\(adbPath)'"
        
        // Method 1: ip route (preferred)
        let output1 = run("\(adbCmd) shell ip route")
        let lines1 = output1.components(separatedBy: .newlines)
        for line in lines1 {
            if line.contains("wlan0") && line.contains("src") {
                let parts = line.components(separatedBy: .whitespaces)
                if let srcIndex = parts.firstIndex(of: "src"), srcIndex + 1 < parts.count {
                    return parts[srcIndex + 1]
                }
            }
        }
        
        // Method 2: ip addr show wlan0 (fallback)
        let output2 = run("\(adbCmd) shell ip addr show wlan0")
        let lines2 = output2.components(separatedBy: .newlines)
        for line in lines2 {
            // Look for "inet 192.168.x.x"
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("inet ") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                if parts.count > 1 {
                    // parts[1] is usually the IP info, sometimes with /24
                    let ipCidr = parts[1]
                    let ip = ipCidr.components(separatedBy: "/").first
                    return ip
                }
            }
        }
        
        return nil
    }
    
    func restartAdbServer() {
        _ = run("'\(adbPath)' kill-server")
        _ = run("'\(adbPath)' start-server")
    }
    
    func adbConnect(ip: String, port: String = "5555") -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: adbPath)
        
        // If IP already has a port, use it as-is
        if ip.contains(":") {
            task.arguments = ["connect", ip]
        } else {
            task.arguments = ["connect", "\(ip):\(port)"]
        }
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func adbDisconnect(serial: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: adbPath)
        task.arguments = ["disconnect", serial]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func adbTcpIp(port: String = "5555", serial: String? = nil) -> String {
        if let s = serial, !s.isEmpty {
            return run("'\(adbPath)' -s \(s) tcpip \(port)")
        }
        return run("'\(adbPath)' tcpip \(port)")
    }
    
    // Track active scrcpy processes: Serial -> Process
    @Published var activeScrcpySessions: [String: Bool] = [:]
    private var runningProcesses: [String: Process] = [:]
    
    func stopScrcpy(serial: String) {
        if let process = runningProcesses[serial] {
            process.terminate()
            runningProcesses.removeValue(forKey: serial)
            DispatchQueue.main.async {
                self.activeScrcpySessions[serial] = false
            }
        }
    }
    
    func startScrcpy(serial: String? = nil, stayAwake: Bool, turnScreenOff: Bool, alwaysOnTop: Bool, rotation: Int, isCamera: Bool = false, cameraSource: String = "back", dexResolution: String? = nil) {
        var args = ["'\(scrcpyPath)'"] // Quote the path in case it contains spaces
        
        // Ensure we always have a serial to track the process safely
        let deviceSerial = serial ?? "default"
        
        if let s = serial, !s.isEmpty {
            args.append("-s")
            args.append(s)
        }
        
        // Camera mode disables control, so we cannot use stay-awake or turn-screen-off
        if !isCamera {
            if stayAwake { args.append("--stay-awake") }
            if turnScreenOff { args.append("--turn-screen-off") }
        }
        
        if alwaysOnTop { args.append("--always-on-top") }
        
        if rotation != 0 {
            let angle = rotation * 90
            args.append("--orientation=\(angle)")
        }
        
        if isCamera {
            args.append("--video-source=camera")
            args.append("--camera-facing=\(cameraSource)")
            args.append("--camera-size=1280x720")
            args.append("--no-audio")
        }

        if let res = dexResolution, !res.isEmpty {
            args.append("--new-display=\(res)")
        }
        
        // Prepend ADB environment variable so scrcpy knows exactly which adb to use, and include homebrew paths
        let command = "export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; export ADB='\(adbPath)'; " + args.joined(separator: " ")
        print("Launching: \(command)")
        
        // Stop existing if any
        stopScrcpy(serial: deviceSerial)
        
        launchAsyncTracked(command: command, serial: deviceSerial)
    }
    
    private func launchAsyncTracked(command: String, serial: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        task.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.activeScrcpySessions[serial] = false
                self?.runningProcesses.removeValue(forKey: serial)
            }
        }
        
        do {
            try task.run()
            runningProcesses[serial] = task
            DispatchQueue.main.async {
                self.activeScrcpySessions[serial] = true
            }
        } catch {
            print("Failed to launch tracked command: \(error)")
        }
    }
}
