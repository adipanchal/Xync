//
//  ConnectionWizardView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct ConnectionWizardView: View {
    var onComplete: () -> Void
    
    @State private var step = 0
    @State private var log = ""
    @State private var ipAddress = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Connection Wizard")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Close")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
            if step == 0 {
                StepView(
                    number: 1,
                    title: "Connect via USB",
                    description: "Connect your device via USB cable first to setup TCP/IP mode.",
                    actionTitle: "Enable TCP/IP Mode",
                    isLoading: isLoading
                ) {
                    enableTcpIp()
                }
            } else if step == 1 {
                StepView(
                    number: 2,
                    title: "Connect Wirelessly",
                    description: "Keep USB plugged in. Enter the IP address and tap Connect. You can unplug USB after a successful connection.",
                    actionTitle: "",
                    isLoading: false,
                    action: {}
                )
                
                HStack {
                    TextField("Device IP Address", text: $ipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        connectToIp()
                    }) {
                        Text("Connect")
                             .fontWeight(.semibold)
                             .padding(.vertical, 6)
                             .padding(.horizontal, 12)
                             .background(
                                 RoundedRectangle(cornerRadius: 8)
                                     .fill(Material.ultraThin)
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 8)
                                             .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                     )
                             )
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .disabled(ipAddress.isEmpty || isLoading)
                }
                
                HStack {
                    Button(action: {
                        step = 0
                        log += "\n--- Back to Step 1 ---\n"
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.caption)
                            Text("Back to Step 1")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    
                    Spacer()
                    
                    Text("Tip: Assign a Static IP to avoid repeating this.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            
            ScrollView {
                Text(log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 120)
                }
                .padding(28)
            }
        }
        .onAppear {
            // Try to auto-detect IP immediately when wizard opens (assuming USB is connected)
            if let ip = ShellManager.shared.getDeviceIP() {
                ipAddress = ip
                log += "Detected IP: \(ip)\n"
            } else {
                log += "Could not detect IP automatically. Ensure USB uses data transfer.\n"
            }
        }
    }
    
    func enableTcpIp() {
        isLoading = true
        log += "Checking for USB devices...\n"
        
        // Refresh IP check before enabling TCP/IP
        if let ip = ShellManager.shared.getDeviceIP() {
            ipAddress = ip
        }
        
        DispatchQueue.global().async {
            // First, get raw adb output for diagnostics
            let rawOutput = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' devices -l")
            
            DispatchQueue.main.async {
                log += "> adb devices -l\n\(rawOutput)\n"
            }
            
            // Find a USB device to target
            let devices = ShellManager.shared.listDevices()
            
            DispatchQueue.main.async {
                log += "Found \(devices.count) device(s) total:\n"
                for d in devices {
                    log += "  • \(d.serial) [\(d.state)] \(d.isWireless ? "(wireless)" : "(USB)")\n"
                }
            }
            
            // Pick the first non-wireless, active device
            let usbDevice = devices.first { !$0.isWireless && $0.state == "device" }
            // Fallback: try any non-wireless device regardless of state
            let fallbackDevice = usbDevice ?? devices.first { !$0.isWireless }
            
            guard let targetSerial = fallbackDevice?.serial else {
                DispatchQueue.main.async {
                    log += "❌ Error: No USB device found.\n"
                    log += "\nTroubleshooting:\n"
                    log += "• Ensure USB cable supports data transfer (not charge-only)\n"
                    log += "• Enable USB Debugging in Developer Options on your phone\n"
                    log += "• Tap 'Allow USB Debugging' on the phone prompt\n"
                    log += "• Try a different USB port or cable\n"
                    isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                log += "Targeting USB device: \(targetSerial)\n"
            }
            
            let output = ShellManager.shared.adbTcpIp(serial: targetSerial)
            
            // Get IP from this specific device for the next step
            let specificIp = ShellManager.shared.getDeviceIP(serial: targetSerial)
            
            DispatchQueue.main.async {
                log += "> adb -s \(targetSerial) tcpip 5555\n\(output)\n"
                
                if let ip = specificIp {
                   self.ipAddress = ip
                   log += "Detected device IP: \(ip)\n"
                }

                isLoading = false
                if !output.lowercased().contains("error") && !output.lowercased().contains("no devices") {
                    step = 1
                } else {
                    log += "Failed to enable TCP/IP. Check USB connection.\n"
                }
            }
        }
    }
    
    func connectToIp() {
        isLoading = true
        let ip = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if ip.isEmpty {
            log += "Error: IP Address is empty.\n"
            isLoading = false
            return
        }
        
        DispatchQueue.global().async {
            let output = ShellManager.shared.adbConnect(ip: ip)
            DispatchQueue.main.async {
                log += "> adb connect \(ip):5555\n\(output)\n"
                isLoading = false
                
                if output.localizedCaseInsensitiveContains("connected") {
                     log += "SUCCESS! Device connected wirelessly.\nYou can close this wizard and find the device in the list.\n"
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                         onComplete()
                     }
                } else if output.localizedCaseInsensitiveContains("no route to host") || output.localizedCaseInsensitiveContains("failed to connect") {
                    log += "FAILED: \(output)\nAttempting to reset ADB server and retry...\n"
                    
                    // Auto-retry with reset
                    self.retryWithReset(ip: ip)
                    
                } else if output.localizedCaseInsensitiveContains("refused") {
                     log += "FAILED: Connection refused.\n• Ensure TCP Mode (Step 1) was successful.\n• Resetting ADB might help.\n"
                     self.retryWithReset(ip: ip)
                } else {
                    // Fallback for "already connected" if it didn't trigger 'connected' or ambiguous output
                     if output.localizedCaseInsensitiveContains("already connected") {
                         log += "SUCCESS! Device was already connected.\n"
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                             onComplete()
                         }
                     } else {
                        log += "FAILED: Unknown error.\n\(output)\n"
                     }
                }
            }
        }
    }
    
    func retryWithReset(ip: String) {
        DispatchQueue.global().async {
            // Try to re-enable TCP/IP if USB is still connected
            let devices = ShellManager.shared.listDevices()
            let usbDevice = devices.first { !$0.isWireless && $0.state == "device" }
            
            if let usb = usbDevice {
                DispatchQueue.main.async {
                    self.log += "USB device still connected. Re-enabling TCP/IP...\n"
                }
                let tcpResult = ShellManager.shared.adbTcpIp(serial: usb.serial)
                DispatchQueue.main.async {
                    self.log += "> adb -s \(usb.serial) tcpip 5555\n\(tcpResult)\n"
                }
                // Give the phone time to switch to TCP/IP mode
                Thread.sleep(forTimeInterval: 2.0)
            } else {
                // No USB device, just restart ADB server
                ShellManager.shared.restartAdbServer()
                Thread.sleep(forTimeInterval: 2.0)
                DispatchQueue.main.async {
                    self.log += "> ADB Restarted.\n"
                }
            }
            
            DispatchQueue.main.async {
                self.log += "Retrying connection...\n"
            }
            
            let output = ShellManager.shared.adbConnect(ip: ip)
            
            DispatchQueue.main.async {
                self.log += "> adb connect \(ip):5555\n\(output)\n"
                
                if output.localizedCaseInsensitiveContains("connected") {
                     self.log += "SUCCESS! Device connected wirelessly.\nYou can now unplug USB and close this wizard.\n"
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                         self.onComplete()
                     }
                } else {
                    self.log += "Still failing. Troubleshooting:\n"
                    self.log += "• Keep USB plugged in and go Back to Step 1\n"
                    self.log += "• Ensure phone and Mac are on the same WiFi\n"
                    self.log += "• Check if IP address is correct\n"
                }
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String
    let actionTitle: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "\(number).circle.fill")
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .foregroundColor(.secondary)
            
            if !actionTitle.isEmpty {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThin)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.top, 5)
                .disabled(isLoading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
