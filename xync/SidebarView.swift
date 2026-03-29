//
//  SidebarView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

enum SidebarTab: CaseIterable {
    case wireless
    case wired
    case dex
    case files
    
    var rawValue: String {
        switch self {
        case .wireless: return "Wireless"
        case .wired: return "Wired Mirror"
        case .dex: return "Samsung DeX"
        case .files: return "File Explorer"
        }
    }
    
    var icon: String {
        switch self {
        case .wireless: return "wifi"
        case .wired: return "cable.connector"
        case .dex: return "desktopcomputer"
        case .files: return "folder"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarTab
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                Button(action: {
                    selection = tab
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selection == tab ? .blue : .primary)
                            .frame(width: 24)
                        
                        Text(tab.rawValue)
                            .font(.title3)
                            .foregroundColor(selection == tab ? .blue : .primary)
                        
                        if tab == .files {
                            Text("BETA")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selection == tab ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            
            Spacer()
            
            Divider()
                .padding(.horizontal, 4)
            
            Button(action: { openWindow(id: "about") }) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("About")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

struct SidebarButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
        .cornerRadius(8)
        .foregroundColor(isSelected ? .blue : .primary)
    }
}
