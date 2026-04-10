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
        .frame(width: 450, height: 380)
    }
}

// General settings only — used in device card popover and Settings window
struct GeneralSettingsView: View {
    @AppStorage("dexResolution") private var dexResolution: String = "1920x1080"
    @AppStorage("stayAwake") private var stayAwake = true
    @AppStorage("turnScreenOff") private var turnScreenOff = false
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rotation") private var rotation = 0
    
    let resolutions = [
        "1920x1080",
        "2560x1440",
        "3840x2160",
        "1600x900",
        "1280x720"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Mirroring Settings section
            Text("Mirroring Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Stay Awake", isOn: $stayAwake)
                Toggle("Turn Screen Off", isOn: $turnScreenOff)
                Toggle("Always on Top", isOn: $alwaysOnTop)
                
                HStack {
                    Text("Rotation")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $rotation) {
                        Text("0° (Normal)").tag(0)
                        Text("90°").tag(1)
                        Text("180°").tag(2)
                        Text("270°").tag(3)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
            
            Divider()
                .padding(.vertical, 18)
            
            // Samsung DeX section
            Text("Samsung DeX")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
            
            HStack {
                Text("DeX Resolution")
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $dexResolution) {
                    ForEach(resolutions, id: \.self) { res in
                        Text(res).tag(res)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
