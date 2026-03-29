//
//  FileItem.swift
//  xync
//
//  Created by Aditya on 29/03/26.
//

import Foundation

struct FileItem: Identifiable, Hashable {
    var id: String { path }
    let name: String
    let path: String
    let isDirectory: Bool
    let size: String
    let date: String
    let permissions: String
}
