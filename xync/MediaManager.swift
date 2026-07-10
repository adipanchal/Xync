//
//  MediaManager.swift
//  xync
//
//  Created by Aditya on 25/06/26.
//

import Foundation
import Combine

struct MediaState {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var isPlaying: Bool = false
}

class MediaManager: ObservableObject {
    static let shared = MediaManager()
    
    @Published var currentMediaState: MediaState = MediaState()
    private var timer: Timer?
    private var activeSerial: String?
    
    private var subscribers = Set<String>()
    
    func startPolling(serial: String, subscriber: String = "default") {
        subscribers.insert(subscriber)
        
        if self.activeSerial == serial && timer != nil { return }
        self.activeSerial = serial
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchMediaState()
        }
        // Also run on main runloop so it fires even during UI tracking (like menus)
        RunLoop.main.add(timer!, forMode: .common)
        
        fetchMediaState() // Initial fetch
    }
    
    func stopPolling(subscriber: String = "default") {
        subscribers.remove(subscriber)
        
        if subscribers.isEmpty {
            timer?.invalidate()
            timer = nil
            // Deliberately NOT clearing activeSerial here, so playback buttons (Play/Pause)
            // can still send commands to the last known device if needed.
            DispatchQueue.main.async {
                self.currentMediaState = MediaState()
            }
        }
    }
    
    func fetchMediaState() {
        guard let serial = activeSerial else { return }
        DispatchQueue.global(qos: .background).async {
            let cmd = "'\(ShellManager.shared.adbPath)' -s \(serial) shell dumpsys media_session"
            let output = ShellManager.shared.run(cmd)
            
            // Save dump for debugging if needed
            try? output.write(to: URL(fileURLWithPath: "/tmp/xync_media_debug.txt"), atomically: true, encoding: .utf8)
            
            var newState = MediaState()
            
            let chunks = output.components(separatedBy: "Record")
            var textToParse = output
            if chunks.count > 1 {
                if let active = chunks.first(where: { $0.contains("state=3") || $0.contains("PLAYING(3)") }) {
                    textToParse = active
                } else if let paused = chunks.first(where: { $0.contains("state=2") || $0.contains("PAUSED(2)") }) {
                    textToParse = paused
                } else if let withTitle = chunks.first(where: { $0.contains("TITLE") || $0.contains("description=") }) {
                    textToParse = withTitle
                }
            }
            
            if textToParse.contains("state=3") || textToParse.contains("PLAYING(3)") {
                newState.isPlaying = true
            }
            
            // Extract Title
            if let t = self.extractWithRegex(textToParse, pattern: #"android\.media\.metadata\.TITLE=(?:.*?:\s*)?([^,\n\}]+)"#) {
                newState.title = t
            } else if let t = self.extractWithRegex(textToParse, pattern: #"\bTITLE=(?:.*?:\s*)?([^,\n\}]+)"#) {
                newState.title = t
            } else if let t = self.extractWithRegex(textToParse, pattern: #"description=([^,\n]+)"#) {
                newState.title = t
            }
            
            // Extract Artist
            if let a = self.extractWithRegex(textToParse, pattern: #"android\.media\.metadata\.ARTIST=(?:.*?:\s*)?([^,\n\}]+)"#) {
                newState.artist = a
            } else if let a = self.extractWithRegex(textToParse, pattern: #"\bARTIST=(?:.*?:\s*)?([^,\n\}]+)"#) {
                newState.artist = a
            } else if let a = self.extractWithRegex(textToParse, pattern: #"description=[^,\n]+,\s*([^,\n]+)"#) {
                newState.artist = a
            }
            
            DispatchQueue.main.async {
                self.currentMediaState = newState
            }
        }
    }
    
    private func extractWithRegex(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        if let match = results.first {
            if match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                return nsString.substring(with: range).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    func playPause() {
        guard let serial = activeSerial else { return }
        // Optimistic UI update
        self.currentMediaState.isPlaying.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' -s \(serial) shell input keyevent 85")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchMediaState()
            }
        }
    }
    
    func nextTrack() {
        guard let serial = activeSerial else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' -s \(serial) shell input keyevent 87")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchMediaState()
            }
        }
    }
    
    func prevTrack() {
        guard let serial = activeSerial else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' -s \(serial) shell input keyevent 88")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchMediaState()
            }
        }
    }
    
    func volumeUp() {
        guard let serial = activeSerial else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' -s \(serial) shell input keyevent 24")
        }
    }
    
    func volumeDown() {
        guard let serial = activeSerial else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ShellManager.shared.run("'\(ShellManager.shared.adbPath)' -s \(serial) shell input keyevent 25")
        }
    }
}
