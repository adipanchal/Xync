//
//  UpdateManager.swift
//  xync
//
//  Created by Aditya on 14/03/26.
//

import Foundation
import AppKit

class UpdateManager: ObservableObject {
    @Published var showUpdateAlert = false
    @Published var updateVersion = ""
    @Published var updateURL: URL?
    
    func checkForUpdates() {
        // Fetch the latest release from the GitHub public API
        guard let url = URL(string: "https://api.github.com/repos/adipanchal/xync/releases/latest") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Update check failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrlString = json["html_url"] as? String,
                   let updateUrl = URL(string: htmlUrlString) {
                    
                    // Strip the "v" prefix if it exists (e.g. "v1.1.0" -> "1.1.0")
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    
                    // Get the app's current version
                    if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        
                        // Compare the versions natively correctly (e.g. 1.2 > 1.1)
                        if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                            DispatchQueue.main.async {
                                self?.updateVersion = latestVersion
                                self?.updateURL = updateUrl
                                self?.showUpdateAlert = true
                            }
                        }
                    }
                }
            } catch {
                print("Error parsing update JSON: \(error)")
            }
        }
        task.resume()
    }
    
    func openUpdate() {
        if let url = updateURL {
            NSWorkspace.shared.open(url)
        }
    }
}
