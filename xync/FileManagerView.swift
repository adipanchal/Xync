//
//  FileManagerView.swift
//  xync
//
//  Created by Aditya on 29/03/26.
//

import SwiftUI
import AppKit

/// A plain AppKit label for toolbar use — macOS never applies pill/button styling to NSTextField.
struct PlainToolbarLabel: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.backgroundColor = .clear
        label.drawsBackground = false
        return label
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
}

struct FileManagerView: View {
    let device: Device
    @State private var currentPath: String = "/sdcard/"
    @State private var files: [FileItem] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var showNewFolderDialog = false
    @State private var newFolderName = ""
    @State private var selection = Set<String>()
    @State private var backHistory: [String] = []
    @State private var forwardHistory: [String] = []
    
    // Advanced Operations State
    @State private var clipboardItems = Set<String>()
    @State private var clipboardIsCut = false
    
    @State private var showRenameDialog = false
    @State private var renameTargetPath: String? = nil
    @State private var renameNewName = ""
    
    // Progress HUD State
    @State private var isProcessing = false
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0.0
    @State private var progressTotal: Double = 1.0
    
    enum StorageType: String {
        case `internal` = "Internal"
        case external = "External"
    }
    
    @State private var selectedStorageType: StorageType = .internal
    
    var folderTitle: String {
        if currentPath == "/" {
            return "Root"
        } else if currentPath == "/sdcard/" || currentPath == "/sdcard" || currentPath == "/storage/" {
            return device.displayName
        } else {
            return currentPath.components(separatedBy: "/").filter { !$0.isEmpty }.last ?? device.displayName
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            
            // File List
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if files.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Folder is empty or access denied.")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                Table(files, selection: $selection) {
                    TableColumn("Name") { file in
                        HStack {
                            Image(systemName: file.isDirectory ? "folder.fill" : "doc")
                                .foregroundColor(file.isDirectory ? .blue : .primary)
                                .font(.title3)
                                .frame(width: 20)
                            Text(file.name)
                                .font(.body)
                        }
                    }
                    TableColumn("Size") { file in
                        Text(formatSize(file))
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    TableColumn("Date") { file in
                        Text(file.date)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu(forSelectionType: String.self) { items in
                    if items.isEmpty {
                        Button(action: performPaste) {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                        .disabled(clipboardItems.isEmpty)
                        Button(action: { showNewFolderDialog = true }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button(action: loadFiles) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } else {
                        if items.count == 1, let path = items.first, let file = files.first(where: { $0.path == path }) {
                            Button(action: {
                                if file.isDirectory { navigateTo(path: file.path + "/") }
                                else { downloadFile(file: file) }
                            }) {
                                Label("Open", systemImage: "arrow.up.forward.app")
                            }
                            Divider()
                        }
                        
                        Button(action: {
                            clipboardItems = items
                            clipboardIsCut = true
                        }) {
                            Label(clipboardIsCut && clipboardItems == items ? "Cut (Selected)" : "Cut", systemImage: "scissors")
                        }
                        Button(action: {
                            clipboardItems = items
                            clipboardIsCut = false
                        }) {
                            Label(!clipboardIsCut && clipboardItems == items ? "Copy (Selected)" : "Copy", systemImage: "doc.on.doc")
                        }
                        
                        if items.count == 1, let path = items.first {
                            Button(action: {
                                if ShellManager.shared.duplicateFile(serial: device.serial, path: path) { loadFiles() }
                            }) {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(action: {
                                renameTargetPath = path
                                renameNewName = files.first(where: { $0.path == path })?.name ?? ""
                                showRenameDialog = true
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            selection = items
                            deleteSelected()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } primaryAction: { items in
                    if items.count == 1, let path = items.first, let file = files.first(where: { $0.path == path }) {
                        if file.isDirectory { navigateTo(path: file.path + "/") }
                        else { downloadFile(file: file) }
                    }
                }
            }
        }
        .onAppear {
            loadFiles()
            // Keep device awake while file manager is open to prevent connection drops
            DispatchQueue.global(qos: .background).async {
                ShellManager.shared.setStayAwake(serial: device.serial, enable: true)
            }
        }
        .onDisappear {
            // Allow device to sleep nominally natively when closed
            DispatchQueue.global(qos: .background).async {
                ShellManager.shared.setStayAwake(serial: device.serial, enable: false)
            }
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: { Text(errorMessage) })
        .alert("New Folder", isPresented: $showNewFolderDialog) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create", action: createFolder)
        } message: {
            Text("Enter a name for the new folder.")
        }
        .alert("Rename", isPresented: $showRenameDialog) {
            TextField("New Name", text: $renameNewName)
            Button("Cancel", role: .cancel) { renameTargetPath = nil }
            Button("Rename") {
                if let old = renameTargetPath {
                    if ShellManager.shared.renameFile(serial: device.serial, oldPath: old, newName: renameNewName) {
                        loadFiles()
                    } else {
                        showError = true
                        errorMessage = "Failed to rename."
                    }
                }
            }
        } message: {
             Text("Enter a new file or folder name.")
        }
        .navigationTitle(folderTitle)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ControlGroup {
                    Button(action: goBackHistory) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(backHistory.isEmpty)
                    .help("Backward")
                    
                    Button(action: goForwardHistory) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(forwardHistory.isEmpty)
                    .help("Forward")
                }
                .controlGroupStyle(.navigation)
            }

            ToolbarItem(placement: .navigation) {
                PlainToolbarLabel(text: folderTitle)
                    .padding(.horizontal, 12)
            }
            
            ToolbarItem(placement: .principal) {
                Picker("Storage", selection: $selectedStorageType) {
                    Text("Internal").tag(StorageType.internal)
                    Text("External").tag(StorageType.external)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: selectedStorageType) { _, newValue in
                    if newValue == .internal {
                        navigateTo(path: "/sdcard/")
                    } else {
                        navigateToExternalStorage()
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                ControlGroup {
                    Button(action: { showNewFolderDialog = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                    .help("New Folder")
                    
                    Button(action: uploadFile) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Upload to Phone")
                    
                    Button(action: loadFiles) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                if !clipboardItems.isEmpty || !selection.isEmpty {
                    ControlGroup {
                        if !clipboardItems.isEmpty {
                            Button(action: performPaste) {
                                Image(systemName: "doc.on.clipboard")
                            }
                            .help("Paste \(clipboardItems.count) Items")
                        }
                        
                        if !selection.isEmpty {
                            Button(action: downloadSelected) {
                                Image(systemName: "arrow.down.doc.fill")
                            }
                            .help("Download \(selection.count) items")
                            
                            Button(action: deleteSelected) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                            }
                            .help("Delete Selected")
                        }
                    }
                }
            }
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        if progressTotal > 1 {
                            ProgressView(value: progressValue, total: progressTotal) {
                                Text(progressMessage)
                                    .font(.headline)
                            } currentValueLabel: {
                                Text("\(Int(progressValue)) of \(Int(progressTotal))")
                            }
                            .progressViewStyle(.linear)
                            .frame(width: 250)
                            .padding()
                        } else {
                            ProgressView(progressMessage)
                                .padding()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 20)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func performPaste() {
        guard !clipboardItems.isEmpty else { return }
        
        isProcessing = true
        progressTotal = 1.0
        progressValue = 0.0
        progressMessage = clipboardIsCut ? "Moving \(clipboardItems.count) objects..." : "Copying \(clipboardItems.count) objects..."
        
        DispatchQueue.global().async {
            let success = ShellManager.shared.copyOrMoveFiles(
                serial: device.serial,
                sourcePaths: Array(clipboardItems),
                targetDir: currentPath,
                isMove: clipboardIsCut
            )
            DispatchQueue.main.async {
                isProcessing = false
                if success {
                    if clipboardIsCut {
                        clipboardItems.removeAll()
                        clipboardIsCut = false
                    }
                    loadFiles()
                } else {
                    isLoading = false
                    showError = true
                    errorMessage = "Failed to paste files."
                }
            }
        }
    }
    
    private func formatSize(_ file: FileItem) -> String {
        if file.isDirectory { return "--" }
        guard let bytes = Int64(file.size) else { return file.size }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func loadFiles() {
        isLoading = true
        DispatchQueue.global().async {
            let fetched = ShellManager.shared.listDirectory(serial: device.serial, path: currentPath)
            DispatchQueue.main.async {
                self.files = fetched
                self.isLoading = false
            }
        }
    }
    
    private func navigateTo(path: String) {
        if path != currentPath {
            backHistory.append(currentPath)
            forwardHistory.removeAll()
            currentPath = path
            loadFiles()
        }
    }
    
    /// When switching to External, skip the raw /storage/ listing and jump directly
    /// into the SD card folder (first folder that isn't 'emulated' or 'self').
    private func navigateToExternalStorage() {
        isLoading = true
        DispatchQueue.global().async {
            let entries = ShellManager.shared.listDirectory(serial: device.serial, path: "/storage/")
            // Find the actual SD card: skip 'emulated' and 'self' which are virtual
            let sdCard = entries.first(where: { $0.isDirectory && $0.name != "emulated" && $0.name != "self" })
            DispatchQueue.main.async {
                if let sd = sdCard {
                    // Go directly into the SD card folder
                    backHistory.append(currentPath)
                    forwardHistory.removeAll()
                    currentPath = "/storage/\(sd.name)/"
                    loadFiles()
                } else {
                    // Fallback: no SD card found, show /storage/ as-is
                    backHistory.append(currentPath)
                    forwardHistory.removeAll()
                    currentPath = "/storage/"
                    loadFiles()
                }
            }
        }
    }
    
    private func goBackHistory() {
        if let previous = backHistory.popLast() {
            forwardHistory.append(currentPath)
            currentPath = previous
            loadFiles()
        }
    }
    
    private func goForwardHistory() {
        if let next = forwardHistory.popLast() {
            backHistory.append(currentPath)
            currentPath = next
            loadFiles()
        }
    }
    
    private func downloadFile(file: FileItem) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.prompt = "Download"
        
        if panel.runModal() == .OK, let localURL = panel.url {
            DispatchQueue.global().async {
                let success = ShellManager.shared.pullFile(serial: device.serial, remotePath: file.path, localPath: localURL.path)
                DispatchQueue.main.async {
                    if !success {
                        errorMessage = "Failed to download \(file.name)."
                        showError = true
                    }
                }
            }
        }
    }
    
    private func uploadFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.prompt = "Upload"
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            if urls.isEmpty { return }
            
            isProcessing = true
            progressTotal = Double(urls.count)
            progressValue = 0
            progressMessage = "Uploading Files..."
            
            DispatchQueue.global().async {
                var allSuccess = true
                for (index, localURL) in urls.enumerated() {
                    let fileName = localURL.lastPathComponent
                    let remotePath = self.currentPath + fileName
                    let success = ShellManager.shared.pushFile(serial: self.device.serial, localPath: localURL.path, remotePath: remotePath)
                    if !success { allSuccess = false }
                    
                    DispatchQueue.main.async {
                        self.progressValue = Double(index + 1)
                    }
                }
                
                DispatchQueue.main.async {
                    isProcessing = false
                    if allSuccess {
                        loadFiles()
                    } else {
                        errorMessage = "Failed to upload some items."
                        showError = true
                    }
                }
            }
        }
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let newPath = currentPath + newFolderName
        
        DispatchQueue.global().async {
            let success = ShellManager.shared.createDirectory(serial: device.serial, remotePath: newPath)
            DispatchQueue.main.async {
                if success {
                    newFolderName = ""
                    loadFiles()
                } else {
                    errorMessage = "Failed to create folder."
                    showError = true
                }
            }
        }
    }
    
    private func deleteFile(file: FileItem) {
        // Confirmation could be added here
        isProcessing = true
        progressTotal = 1.0
        progressValue = 0.0
        progressMessage = "Deleting \(file.name)..."
        
        DispatchQueue.global().async {
            let success = ShellManager.shared.deleteFile(serial: device.serial, remotePath: file.path)
            DispatchQueue.main.async {
                isProcessing = false
                if success {
                    loadFiles()
                } else {
                    errorMessage = "Failed to delete \(file.name)."
                    showError = true
                }
            }
        }
    }
    
    private func downloadSelected() {
        let selectedFiles = files.filter { selection.contains($0.id) }
        guard !selectedFiles.isEmpty else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Save Downloads Here"
        
        if panel.runModal() == .OK, let localDir = panel.url {
            isProcessing = true
            progressTotal = Double(selectedFiles.count)
            progressValue = 0
            progressMessage = "Downloading Files..."
            
            DispatchQueue.global().async {
                var allSuccess = true
                for (index, file) in selectedFiles.enumerated() {
                    let localPath = localDir.appendingPathComponent(file.name).path
                    let success = ShellManager.shared.pullFile(serial: device.serial, remotePath: file.path, localPath: localPath)
                    if !success { allSuccess = false }
                    DispatchQueue.main.async {
                        self.progressValue = Double(index + 1)
                    }
                }
                DispatchQueue.main.async {
                    isProcessing = false
                    selection.removeAll()
                    if !allSuccess {
                        errorMessage = "Some files failed to download."
                        showError = true
                    }
                }
            }
        }
    }
    
    private func deleteSelected() {
        let selectedFiles = files.filter { selection.contains($0.id) }
        guard !selectedFiles.isEmpty else { return }
        
        isProcessing = true
        progressTotal = Double(selectedFiles.count)
        progressValue = 0
        progressMessage = "Deleting Files..."
        
        DispatchQueue.global().async {
            var allSuccess = true
            for (index, file) in selectedFiles.enumerated() {
                let success = ShellManager.shared.deleteFile(serial: device.serial, remotePath: file.path)
                if !success { allSuccess = false }
                DispatchQueue.main.async {
                    self.progressValue = Double(index + 1)
                }
            }
            DispatchQueue.main.async {
                isProcessing = false
                selection.removeAll()
                if allSuccess {
                    loadFiles()
                } else {
                    errorMessage = "Failed to delete some items."
                    showError = true
                }
            }
        }
    }
}
