//
//  ContentView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0
    @AppStorage("dexResolution") private var dexResolution = "1920x1080"
    @AppStorage("xyncEnabled") private var xyncEnabled = true
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var devices: [Device] = []
    @State private var showWizard = false
    @State private var selectedFileDevice: Device? = nil
    @StateObject private var updateManager = UpdateManager()
    
    // Subscribe to ShellManager update
    @ObservedObject var shell = ShellManager.shared
    
    // Timer for auto-refresh
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    @State private var selectedTab: SidebarTab = .dashboard
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedTab)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            VStack(spacing: 0) {
                if let device = selectedFileDevice, selectedTab == .files {
                    FileManagerView(device: device)
                        .navigationSubtitle(device.displayName)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button(action: { selectedFileDevice = nil }) {
                                    Label("Back", systemImage: "chevron.left")
                                }
                            }
                        }
                } else {
                    // Filtered Device List
                if filteredDevices.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: selectedTab == .dashboard ? "square.grid.2x2" : "folder.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No devices found.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    Group {
                        if selectedTab == .files {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(Array(filteredDevices.enumerated()), id: \.element.id) { index, device in
                                        Button {
                                            selectedFileDevice = device
                                        } label: {
                                            HStack(spacing: 14) {
                                                // Phone icon (small)
                                                let topColor = Color(red: 0.16, green: 0.16, blue: 0.16)
                                                let bottomColor = Color(red: 0.04, green: 0.04, blue: 0.04)
                                                
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            stops: [
                                                                .init(color: topColor, location: 0.0),
                                                                .init(color: bottomColor, location: 1.0)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                            .stroke(
                                                                LinearGradient(
                                                                    stops: [
                                                                        .init(color: Color.white.opacity(0.4), location: 0.0),
                                                                        .init(color: Color.white.opacity(0.12), location: 0.3),
                                                                        .init(color: Color.white.opacity(0.02), location: 0.6),
                                                                        .init(color: Color.white.opacity(0.1), location: 1.0)
                                                                    ],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                                    .shadow(color: Color.black.opacity(colorScheme == .light ? 0.2 : 0), radius: colorScheme == .light ? 4 : 0, x: 0, y: colorScheme == .light ? 2 : 0)
                                                    .frame(width: 28, height: 44)

                                                
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(device.displayName)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    Text(device.serial)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 14)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Divider between items (not after last)
                                        if index < filteredDevices.count - 1 {
                                            Divider()
                                                .background(Color.primary.opacity(0.08))
                                                .padding(.horizontal, 18)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                )
                                .padding()
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    // Connected Devices at the top
                                    let connected = filteredDevices.filter { $0.state == "device" }
                                    let activeDevice = connected.first
                                    let inactiveConnected = connected.dropFirst()

                                    if let active = activeDevice {
                                        DeviceRow(
                                            device: active,
                                            onMirror: { isCamera, source in
                                                launchScrcpy(serial: active.serial, isCamera: isCamera, source: source)
                                            },
                                            onDex: {
                                                launchScrcpy(serial: active.serial, dexResolution: dexResolution)
                                            },
                                            onFiles: {
                                                selectedFileDevice = active
                                                selectedTab = .files
                                            },
                                            onStop: {
                                                shell.stopScrcpy(serial: active.serial)
                                            },
                                            onReconnect: { completion in
                                                reconnectDevice(active.serial, completion: completion)
                                            },
                                            onDisconnect: {
                                                _ = shell.adbDisconnect(serial: active.serial)
                                                refreshDevices()
                                            },
                                            onForget: {
                                                forgetDevice(active.serial)
                                            },
                                            isMirroring: shell.activeScrcpySessions[active.serial] == true
                                        )
                                    }

                                    // Remaining devices under All Devices
                                    let disconnected = filteredDevices.filter { $0.state != "device" }
                                    let allOther = Array(inactiveConnected) + disconnected
                                    if !allOther.isEmpty {
                                        HStack {
                                            Text("All Devices")
                                                .font(.headline)
                                                .padding(.top, 16)
                                                .padding(.bottom, 8)
                                            Spacer()
                                        }

                                        VStack(spacing: 12) {
                                            ForEach(allOther) { device in
                                                DeviceRow(
                                                    device: device,
                                                    onMirror: { _, _ in },
                                                    onDex: { },
                                                    onFiles: { },
                                                    onStop: { },
                                                    onReconnect: { completion in
                                                        reconnectDevice(device.serial, completion: completion)
                                                    },
                                                    onDisconnect: {
                                                        _ = shell.adbDisconnect(serial: device.serial)
                                                        refreshDevices()
                                                    },
                                                    onForget: {
                                                        forgetDevice(device.serial)
                                                    },
                                                    isMirroring: false
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .id(selectedTab)
                    
                    if selectedTab == .files {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 11))
                            Text("In wireless mode, keep your phone screen on for a stable connection.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if selectedFileDevice == nil {
                    ToolbarItem(placement: .navigation) {
                        Text(headerTitle)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                    
                    ToolbarItemGroup(placement: .primaryAction) {
                        if selectedTab == .dashboard {
                            Button(action: { showWizard = true }) {
                                Label("Add Device", systemImage: "plus")
                            }
                            .help("Add New Device")
                        }
                        
                        Button(action: { refreshDevices() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .help("Refresh Devices")
                    }
                }
            }
            .sheet(isPresented: $showWizard) {
                ConnectionWizardView(onComplete: {
                    refreshDevices()
                    showWizard = false
                })
                .frame(width: 450, height: 320)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .files {
                selectedFileDevice = nil
            }
        }
        // Sheet removed
        .onAppear {
            refreshDevices()
            updateManager.checkForUpdates()
        }
        .onReceive(timer) { _ in
            if xyncEnabled { refreshDevices() }
        }
        .alert("Update Available 🚀", isPresented: $updateManager.showUpdateAlert) {
            Button("Download Update", role: .cancel) {
                updateManager.openUpdate()
            }
            Button("Later") { }
        } message: {
            Text("Version \(updateManager.updateVersion) of Xync is now available! Would you like to download it now?")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToFiles"))) { notification in
            if let device = notification.object as? Device {
                selectedFileDevice = device
                selectedTab = .files
            }
        }
    }
    
    // MARK: - Helper Properties
    
    var headerTitle: String {
        switch selectedTab {
        case .dashboard: return "Dashboard"
        case .files: return "File Explorer"
        case .settings: return "Dashboard"
        }
    }
    
    var filteredDevices: [Device] {
        return devices
    }
    
    // MARK: - Actions
    
    func refreshDevices() {
        print("🔄 Starting device refresh...")
        DispatchQueue.global().async {
            let list = ShellManager.shared.listDevices()
            print("📋 Got \(list.count) devices from adb")
            for device in list {
                print("  - \(device.displayName) (\(device.serial)): \(device.state)")
            }
            DispatchQueue.main.async {
                print("🔄 Updating UI with \(list.count) devices")
                self.devices = list
            }
        }
    }
    
    func reconnectDevice(_ serial: String, completion: ((Bool) -> Void)? = nil) {
        print("🔄 Reconnect requested for: \(serial)")
        
        DispatchQueue.global().async {
            // Extract IP from serial (format: IP:PORT)
            let ip: String
            if serial.contains(":") {
                // Wireless device - extract IP part
                ip = serial.components(separatedBy: ":").first ?? serial
                print("📱 Extracted IP: \(ip) from serial: \(serial)")
            } else {
                // USB device - use serial as-is
                ip = serial
                print("🔌 USB device, using serial: \(serial)")
            }
            
            // Disconnect first
            print("❌ Disconnecting...")
            let disconnectResult = ShellManager.shared.adbDisconnect(serial: serial)
            print("Disconnect result: \(disconnectResult)")
            
            // Wait a moment
            Thread.sleep(forTimeInterval: 0.5)
            
            // Reconnect
            print("✅ Connecting to \(ip)...")
            let result = ShellManager.shared.adbConnect(ip: ip)
            print("Connect result: \(result)")
            
            // Check if connection was successful
            let success = result.contains("connected") && !result.contains("failed")
            
            // Refresh device list
            Thread.sleep(forTimeInterval: 1.0)
            print("🔄 Refreshing device list...")
            DispatchQueue.main.async {
                self.refreshDevices()
                completion?(success)
            }
        }
    }
    
    func launchScrcpy(serial: String, isCamera: Bool = false, source: String = "back", dexResolution: String? = nil) {
        ShellManager.shared.startScrcpy(
            serial: serial,
            stayAwake: stayAwake,
            turnScreenOff: turnScreenOff,
            alwaysOnTop: alwaysOnTop,
            rotation: rotation,
            isCamera: isCamera,
            cameraSource: source,
            dexResolution: dexResolution
        )
    }
    
    func forgetDevice(_ serial: String) {
        print("🗑️ Forget requested for: \(serial)")
        DispatchQueue.global().async {
            ShellManager.shared.forgetDevice(serial: serial)
            DispatchQueue.main.async {
                self.refreshDevices()
            }
        }
    }
}

// MARK: - Native Visual Effect Background
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
