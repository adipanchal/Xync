//
//  xyncApp.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

@main
struct xyncApp: App {
    @AppStorage("setupComplete") private var setupComplete = false
    @State private var dependenciesInstalled = DependencyManager.shared.areDependenciesInstalled()
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
            Group {
                if setupComplete || dependenciesInstalled {
                    ContentView()
                        .frame(minWidth: 800, minHeight: 600)
                        .background(WindowAccessor())
                } else {
                    SetupWizardView(setupComplete: $setupComplete)
                        .frame(width: 600, height: 500)
                        .onAppear {
                            // Recheck dependencies when wizard appears
                            dependenciesInstalled = DependencyManager.shared.areDependenciesInstalled()
                            if dependenciesInstalled {
                                setupComplete = true
                            }
                        }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Xync") {
                    openWindow(id: "about")
                }
            }
        }
        
        Window("About Xync", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

