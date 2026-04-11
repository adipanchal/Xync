//
//  SidebarView.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import SwiftUI

enum SidebarTab: CaseIterable {
    case dashboard
    case files
    case settings
    
    var rawValue: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .files: return "File Explorer"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .files: return "folder"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarTab
    
    private var navTabs: [SidebarTab] {
        [.dashboard, .files]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dashboard & File Explorer tabs
            ForEach(navTabs, id: \.self) { tab in
                Button(action: {
                    selection = tab
                }) {
                    sidebarLabel(tab: tab, isSelected: selection == tab)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            
            // Settings tab — uses SettingsLink to open native macOS Settings window
            SettingsLink {
                sidebarLabel(tab: .settings, isSelected: false)
            }
            .buttonStyle(.plain)
            .focusable(false)
            
            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    
    private func sidebarLabel(tab: SidebarTab, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tab.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .blue : .primary)
                .frame(width: 24)
            
            Text(tab.rawValue)
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.primary.opacity(0.04) : Color.clear)
        )
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
