//
//  OtaUpdater.swift
//  bitaxe
//
//  Created by Brent Parks on 6/16/25.
//

// OtaUpdater.swift

import Foundation

// Enum to define the type of OTA update.
enum OtaUpdateType {
    case firmware
    case webInterface

    // The API endpoint for the update type.
    var endpoint: String {
        switch self {
        case .firmware:
            // Endpoint for firmware update
            return "/api/system/OTA"
        case .webInterface:
            // Endpoint for web interface (www) update
            return "/api/system/OTAWWW"
        }
    }

    /// Validates the file URL based on the expected naming convention for the update type.
    /// - Parameter fileURL: The URL of the file to validate.
    /// - Returns: A boolean indicating if the filename is valid.
    func isValid(fileURL: URL) -> Bool {
        let filename = fileURL.lastPathComponent
        switch self {
        case .firmware:
            // Firmware files should end in .bin. Loosened validation to allow more flexibility.
            return filename.lowercased().hasSuffix(".bin")
        case .webInterface:
            // The web interface file is expected to be named "www.bin"
            return filename.lowercased() == "www.bin"
        }
    }
}

enum OTAError: Error, LocalizedError {
    case invalidURL
    case fileNotFound
    case invalidFilename
    case requestFailed(Error)
    case invalidResponse(URLResponse?)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The device URL is invalid."
        case .fileNotFound:
            return "The selected file could not be read."
        case .invalidFilename:
            return "The filename is not valid for this update type."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .serverError(let statusCode):
            return "The server returned an error with status code: \(statusCode)."
        }
    }
}


// --- NEW ---
// A dedicated session delegate class to handle OTA update progress and completion.
class OtaUpdateSessionDelegate: NSObject, URLSessionTaskDelegate {
    var progressHandler: ((Double) -> Void)?
    var completionHandler: ((Result<Bool, OTAError>) -> Void)?

    // This delegate method is called periodically with upload progress updates.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }

    // This delegate method is called when the entire task is complete.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Wrap the completion handler calls on the main thread so that any
        // published properties updated in the view model do not trigger thread
        // violations.
        let callCompletionOnMain: (Result<Bool, OTAError>) -> Void = { result in
            DispatchQueue.main.async {
                self.completionHandler?(result)
            }
        }

        if let error = error {
            callCompletionOnMain(.failure(.requestFailed(error)))
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            callCompletionOnMain(.failure(.invalidResponse(task.response)))
            return
        }

        if httpResponse.statusCode == 200 {
            callCompletionOnMain(.success(true))
        } else {
            callCompletionOnMain(.failure(.serverError(httpResponse.statusCode)))
        }
    }
}


/// Performs an Over-the-Air (OTA) update for a Bitaxe device, handling both firmware and web interface updates.
///
/// - Parameters:
///   - deviceIP: The IP address of the Bitaxe device.
///   - fileURL: The local file URL of the `.bin` file to upload.
///   - updateType: The type of update to perform (`.firmware` or `.webInterface`).
///   - progressHandler: A closure that receives progress updates as a Double between 0.0 and 1.0.
///   - completion: A closure executed on completion, returning a success boolean or an error.
func performOtaUpdate(deviceIP: String, fileURL: URL, updateType: OtaUpdateType, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<Bool, OTAError>) -> Void) {
    
    // 1. Validate the filename before proceeding.
    guard updateType.isValid(fileURL: fileURL) else {
        completion(.failure(.invalidFilename))
        return
    }

    // 2. Construct the target URL from the device IP and the correct endpoint.
    guard let url = URL(string: "http://\(deviceIP)\(updateType.endpoint)") else {
        completion(.failure(.invalidURL))
        return
    }

    // 3. Read the binary data from the local file.
    guard let binaryData = try? Data(contentsOf: fileURL) else {
        completion(.failure(.fileNotFound))
        return
    }

    // 4. Create and configure the URLRequest.
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

    // --- MODIFIED ---
    // 5. Use a URLSession with a custom delegate to handle the upload and track progress.
    let delegate = OtaUpdateSessionDelegate()
    delegate.progressHandler = progressHandler
    delegate.completionHandler = completion
    
    // A session configured with our delegate. The delegateQueue is nil to use a background queue.
    let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    
    // 6. Create and resume the upload task.
    let task = session.uploadTask(with: request, from: binaryData)
    task.resume()
}
