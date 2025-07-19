// Project- Bitaxe Dashboard
//  BitaxeModels.swift
//  bitaxe
//
// Created by Brent Parks on 5/31/25.
//

import Foundation

// MARK: - Device Statistics
/// Represents the raw response from the `/api/system/statistics` endpoint.
struct DeviceStatisticsResponse: Codable {
    let currentTimestamp: Double?
    let labels: [String]?
    let statistics: [[Double]]?
}

/// A processed, chart-ready data point for a single series.
// --- FIX: Conformed to Equatable ---
struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}


// MARK: - AsicInfo
// This struct holds the performance capabilities of the device's ASIC.
struct AsicInfo: Codable, Hashable {
    let ASICModel: String?
    let boardFamily: String?
    let defaultFrequency: Int?
    let frequencyOptions: [Int]?
    let defaultVoltage: Int?
    let voltageOptions: [Int]?
}


// MARK: - Device Sort Option Enum
enum DeviceSortOption: String, CaseIterable, Identifiable {
    case hostname = "Hostname"
    case currentHashRate = "Current Hash Rate"
    case wattage = "Wattage"
    case bestSessionDiff = "Session Difficulty"
    case bestOverallDiff = "Overall Difficulty"
    case uptime = "Uptime"
    case acceptedShares = "Accepted Shares"
    case rejectedShares = "Rejected Shares"
    case temperature = "Temperature"

    var id: String { self.rawValue }
}

// NEW: Sort Direction Enum
enum SortDirection: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"

    var id: String { self.rawValue }
}


// MARK: - FlexibleBool (Made Hashable)
enum FlexibleBool: Codable, Hashable {
    case bool(Bool)
    var value: Bool { switch self { case .bool(let b): return b } }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) { self = .bool(intValue != 0) }
        else if let boolValue = try? container.decode(Bool.self) { self = .bool(boolValue) }
        else { throw DecodingError.typeMismatch(FlexibleBool.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or Bool")) }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self { case .bool(let value): try container.encode(value) }
    }
}

// MARK: - Bitaxe Device Data Structure (Made Hashable and Equatable)
struct BitaxeDevice: Identifiable, Codable, Hashable, Equatable {
    var id: String { ip } // Use the IP address as the stable identifier
    var ip: String = "0.0.0.0"
    var hostname: String?
    var power: Double?
    var voltage: Double?
    var current: Double?
    var temp: Double?
    var vrTemp: Double?
    var maxPower: Double?
    var nominalVoltage: Double?
    var hashRate: Double?
    var bestDiff: String?
    var bestSessionDiff: String?
    var stratumDiff: Int?
    var isUsingFallbackStratum: FlexibleBool?
    var isPSRAMAvailable: Int?
    var freeHeap: Int?
    var coreVoltage: Int?
    var coreVoltageActual: Int?
    var frequency: Int?
    var ssid: String?
    var macAddr: String?
    var wifiStatus: String?
    var wifiRSSI: Int?
    var apEnabled: Int?
    var sharesAccepted: Int?
    var sharesRejected: Int?
    var sharesRejectedReasons: [RejectedReason]?
    var uptimeSeconds: Int?
    var asicCount: Int?
    var smallCoreCount: Int?
    var ASICModel: String?
    var stratumURL: String?
    var fallbackStratumURL: String?
    var stratumPort: Int?
    var fallbackStratumPort: Int?
    var stratumUser: String?
    var fallbackStratumUser: String?
    var version: String?
    var idfVersion: String?
    var boardVersion: String?
    var runningPartition: String?
    var flipscreen: Int?
    var overheat_mode: Int?
    var overclockEnabled: Int?
    var invertscreen: Int?
    var displayTimeout: Int?
    var autofanspeed: Int?
    var fanspeed: Int?
    var temptarget: Int?
    var fanrpm: Int?
    var deviceModel: String?
    var hostip: String?
    var minPower: Double?
    var maxVoltage: Double?
    var minVoltage: Double?
    var hashRateTimestamp: Double?
    var hashRate10m: Double?
    var hashRate1h: Double?
    var hashRate1d: Double?
    var defaultCoreVoltage: Int?
    var isStratumConnected: FlexibleBool?
    var pidTargetTemp: Int?
    var pidP: Double?
    var pidI: Double?
    var pidD: Double?
    var defaultFrequency: Int?
    var jobInterval: Int?
    var overheatTemp: Int?
    var autoscreenoff: Int?
    var invertfanpolarity: Int?
    var autofanpolarity: Int?
    var lastResetReason: String?
    var statsLimit: Int?
    var statsDuration: Int?

    // --- NEW: NerdQaxe Specific Properties (as placeholders) ---
    var nerdqaxe_version: String?
    var autoTune: Bool?
    var powerTune: Int?


    // This nested struct also needs to be Hashable
    struct RejectedReason: Codable, Hashable {
        let message: String
        let count: Int
    }

