// DeviceConfigUpdater.swift

import Foundation

// This struct now matches the API specification with camelCase properties.
struct SystemSettings: Codable {
    // System Settings
    let hostname: String?
    
    // Pool Settings
    let stratumURL: String?
    let stratumPort: Int?
    let stratumUser: String?
    let stratumPassword: String?
    
    // Fallback Pool Settings
    let fallbackStratumURL: String?
    let fallbackStratumPort: Int?
    let fallbackStratumUser: String?
    let fallbackStratumPassword: String?
    
    // --- Fan Control Settings ---
    let autofanspeed: Bool?
    let fanspeed: Int?
    let temptarget: Int?
    let overheat_mode: Int?
    
    // --- Performance Settings ---
    let frequency: Int?
    let coreVoltage: Int?

    // --- Statistics Settings ---
    let statsLimit: Int?

    // --- NerdQaxe Specific Settings ---
    let autoTune: Bool?
    let powerTune: Int?

    // A convenience initializer to create a settings object with specific values.
    init(hostname: String? = nil, stratumURL: String? = nil, stratumPort: Int? = nil, stratumUser: String? = nil, stratumPassword: String? = nil, fallbackStratumURL: String? = nil, fallbackStratumPort: Int? = nil, fallbackStratumUser: String? = nil, fallbackStratumPassword: String? = nil, autofanspeed: Bool? = nil, fanspeed: Int? = nil, temptarget: Int? = nil, overheat_mode: Int? = nil, frequency: Int? = nil, coreVoltage: Int? = nil, statsLimit: Int? = nil, autoTune: Bool? = nil, powerTune: Int? = nil) {
        self.hostname = hostname
        self.stratumURL = stratumURL
        self.stratumPort = stratumPort
        self.stratumUser = stratumUser
        self.stratumPassword = stratumPassword
        self.fallbackStratumURL = fallbackStratumURL
        self.fallbackStratumPort = fallbackStratumPort
        self.fallbackStratumUser = fallbackStratumUser
        self.fallbackStratumPassword = fallbackStratumPassword
        self.autofanspeed = autofanspeed
        self.fanspeed = fanspeed
        self.temptarget = temptarget
        self.overheat_mode = overheat_mode
        self.frequency = frequency
        self.coreVoltage = coreVoltage
        self.statsLimit = statsLimit
        self.autoTune = autoTune
        self.powerTune = powerTune
    }
}


enum ConfigUpdateError: Error, LocalizedError {
    case invalidURL
    case jsonEncodingFailed(Error)
    case requestFailed(Error)
    case invalidResponse(URLResponse?)
    case serverError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The device URL is invalid."
        case .jsonEncodingFailed:
            return "Failed to encode the configuration data."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .serverError(let statusCode, let message):
            return "Save failed with status \(statusCode). \(message ?? "")"
        }
    }
}

/// Sends updated settings to a Bitaxe device.
func updateDeviceSettings(deviceIP: String, settings: SystemSettings, completion: @escaping (Result<Bool, ConfigUpdateError>) -> Void) {
    
    guard let url = URL(string: "http://\(deviceIP)/api/system") else {
        DispatchQueue.main.async {
            completion(.failure(.invalidURL))
        }
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(settings)
        
        if let body = request.httpBody, let jsonString = String(data: body, encoding: .utf8) {
            print("[DeviceSettingsUpdater] Sending JSON: \(jsonString)")
        }
        
    } catch {
        DispatchQueue.main.async {
            completion(.failure(.jsonEncodingFailed(error)))
        }
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(response)))
                return
            }

            if httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                var errorMessage: String?
                if let data = data, let message = String(data: data, encoding: .utf8) {
                    errorMessage = message
                }
                completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
            }
        }
    }
    task.resume()
}
