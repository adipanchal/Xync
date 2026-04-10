//
//  DeviceRow.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct DeviceRow: View {
    let device: Device
    let onMirror: (Bool, String) -> Void
    let onDex: () -> Void
    let onFiles: () -> Void
    let onStop: () -> Void
    let onReconnect: (@escaping (Bool) -> Void) -> Void
    let onDisconnect: () -> Void
    let onForget: () -> Void
    let isMirroring: Bool
    
    @State private var showSettings = false
    @State private var batteryLevel: Int? = nil
    @State private var isConnecting = false
    @State private var isMirrorLoading = false
    @State private var isDexLoading = false
    @State private var isDisconnecting = false
    @State private var isFrontCamLoading = false
    @State private var isBackCamLoading = false
    @State private var connectionError: String? = nil
    
    // Card background color #222222
    private let cardBg = Color(nsColor: .controlBackgroundColor)
    private let buttonBg = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    
    var body: some View {
        if device.state == "device" {
            connectedCard
                .onAppear {
                    fetchBattery()
                }
        } else {
            disconnectedCard
        }
    }
    
    // MARK: - Connected Device Card
    
    private var connectedCard: some View {
        HStack(alignment: .top, spacing: 20) {
            // Phone icon
            phoneIcon(width: 90, height: 150, cornerRadius: 16, innerCornerRadius: 12, innerPadding: 8)
            
            // Center: Device Info + Action Buttons
            VStack(alignment: .leading, spacing: 6) {
                // Device name — bold, large
                Text(device.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                // Serial + connection type
                Text("\(device.serial) · \(device.isWireless ? "Wireless" : "Wired")")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                
                // Status row: Connected + Battery
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    if let level = batteryLevel {
                        Image(systemName: batteryIconName(level))
                            .font(.system(size: 13))
                            .foregroundColor(batteryColor(level))
                            .padding(.leading, 4)
                        Text("\(level)%")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .padding(.top, 2)
                
                Spacer().frame(height: 10)
                
                // Action buttons row 1: Mirror, Files, Dex
                HStack(spacing: 10) {
                    loadingActionButton("Mirror", isLoading: $isMirrorLoading) {
                        isMirrorLoading = true
                        onMirror(false, "back")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isMirrorLoading = false }
                    }
                    actionButton("Files") { onFiles() }
                    loadingActionButton("Dex", isLoading: $isDexLoading) {
                        isDexLoading = true
                        onDex()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isDexLoading = false }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                // Action buttons row 2: Front Camera, Back Camera
                HStack(spacing: 10) {
                    loadingActionButton("Front Camera", isLoading: $isFrontCamLoading) {
                        isFrontCamLoading = true
                        onMirror(true, "front")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isFrontCamLoading = false }
                    }
                    loadingActionButton("Back Camera", isLoading: $isBackCamLoading) {
                        isBackCamLoading = true
                        onMirror(true, "back")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isBackCamLoading = false }
                    }
                }
            }
            
            Spacer()
            
            // Right side buttons
            VStack(spacing: 8) {
                sideButton("Settings") { showSettings.toggle() }
                    .popover(isPresented: $showSettings) {
                        GeneralSettingsView()
                            .frame(width: 350, height: 280)
                    }
                sideButton("Send Clipboard") { sendClipboardText() }
                sideButton("Upload to phone") { quickPushFile() }
                
                // Disconnect with loading
                Button(action: {
                    isDisconnecting = true
                    onDisconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isDisconnecting = false }
                }) {
                    if isDisconnecting {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 16, height: 16)
                    } else {
                        Text("Disconnect")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .frame(width: 140)
                .disabled(isDisconnecting)
                
                // Remove Device — red variant
                Button(action: { onForget() }) {
                    Text("Remove Device")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .frame(width: 140)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
        )
    }
    
    // MARK: - Disconnected Device Card
    
    private var disconnectedCard: some View {
        HStack(spacing: 16) {
            // Small phone icon
            phoneIcon(width: 44, height: 68, cornerRadius: 10, innerCornerRadius: 7, innerPadding: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(device.serial)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                
                if let error = connectionError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                } else {
                    Text("Not connected")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }
            
            Spacer()
            
            Button(action: {
                isConnecting = true
                connectionError = nil
                onReconnect { success in
                    isConnecting = false
                    if !success {
                        connectionError = "Device is offline. Make sure it's on the same network."
                    }
                }
            }) {
                if isConnecting {
                    ProgressView()
                        .scaleEffect(0.55)
                        .frame(width: 16, height: 16)
                } else {
                    Text("Connect")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isConnecting)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
        )
    }
    
    // MARK: - Phone Icon
    
    private func phoneIcon(width: CGFloat, height: CGFloat, cornerRadius: CGFloat, innerCornerRadius: CGFloat, innerPadding: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(nsColor: .windowBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.12), location: 0.3),
                                .init(color: Color.white.opacity(0.03), location: 0.6),
                                .init(color: Color.white.opacity(0.08), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .frame(width: width, height: height)
    }
    
    // MARK: - Button Components
    
    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.regular)
    }
    
    private func loadingActionButton(_ title: String, isLoading: Binding<Bool>, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isLoading.wrappedValue {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 16, height: 16)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .disabled(isLoading.wrappedValue)
    }
    
    private func sideButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(width: 140)
    }
    
    // MARK: - Battery Helpers
    
    private func fetchBattery() {
        DispatchQueue.global(qos: .userInitiated).async {
            let level = ShellManager.shared.getBatteryLevel(serial: device.serial)
            DispatchQueue.main.async {
                self.batteryLevel = level
            }
        }
    }
    
    private func batteryIconName(_ level: Int) -> String {
        switch level {
        case 0...12: return "battery.0"
        case 13...37: return "battery.25"
        case 38...62: return "battery.50"
        case 63...87: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private func batteryColor(_ level: Int) -> Color {
        if level <= 20 { return .red }
        if level <= 40 { return .orange }
        return Color.white.opacity(0.5)
    }
    
    // MARK: - Quick Share Actions
    
    private func sendClipboardText() {
        if let string = NSPasteboard.general.string(forType: .string) {
            ShellManager.shared.sendText(serial: device.serial, text: string)
        }
    }
    
    private func quickPushFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Send to Phone"
        
        if panel.runModal() == .OK, let url = panel.url {
            let fileName = url.lastPathComponent
            DispatchQueue.global().async {
                _ = ShellManager.shared.pushFile(serial: device.serial, localPath: url.path, remotePath: "/sdcard/Download/\(fileName)")
            }
        }
    }
}
