//
//  GlassButton.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

/// Modern macOS Liquid Glass button component
struct GlassButton: View {
    let systemImage: String
    let action: () -> Void
    var helpText: String = ""
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .background(.thickMaterial, in: Circle())
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}
