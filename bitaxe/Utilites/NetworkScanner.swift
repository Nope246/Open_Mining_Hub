// Project- Bitaxe Dashboard
//  NetworkScanner.swift
//  bitaxe
//
//  Created by Brent Parks on 5/31/25.
//


import Foundation


class NetworkScanner {
    private let apiEndpoint = "/api/system/info"
    private let restartEndpoint = "/api/system/restart"
    private let asicEndpoint = "/api/system/asic"
    private let statisticsEndpoint = "/api/system/statistics"
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        // Keep a short timeout for the online check, but slightly longer for the full data fetch.
        configuration.timeoutIntervalForRequest = 5.0
        configuration.timeoutIntervalForResource = 10.0
        self.session = URLSession(configuration: configuration)
    }

    /// Checks if a device is online by making a lightweight network request.
    func isDeviceOnline(ip: String) async -> Bool {
        guard let url = URL(string: "http://\(ip)\(apiEndpoint)") else { return false }
        var request = URLRequest(url: url)
        // **FIX:** Changed from HEAD to GET for better compatibility with device firmware.
        request.httpMethod = "GET"

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func scanForDevices(ips: [String]) async -> [BitaxeDevice] {
        var discoveredDevices: [BitaxeDevice] = []

        if ips.isEmpty {
            print("[NetworkScanner] No IPs provided to scan.")
            return []
        }
        print("[NetworkScanner] Starting scan for \(ips.count) IP(s)...")

        await withTaskGroup(of: BitaxeDevice?.self) { group in
            for ip in ips {
                group.addTask {
                    // Only fetch full details if the device is confirmed online first.
                    if await self.isDeviceOnline(ip: ip) {
                        return await self.fetchDeviceInfo(ip: ip)
                    }
                    return nil
                }
            }
            for await device in group {
                if let device = device {
                    discoveredDevices.append(device)
                }
            }
        }
        print("[NetworkScanner] Scan finished. Discovered \(discoveredDevices.count) device(s).")
        return discoveredDevices
    }

    func fetchDeviceInfo(ip: String) async -> BitaxeDevice? {
        guard let url = URL(string: "http://\(ip)\(apiEndpoint)") else {
            print("[NetworkScanner] Invalid URL for IP: \(ip)")
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            var deviceInfo = try JSONDecoder().decode(BitaxeDevice.self, from: data)
            deviceInfo.ip = ip
            return deviceInfo
        } catch {
            print("[NetworkScanner] FAILED to fetch/decode device info from IP: \(ip). Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAsicInfo(ip: String) async -> AsicInfo? {
        guard let url = URL(string: "http://\(ip)\(asicEndpoint)") else {
            print("[NetworkScanner] Invalid ASIC info URL for IP: \(ip)")
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[NetworkScanner] Bad HTTP response for ASIC info from \(ip)")
                return nil
            }
            
            let asicInfo = try JSONDecoder().decode(AsicInfo.self, from: data)
            return asicInfo
        } catch {
            print("[NetworkScanner] FAILED to fetch/decode ASIC info JSON from IP: \(ip). Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchDeviceStatistics(ip: String) async -> DeviceStatisticsResponse? {
        guard let url = URL(string: "http://\(ip)\(statisticsEndpoint)") else {
            print("[NetworkScanner] Invalid statistics URL for IP: \(ip)")
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[NetworkScanner] Bad HTTP response for statistics from \(ip)")
                return nil
            }

            let stats = try JSONDecoder().decode(DeviceStatisticsResponse.self, from: data)
            return stats
        } catch {
            print("[NetworkScanner] FAILED to fetch/decode statistics JSON from IP: \(ip). Error: \(error.localizedDescription)")
            return nil
        }
    }

    func restartDevice(ip: String) async -> Bool {
        guard let url = URL(string: "http://\(ip)\(restartEndpoint)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode([String:String]())

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            print("[NetworkScanner] Error restarting device at IP \(ip): \(error.localizedDescription)")
            return false
        }
    }
}
