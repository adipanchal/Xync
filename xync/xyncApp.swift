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
    
    var connectedDevices: [Device] { devices.filter { $0.state == "device" } }
    var otherDevices: [Device] { devices.filter { $0.state != "device" } }
    
    var body: some View {
        VStack(spacing: 0) {
            // Connected Devices
            VStack(spacing: 16) {
                if connectedDevices.isEmpty {
                    Text("No connected devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 30)
                } else {
                    ForEach(connectedDevices, id: \.id) { device in
                        MenuBarDeviceCard(device: device, shell: shell, onRefresh: refresh)
                        
                        if device.id != connectedDevices.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Other Devices Expansion
            if !otherDevices.isEmpty {
                VStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isOtherDevicesExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Other Devices")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isOtherDevicesExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
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
                            ForEach(otherDevices, id: \.id) { device in
                                OtherDeviceRow(device: device, shell: shell, onRefresh: refresh)
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // Footer
            HStack {
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
            .padding(12)
        }
        .frame(width: 270)
        .onAppear {
            refresh()
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

struct MenuBarDeviceCard: View {
    let device: Device
    @ObservedObject var shell: ShellManager
    let onRefresh: () -> Void
    
    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0
    
    var body: some View {
        let name = device.marketName.isEmpty ? (device.model == "Unknown" ? device.serial : device.model) : device.marketName
        
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    onRefresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            }
            
            // Action Grid
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            let isMirroring = shell.activeScrcpySessions[device.serial] == true
            
            LazyVGrid(columns: columns, spacing: 16) {
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
                ActionButton(icon: "camera", title: "Front Cam") {
                    shell.startScrcpy(serial: device.serial, stayAwake: false, turnScreenOff: false, alwaysOnTop: false, rotation: 0, isCamera: true, cameraSource: "front")
                }
                ActionButton(icon: "camera.fill", title: "Back Cam") {
                    shell.startScrcpy(serial: device.serial, stayAwake: false, turnScreenOff: false, alwaysOnTop: false, rotation: 0, isCamera: true, cameraSource: "back")
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
            .padding(.vertical, 4)
            
            // Full-width Disconnect Pill
            Button(action: {
                _ = shell.adbDisconnect(serial: device.serial)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { onRefresh() }
            }) {
                Text("Disconnect")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
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
    
    var body: some View {
        let name = device.marketName.isEmpty ? (device.model == "Unknown" ? device.serial : device.model) : device.marketName
        Button(action: {
            _ = shell.adbConnect(ip: device.serial)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onRefresh() }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "smartphone")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 169/255, green: 169/255, blue: 169/255))
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
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
    }
}

