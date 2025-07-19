//
//  OtaUpdateViewModel.swift
//  bitaxe
//
//  Created by Brent Parks on 6/16/25.
//

// OtaUpdateViewModel.swift

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class OtaUpdateViewModel: ObservableObject {
    @Published var isFilePickerPresented = false
    @Published var updateStatusMessage: String?
    @Published var isUpdating = false
    @Published var updateSucceeded: Bool?

    // --- NEW ---
    @Published var uploadProgress: Double = 0.0

    private var currentUpdateType: OtaUpdateType?
    
    // We need the device's IP to perform the update
    private var deviceIP: String = ""

    func selectFile(for updateType: OtaUpdateType, deviceIP: String) {
        self.currentUpdateType = updateType
        self.deviceIP = deviceIP
        self.updateStatusMessage = nil
        self.updateSucceeded = nil
        
        // --- NEW ---
        self.uploadProgress = 0.0
        
        self.isFilePickerPresented = true
    }

    func performUpdate(with fileURL: URL) {
        guard let updateType = currentUpdateType else {
            updateStatusMessage = "Error: Update type not set."
            updateSucceeded = false
            return
        }
        
        // Begin accessing the security-scoped resource if needed
        let needsAccess = fileURL.startAccessingSecurityScopedResource()
        defer { if needsAccess { fileURL.stopAccessingSecurityScopedResource() } }
        
        // Start the update process
        isUpdating = true
        updateSucceeded = nil
        uploadProgress = 0.0
        updateStatusMessage = "Preparing to upload..."
        
        // --- MODIFIED ---
        // Call the updated function with a progress handler
        performOtaUpdate(deviceIP: self.deviceIP, fileURL: fileURL, updateType: updateType) { progress in
            // This closure is called by the delegate on the main thread
            self.uploadProgress = progress
            self.updateStatusMessage = "Uploading: \(Int(progress * 100))%"
        } completion: { result in
            // This is called by the delegate on the main thread
            self.isUpdating = false
            self.uploadProgress = 0.0 // Reset progress
            
            switch result {
            case .success:
                self.updateSucceeded = true
                self.updateStatusMessage = "Update successful! Device is rebooting."
            case .failure(let error):
                self.updateSucceeded = false
                self.updateStatusMessage = "Update Failed: \(error.localizedDescription)"
            }
        }
    }
}
