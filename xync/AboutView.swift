//
//  AboutView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
                // App Icon & Name
                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    
                    Text("Xync")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Version \(version) (\(build))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 20)
                
                // Powered by
                HStack(spacing: 4) {
                    Text("Powered by")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("scrcpy")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Author Section
                VStack(spacing: 6) {
                    Text("Made by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Aditya Panchal")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text("@adipanchal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 8)
                
                // Copyright
                Text("© 2026 Aditya Panchal. All rights reserved.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .frame(width: 320, height: 350)
            .background(.ultraThinMaterial)
    }
}
