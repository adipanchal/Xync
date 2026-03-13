//
//  ContentView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var stayAwake = true
    @State private var turnScreenOff = false
    @State private var alwaysOnTop = false
    @State private var rotation = 0
    
    @State private var devices: [Device] = []
    @State private var showWizard = false
    
    // Subscribe to ShellManager update
    @ObservedObject var shell = ShellManager.shared
    
    // Timer for auto-refresh
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    @State private var selectedTab: SidebarTab = .wireless
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedTab)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            VStack(spacing: 0) {
                // Filtered Device List
                if filteredDevices.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: selectedTab == .wireless ? "wifi.slash" : (selectedTab == .dex ? "desktopcomputer.trianglebadge.exclamationmark" : "cable.connector.slash"))
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No devices found.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(filteredDevices) { device in
                        if selectedTab == .dex {
                            DexDeviceRow(
                                device: device,
                                onStartDex: { resolution in
                                    launchScrcpy(serial: device.serial, dexResolution: resolution)
                                },
                                onStop: {
                                    shell.stopScrcpy(serial: device.serial)
                                },
                                onReconnect: {
                                    reconnectDevice(device.serial)
                                },
                                onForget: {
                                    forgetDevice(device.serial)
                                },
                                isMirroring: shell.activeScrcpySessions[device.serial] == true
                            )
                        } else {
                            DeviceRow(
                                device: device,
                                stayAwake: $stayAwake,
                                turnScreenOff: $turnScreenOff,
                                alwaysOnTop: $alwaysOnTop,
                                rotation: $rotation,
                                onMirror: { isCamera, source in
                                    launchScrcpy(serial: device.serial, isCamera: isCamera, source: source)
                                },
                                onStop: {
                                    shell.stopScrcpy(serial: device.serial)
                                },
                                onReconnect: {
                                    reconnectDevice(device.serial)
                                },
                                onForget: {
                                    forgetDevice(device.serial)
                                },
                                isMirroring: shell.activeScrcpySessions[device.serial] == true
                            )
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Text(headerTitle)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedTab == .wireless {
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
            .sheet(isPresented: $showWizard) {
                ConnectionWizardView(onComplete: {
                    refreshDevices()
                    showWizard = false
                })
                .frame(width: 450, height: 320)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        // Sheet removed
        .onAppear {
            refreshDevices()
        }
        .onReceive(timer) { _ in
            refreshDevices()
        }
    }
    
    // MARK: - Helper Properties
    
    var headerTitle: String {
        switch selectedTab {
        case .wireless: return "Wireless Devices"
        case .wired: return "Wired Devices"
        case .dex: return "Samsung DeX"
        }
    }
    
    var filteredDevices: [Device] {
        switch selectedTab {
        case .wireless: return devices.filter { $0.isWireless }
        case .wired: return devices.filter { !$0.isWireless }
        case .dex: return devices // Show all for DeX
        }
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
    
    func reconnectDevice(_ serial: String) {
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
            
            // Refresh device list
            Thread.sleep(forTimeInterval: 1.0)
            print("🔄 Refreshing device list...")
            DispatchQueue.main.async {
                self.refreshDevices()
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

