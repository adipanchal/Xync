//
//  SettingsView.swift
//  xync
//
//  Created by Aditya on 09/04/26.
//

import SwiftUI

// Full Settings window with tabs (General + About) — used in macOS Settings scene
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 450)
    }
}

// General settings only — used in device card popover and Settings window
struct GeneralSettingsView: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("hideFromDock") private var hideFromDock = false
    
    @AppStorage("dexResolution") private var dexResolution: String = "1920x1080"
    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0
    
    @StateObject private var dependencyManager = DependencyManager.shared
    
    let resolutions = [
        "1920x1080",
        "2560x1440",
        "3840x2160",
        "1600x900",
        "1280x720"
    ]
    
    var body: some View {
        Form {
            Section {
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                Toggle("Hide from Dock (Menu Bar only)", isOn: $hideFromDock)
                    .disabled(!showInMenuBar)
            }
            
            Section("Mirroring Settings") {
                Toggle("Stay Awake", isOn: $stayAwake)
                Toggle("Turn Screen Off", isOn: $turnScreenOff)
                Toggle("Always on Top", isOn: $alwaysOnTop)
                
                Picker("Rotation", selection: $rotation) {
                    Text("0° (Normal)").tag(0)
                    Text("90°").tag(1)
                    Text("180°").tag(2)
                    Text("270°").tag(3)
                }
            }
            
            Section("Samsung DeX") {
                Picker("DeX Resolution", selection: $dexResolution) {
                    ForEach(resolutions, id: \.self) { res in
                        Text(res).tag(res)
                    }
                }
            }
            
            Section("Advanced") {
                HStack(alignment: .center) {
                    Text("Dependencies")
                    Spacer()
                    if dependencyManager.isInstalling {
                        ProgressView(value: dependencyManager.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                        Text(dependencyManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        if dependencyManager.installationComplete {
                            Text("Done! Restart Xync.")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if let error = dependencyManager.installationError {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button("Reinstall") {
                            Task {
                                await dependencyManager.installDependencies()
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// Lightweight settings shown in the per-device popover — only Mirroring & DeX.
struct DeviceMirrorSettingsView: View {
    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0
    @AppStorage("dexResolution") private var dexResolution: String = "1920x1080"
    
    let resolutions = ["1920x1080", "2560x1440", "3840x2160", "1600x900", "1280x720"]
    
    var body: some View {
        Form {
            Section("Mirroring") {
                Toggle("Stay Awake", isOn: $stayAwake)
                Toggle("Turn Screen Off", isOn: $turnScreenOff)
                Toggle("Always on Top", isOn: $alwaysOnTop)
                Picker("Rotation", selection: $rotation) {
                    Text("0° (Normal)").tag(0)
                    Text("90°").tag(1)
                    Text("180°").tag(2)
                    Text("270°").tag(3)
                }
            }
            Section("Samsung DeX") {
                Picker("DeX Resolution", selection: $dexResolution) {
                    ForEach(resolutions, id: \.self) { res in
                        Text(res).tag(res)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
