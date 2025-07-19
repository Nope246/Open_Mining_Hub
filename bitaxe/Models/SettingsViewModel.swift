// Project- Bitaxe Dashboard
//  SettingsViewModel.swift
//  bitaxe
//
//  Created by Brent Parks on 5/31/25.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    // Store the IP list as raw Data using AppStorage
    @AppStorage("targetIPs_v2_data") private var ipListStoreData: Data = Data()

    // This will be the source of truth for your UI and logic
    @Published var currentIPs: [EditableIP] = []

    struct EditableIP: Identifiable {
        let id = UUID()
        var address: String
    }

    init() {
        // Decode the Data into [String] and then into [EditableIP]
        if let decodedIPs = try? JSONDecoder().decode([String].self, from: ipListStoreData) {
            self.currentIPs = decodedIPs.map { EditableIP(address: $0) }
        } else {
            // If decoding fails (e.g., first run or corrupted data), start fresh
            self.currentIPs = []
        }
    }

    func addIP() {
        currentIPs.append(EditableIP(address: ""))
        // No need to save immediately, saveIPs will handle it
    }

    func deleteIP(at offsets: IndexSet) {
        currentIPs.remove(atOffsets: offsets)
        // No need to save immediately, saveIPs will handle it
    }

    func saveIPs() {
        // Convert [EditableIP] back to [String]
        let ipsToStore = currentIPs.map { $0.address.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        // Encode [String] to Data and save
        if let encodedData = try? JSONEncoder().encode(ipsToStore) {
            ipListStoreData = encodedData
            // Optionally provide user feedback (e.g., an alert)
            print("IP List saved successfully.")
        } else {
            // Handle encoding error
            print("Failed to save IP List.")
            // Optionally show an error to the user
        }
    }
}


//  End of SettingsViewModel.swift
