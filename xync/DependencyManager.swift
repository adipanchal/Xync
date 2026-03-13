//
//  DependencyManager.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import Foundation
import AppKit
import Combine

class DependencyManager: ObservableObject {
    static let shared = DependencyManager()
    
    @Published var isInstalling = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var installationComplete = false
    @Published var installationError: String?
    
    private let fileManager = FileManager.default
    
    // App support directory for storing binaries
    var appSupportDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Xync", isDirectory: true)
    }
    
    var binDir: URL {
        appSupportDir.appendingPathComponent("bin", isDirectory: true)
    }
    
    // Download URLs
    private let scrcpyURL = "https://github.com/Genymobile/scrcpy/releases/download/v2.7/scrcpy-macos-v2.7.zip"
    private let adbURL = "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
    
    private init() {}
    
    // Check if dependencies are installed
    func areDependenciesInstalled() -> Bool {
        let scrcpyPath = binDir.appendingPathComponent("scrcpy").path
        let adbPath = binDir.appendingPathComponent("adb").path
        
        return fileManager.fileExists(atPath: scrcpyPath) &&
               fileManager.fileExists(atPath: adbPath)
    }
    
    // Main installation function
    func installDependencies() async {
        await MainActor.run {
            isInstalling = true
            progress = 0.0
            installationError = nil
            installationComplete = false
        }
        
        do {
            // Create directories
            try createDirectories()
            
            // Download and install scrcpy
            await updateStatus("Downloading scrcpy...")
            try await downloadAndInstallScrcpy()
            
            await updateProgress(0.5)
            
            // Download and install adb
            await updateStatus("Downloading Android Platform Tools...")
            try await downloadAndInstallAdb()
            
            await updateProgress(1.0)
            await updateStatus("Installation complete!")
            
            await MainActor.run {
                installationComplete = true
                isInstalling = false
            }
            
        } catch {
            await MainActor.run {
                installationError = error.localizedDescription
                isInstalling = false
            }
        }
    }
    
    private func createDirectories() throws {
        try fileManager.createDirectory(at: binDir, withIntermediateDirectories: true)
    }
    
    private func downloadAndInstallScrcpy() async throws {
        let zipURL = try await downloadFile(from: scrcpyURL, fileName: "scrcpy.zip")
        try await extractAndInstallScrcpy(from: zipURL)
        try fileManager.removeItem(at: zipURL)
    }
    
    private func downloadAndInstallAdb() async throws {
        let zipURL = try await downloadFile(from: adbURL, fileName: "platform-tools.zip")
        try await extractAndInstallAdb(from: zipURL)
        try fileManager.removeItem(at: zipURL)
    }
    
    private func downloadFile(from urlString: String, fileName: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "DependencyManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let destinationURL = appSupportDir.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        return destinationURL
    }
    
    private func extractAndInstallScrcpy(from zipURL: URL) async throws {
        await updateStatus("Extracting scrcpy...")
        
        let extractDir = appSupportDir.appendingPathComponent("scrcpy_temp")
        try? fileManager.removeItem(at: extractDir)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        // Unzip
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", extractDir.path]
        try process.run()
        process.waitUntilExit()
        
        // Find scrcpy binary in extracted files
        let contents = try fileManager.contentsOfDirectory(at: extractDir, includingPropertiesForKeys: nil)
        if let scrcpyDir = contents.first(where: { $0.lastPathComponent.contains("scrcpy") }) {
            let scrcpyBinary = scrcpyDir.appendingPathComponent("scrcpy")
            let destination = binDir.appendingPathComponent("scrcpy")
            
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            
            try fileManager.copyItem(at: scrcpyBinary, to: destination)
            try makeExecutable(destination)
        }
        
        try fileManager.removeItem(at: extractDir)
    }
    
    private func extractAndInstallAdb(from zipURL: URL) async throws {
        await updateStatus("Extracting Android Platform Tools...")
        
        let extractDir = appSupportDir.appendingPathComponent("platform_tools_temp")
        try? fileManager.removeItem(at: extractDir)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        // Unzip
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", extractDir.path]
        try process.run()
        process.waitUntilExit()
        
        // Copy adb binary
        let adbBinary = extractDir.appendingPathComponent("platform-tools/adb")
        let destination = binDir.appendingPathComponent("adb")
        
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.copyItem(at: adbBinary, to: destination)
        try makeExecutable(destination)
        
        try fileManager.removeItem(at: extractDir)
    }
    
    private func makeExecutable(_ url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", url.path]
        try process.run()
        process.waitUntilExit()
    }
    
    private func updateStatus(_ message: String) async {
        await MainActor.run {
            statusMessage = message
        }
    }
    
    private func updateProgress(_ value: Double) async {
        await MainActor.run {
            progress = value
        }
    }
}
