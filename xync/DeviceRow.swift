//
//  DeviceRow.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct DeviceRow: View {
    let device: Device
    @Binding var stayAwake: Bool
    @Binding var turnScreenOff: Bool
    @Binding var alwaysOnTop: Bool
    @Binding var rotation: Int
    
    let onMirror: (Bool, String) -> Void
    let onStop: () -> Void
    let onReconnect: () -> Void
    let onForget: () -> Void
    let isMirroring: Bool
    
    @State private var showSettings = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: device.isWireless ? "wifi" : "cable.connector")
                .font(.title)
                .foregroundColor(device.isWireless ? .green : .blue)
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
                HStack(spacing: 8) {
                    
                    // Settings Gear
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings) {
                        DeviceSettingsPopover(
                            stayAwake: $stayAwake,
                            turnScreenOff: $turnScreenOff,
                            alwaysOnTop: $alwaysOnTop,
                            rotation: $rotation
                        )
                    }
                    
                    Divider().frame(height: 20)
                    
                    if isMirroring {
                        Text("Mirroring")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.trailing, 4)
                            
                        Button("Stop") {
                            onStop()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.regular)
                        .focusable(false)
                    } else {
                        Button("Mirror") {
                            onMirror(false, "back")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .focusable(false)
                        
                        Menu {
                            Button("Back Camera", action: { onMirror(true, "back") })
                            Button("Front Camera", action: { onMirror(true, "front") })
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 16))
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 36)
                        .padding(.leading, 8)
                    }
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
                            print("🔘 Connect button clicked for device: \(device.serial)")
                            onReconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .focusable(false)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(role: .destructive) {
                onForget()
            } label: {
                Label("Forget Device", systemImage: "trash")
            }
        }
    }
}
