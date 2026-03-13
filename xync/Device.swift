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
    
    var isWireless: Bool {
        return serial.contains(":") || serial.contains(".")
    }
    
    var displayName: String {
        return model.isEmpty ? serial : model
    }
}
