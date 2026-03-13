//
//  SetupWizardView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

struct SetupWizardView: View {
    @StateObject private var dependencyManager = DependencyManager.shared
    @Binding var setupComplete: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Welcome Text
            VStack(spacing: 12) {
                Text("Welcome to Xync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("First-time setup required")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Dependencies Info
            if !dependencyManager.isInstalling && !dependencyManager.installationComplete {
                VStack(alignment: .leading, spacing: 16) {
                    Text("We need to download the following:")
                        .font(.headline)
                    
                    DependencyRow(name: "scrcpy", description: "Screen mirroring tool", size: "~25 MB")
                    DependencyRow(name: "Android Platform Tools", description: "ADB and fastboot", size: "~15 MB")
                    
                    Text("Total download: ~40 MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: 400)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // Installation Progress
            if dependencyManager.isInstalling {
                VStack(spacing: 16) {
                    ProgressView(value: dependencyManager.progress) {
                        Text(dependencyManager.statusMessage)
                            .font(.headline)
                    }
                    .progressViewStyle(.linear)
                    .frame(width: 400)
                    
                    Text("This may take a few minutes...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Success Message
            if dependencyManager.installationComplete {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Setup Complete!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Xync is ready to use")
                        .foregroundColor(.secondary)
                }
            }
            
            // Error Message
            if let error = dependencyManager.installationError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Installation Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                if !dependencyManager.isInstalling {
                    if dependencyManager.installationComplete {
                        Button("Get Started") {
                            setupComplete = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .focusable(false)
                    } else if dependencyManager.installationError != nil {
                        Button("Retry") {
                            Task {
                                await dependencyManager.installDependencies()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .focusable(false)
                        
                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .focusable(false)
                    } else {
                        Button("Download & Install") {
                            Task {
                                await dependencyManager.installDependencies()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .focusable(false)
                        
                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .focusable(false)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct DependencyRow: View {
    let name: String
    let description: String
    let size: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(size)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
