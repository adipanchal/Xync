//
//  DexDeviceRow.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct DexDeviceRow: View {
    let device: Device
    let onStartDex: (String) -> Void
    let onStop: () -> Void
    let onReconnect: () -> Void
    let onForget: () -> Void
    let isMirroring: Bool
    
    @State private var selectedResolution: String = "1920x1080"
    
    let resolutions = [
        "1920x1080",
        "2560x1440",
        "3840x2160",
        "1600x900",
        "1280x720"
    ]
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.title)
                .foregroundColor(.purple)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(device.serial)
                    .font(.subheadline)
                    .monospaced()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            
            Spacer()
            
            if device.state == "device" {
                if isMirroring {
                    Text("DeX Running")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.trailing, 4)
                        
                    Button("Stop") {
                        onStop()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.regular)
                    .focusable(false)
                } else {
                    Picker("Resolution", selection: $selectedResolution) {
                        ForEach(resolutions, id: \.self) { res in
                            Text(res).tag(res)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    .controlSize(.regular)
                    
                    Button("Start DeX") {
                        onStartDex(selectedResolution)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.regular)
                    .focusable(false)
                }
            } else {
                 HStack {
                    Text(device.state)
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                    
                    if device.state == "offline" || device.state == "disconnected" {
                        Button("Connect") {
                            print("🔘 DeX Connect button clicked for device: \(device.serial)")
                            onReconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .focusable(false)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button(role: .destructive) {
                onForget()
            } label: {
                Label("Forget Device", systemImage: "trash")
            }
        }
    }
}
