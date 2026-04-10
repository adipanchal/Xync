//
//  Device.swift
//  xync
//
//  Created by Aditya on 05/03/26.
//

import Foundation

struct Device: Identifiable, Hashable {
    let id: String // Serial is unique
    let serial: String
    let state: String // device, offline, unauthorized
    let model: String
    let marketName: String // Friendly name e.g. "Galaxy M34 5G"
    
    var isWireless: Bool {
        return serial.contains(":") || serial.contains(".")
    }
    
    var displayName: String {
        if !marketName.isEmpty {
            return marketName
        }
        return model.isEmpty ? serial : model
    }
}