    // --- CORRECTED: Removed 'ip' from CodingKeys ---
    enum CodingKeys: String, CodingKey {
        case hostname, power, voltage, current, temp, vrTemp, maxPower, nominalVoltage, hashRate
        case bestDiff, bestSessionDiff, stratumDiff, isUsingFallbackStratum, isPSRAMAvailable, freeHeap
        case coreVoltage, coreVoltageActual, frequency, ssid, macAddr, wifiStatus, wifiRSSI, apEnabled
        case sharesAccepted, sharesRejected, sharesRejectedReasons, uptimeSeconds, asicCount, smallCoreCount
        case ASICModel, stratumURL, fallbackStratumURL, stratumPort, fallbackStratumPort, stratumUser
        case fallbackStratumUser, version, idfVersion, boardVersion, runningPartition, flipscreen
        case overheat_mode = "overheat_mode"
        case overclockEnabled, invertscreen, displayTimeout, autofanspeed, fanspeed, temptarget, fanrpm
        case deviceModel, hostip, minPower, maxVoltage, minVoltage, hashRateTimestamp
        case hashRate10m = "hashRate_10m"
        case hashRate1h = "hashRate_1h"
        case hashRate1d = "hashRate_1d"
        case defaultCoreVoltage, isStratumConnected, pidTargetTemp, pidP, pidI, pidD
        case defaultFrequency, jobInterval
        case overheatTemp = "overheat_temp"
        case autoscreenoff, invertfanpolarity, autofanpolarity, lastResetReason
        case statsLimit, statsDuration
        // --- NEW: Add NerdQaxe keys to coding keys ---
        case nerdqaxe_version, autoTune, powerTune
    }

    var formattedUptime: String {
        guard let totalSeconds = uptimeSeconds, totalSeconds >= 0 else { return "N/A" }
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }
    
    var temperatureValue: Double? { temp }
    var fanNumeric: Int? { fanspeed }
    var powerValue: Double? { power }
    var hashrateGHs: Double? {
        guard let hr = hashRate else { return nil }
        return hr / 1000.0
    }
    var hashrateDisplay: String {
        guard let ghs = hashrateGHs else { return "N/A" }
        return String(format: "%.2f GH/s", ghs)
    }
    var powerDisplay: String {
        guard let p = powerValue else { return "N/A"}
        return String(format: "%.1f W", p)
    }
    var tempDisplay: String {
        guard let t = temperatureValue else { return "N/A" }
        return String(format: "%.1f°C", t)
    }
    var fanDisplay: String {
        guard let f = fanNumeric else { return "N/A" }
        return "\(f)%"
    }
    
    // Equatable conformance
    static func == (lhs: BitaxeDevice, rhs: BitaxeDevice) -> Bool {
        return lhs.ip == rhs.ip &&
               lhs.hashRate == rhs.hashRate &&
               lhs.power == rhs.power &&
               lhs.temp == rhs.temp &&
               lhs.sharesAccepted == rhs.sharesAccepted &&
               lhs.sharesRejected == rhs.sharesRejected &&
               lhs.hostname == rhs.hostname
    }
}

//MARK: Mining Pool Setting
enum MiningMode: String, CaseIterable, Identifiable {
    case solo = "Solo"
    case pool = "Pool"
    var id: String { self.rawValue }
}

// MARK: - Bitcoin Network Information Structure (Made Codable)
struct BitcoinNetworkInfo: Codable {
    var btcPrice: Double?
    var satsPerUSD: Double?
    var blockHeight: Int?
    var networkDifficulty: Double?
    var networkHashrate: Double?
    var currency: String = "usd"

    init(btcPrice: Double? = nil, satsPerUSD: Double? = nil, blockHeight: Int? = nil, networkDifficulty: Double? = nil, networkHashrate: Double? = nil, currency: String = "usd") {
        self.btcPrice = btcPrice
        self.satsPerUSD = satsPerUSD
        self.blockHeight = blockHeight
        self.networkDifficulty = networkDifficulty
        self.networkHashrate = networkHashrate
        self.currency = currency
    }
}

// MARK: - Scan Mode Enumeration
enum ScanMode: String, CaseIterable, Identifiable {
    case ipList = "Device List"
    case subnetScan = "Network Scan"
    var id: String { self.rawValue }
}

// MARK: - Notification Names
extension Notification.Name {
    static let persistentIpListDidChange = Notification.Name("Playing.btc-home-mining-bitaxe.persistentIpListDidChange")
    static let deviceSortOptionDidChange = Notification.Name("Playing.btc-home-mining-bitaxe.deviceSortOptionDidChange")
    static let deviceSortDirectionDidChange = Notification.Name("Playing.btc-home-mining-bitaxe.deviceSortDirectionDidChange")
    static let currencyDidChange = Notification.Name("Playing.btc-home-mining-bitaxe.currencyDidChange")
}

// MARK: - Dashboard View Mode
enum DashboardViewMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case compact = "Compact"
    case grid = "Grid"

    var id: String { self.rawValue }
}
