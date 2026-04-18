//
//  xyncApp.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

@main
struct xyncApp: App {
    @AppStorage("setupComplete") private var setupComplete = false
    @State private var dependenciesInstalled = DependencyManager.shared.areDependenciesInstalled()
    @Environment(\.openWindow) private var openWindow
    
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("hideFromDock") private var hideFromDock = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if setupComplete || dependenciesInstalled {
                    ContentView()
                        .frame(minWidth: 800, minHeight: 600)
                        .background(WindowAccessor())
                } else {
                    SetupWizardView(setupComplete: $setupComplete)
                        .frame(width: 600, height: 500)
                        .onAppear {
                            // Recheck dependencies when wizard appears
                            dependenciesInstalled = DependencyManager.shared.areDependenciesInstalled()
                            if dependenciesInstalled {
                                setupComplete = true
                            }
                        }
                }
            }
            .onAppear(perform: updateActivationPolicy)
            .onChange(of: showInMenuBar) { updateActivationPolicy() }
            .onChange(of: hideFromDock) { updateActivationPolicy() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Xync") {
                    openWindow(id: "about")
                }
            }
        }
        
        Settings {
            SettingsView()
        }
        
        MenuBarExtra("Xync", image: "MenuBarIcon", isInserted: $showInMenuBar) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
        
        Window("About Xync", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    private func updateActivationPolicy() {
        if showInMenuBar && hideFromDock {
            NSApp.setActivationPolicy(.accessory)
            // If the main window is closed, it acts purely as a menu bar app.
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }
}

struct MenuBarView: View {
    @StateObject private var shell = ShellManager.shared
    @State private var devices: [Device] = []
    @State private var isOtherDevicesExpanded = false
    @State private var isOtherDevicesHovering = false
    @AppStorage("xyncEnabled") private var xyncEnabled = true
    
    // Only the FIRST connected device is "active" — others are treated as "other"
    var activeDevice: Device? { devices.first(where: { $0.state == "device" }) }
    var otherDevices: [Device] {
        let inactiveConnected = devices.filter { $0.state == "device" }.dropFirst()
        let disconnected = devices.filter { $0.state != "device" }
        return Array(inactiveConnected) + disconnected
    }
    var hasConnected: Bool { activeDevice != nil }
    
    var body: some View {
        VStack(spacing: 0) {

            // ── Master Toggle Header ──────────────────────────
            HStack {
                Text("Xync")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle("", isOn: $xyncEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .onChange(of: xyncEnabled) { _, newValue in
                        if newValue { refresh() } else { devices = [] }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.horizontal, 16)

            if xyncEnabled {
                // Top section: active device or first known device
                VStack(spacing: 0) {
                    if let active = activeDevice {
                        // Active connected device
                        ConnectedDeviceSection(device: active, shell: shell, onRefresh: refresh)
                    } else if let firstOther = otherDevices.first {
                        // No active device — show first known device for quick connect
                        HStack {
                            Text("Known Device")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)

                        OtherDeviceRow(device: firstOther, shell: shell, onRefresh: refresh)
                    } else {
                        Text("No connected devices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 6)
                .padding(.bottom, !hasConnected && !otherDevices.isEmpty ? 4 : 12)

                Divider()
                    .padding(.horizontal, 16)

                // Other Devices section: inactive connected + all disconnected
                let remainingOther = !hasConnected ? Array(otherDevices.dropFirst()) : otherDevices
                if !remainingOther.isEmpty {
                    VStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isOtherDevicesExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Other Devices")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: isOtherDevicesExpanded ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.primary.opacity(0.4))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(isOtherDevicesHovering ? Color.primary.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isOtherDevicesHovering = hovering
                        }

                        if isOtherDevicesExpanded {
                            VStack(spacing: 2) {
                                ForEach(remainingOther, id: \.id) { device in
                                    OtherDeviceRow(device: device, shell: shell, onRefresh: refresh)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.horizontal, 16)
                }
            } else {
                Divider()
                    .padding(.horizontal, 16)
            }

            // Footer
            HStack(spacing: 0) {
                Button("Open Xync") {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        if window.title != "About Xync" {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .font(.system(size: 12, weight: .medium))

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 270)
        .onAppear {
            if xyncEnabled { refresh() }
        }
    }

    private func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let devs = shell.listDevices()
            DispatchQueue.main.async {
                self.devices = devs
            }
        }
    }
}

// Connected device section: same look as Known Device row + action tiles below
struct ConnectedDeviceSection: View {
    let device: Device
    @ObservedObject var shell: ShellManager
    let onRefresh: () -> Void
    @State private var hover = false

    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0

    var body: some View {
        let name = device.marketName.isEmpty ? (device.model == "Unknown" ? device.serial : device.model) : device.marketName
        let isMirroring = shell.activeScrcpySessions[device.serial] == true

        VStack(spacing: 0) {
            // ── Heading (same as Known Device) ─────────────────
            HStack {
                Text("Known Device")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)

            // ── Device row (blue icon = connected, tap to disconnect) ──
            Button(action: {
                _ = shell.adbDisconnect(serial: device.serial)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { onRefresh() }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 26, height: 26)
                        Image(systemName: "smartphone")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { onRefresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(hover ? Color.primary.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { h in hover = h }

            // ── Divider + Action tiles ──────────────────────────
            Divider()
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 10)

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ActionButton(icon: "play.display", title: "Mirror", isActive: isMirroring) {
                    if isMirroring {
                        shell.stopScrcpy(serial: device.serial)
                    } else {
                        shell.startScrcpy(serial: device.serial, stayAwake: stayAwake, turnScreenOff: turnScreenOff, alwaysOnTop: alwaysOnTop, rotation: rotation)
                    }
                }
                ActionButton(icon: "folder", title: "Files") {
                    openAppAndBringToFront()
                    NotificationCenter.default.post(name: NSNotification.Name("navigateToFiles"), object: device)
                }
                ActionButton(icon: "doc.on.clipboard", title: "Send Clip") {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        shell.sendText(serial: device.serial, text: string)
                    }
                }
                ActionButton(icon: "arrow.up.doc", title: "Upload") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.prompt = "Send to Phone"
                    if panel.runModal() == .OK, let url = panel.url {
                        let fileName = url.lastPathComponent
                        DispatchQueue.global().async {
                            _ = shell.pushFile(serial: device.serial, localPath: url.path, remotePath: "/sdcard/Download/\(fileName)")
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }
    }

    private func openAppAndBringToFront() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.title != "About Xync" {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Control Center Circular Platter
                    Circle()
                        .fill(isActive ? Color.white : (isHovering ? Color.primary.opacity(0.18) : Color.primary.opacity(0.12)))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isActive ? Color.black : Color(red: 169/255, green: 169/255, blue: 169/255))
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDetectingButtonStyle(isPressed: $isPressed))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// Helper to reliably trigger squish scale animations on buttons
struct PressDetectingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        DispatchQueue.main.async {
            self.isPressed = configuration.isPressed
        }
        return configuration.label
    }
}

struct OtherDeviceRow: View {
    let device: Device
    let shell: ShellManager
    let onRefresh: () -> Void
    @State private var hover = false
    @State private var isConnecting = false
    @State private var showOffline = false

    var body: some View {
        let name = device.marketName.isEmpty ? (device.model == "Unknown" ? device.serial : device.model) : device.marketName
        Button(action: {
            guard !isConnecting else { return }
            isConnecting = true
            showOffline = false
            DispatchQueue.global(qos: .userInitiated).async {
                // Disconnect any currently active device first (exclusive mode)
                shell.disconnectAllConnected()
                // Now connect to the new device
                let result = shell.adbConnect(ip: device.serial)
                let connected = result.contains("connected") && !result.contains("failed") && !result.contains("cannot")
                DispatchQueue.main.async {
                    isConnecting = false
                    if connected {
                        onRefresh()
                    } else {
                        showOffline = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showOffline = false
                        }
                    }
                }
            }
            // Safety timeout — if still connecting after 6 s, give up
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if isConnecting {
                    isConnecting = false
                    showOffline = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showOffline = false
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                // Control-Center style circular icon platter
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 26, height: 26)

                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.45)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "smartphone")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(showOffline ? .red : Color(red: 169/255, green: 169/255, blue: 169/255))
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    if showOffline {
                        Text("Offline")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(hover ? Color.primary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in hover = h }
        .animation(.easeInOut(duration: 0.2), value: showOffline)
    }
}

