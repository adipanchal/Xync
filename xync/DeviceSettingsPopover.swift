//
//  DeviceSettingsPopover.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct DeviceSettingsPopover: View {
    @Binding var stayAwake: Bool
    @Binding var turnScreenOff: Bool
    @Binding var alwaysOnTop: Bool
    @Binding var rotation: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mirroring Settings")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Stay Awake", isOn: $stayAwake)
                    .toggleStyle(.checkbox)
                
                Toggle("Turn Screen Off", isOn: $turnScreenOff)
                    .toggleStyle(.checkbox)
                
                Toggle("Always on Top", isOn: $alwaysOnTop)
                    .toggleStyle(.checkbox)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Rotation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $rotation) {
                    Text("0° (Normal)").tag(0)
                    Text("90°").tag(1)
                    Text("180°").tag(2)
                    Text("270°").tag(3)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}
