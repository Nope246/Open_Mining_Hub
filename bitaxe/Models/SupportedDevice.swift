//
//  SupportedDevice.swift
//  bitaxe
//
//  Created by Brent Parks on 7/20/25.
//

import SwiftUI

// A struct to hold information about each supported device model.
struct SupportedDevice: Identifiable {
    let id = UUID()
    let modelName: String
    let status: SupportStatus
    let notes: String?

    enum SupportStatus: String {
        case fullySupported = "Fully Supported"
        case beta = "Beta"
        case inDevelopment = "In Development"
        case notSupported = "Not Supported"

        var color: Color {
            switch self {
            case .fullySupported: .green
            case .beta: .orange
            case .inDevelopment: .blue
            case .notSupported: .red
            }
        }
    }
}
