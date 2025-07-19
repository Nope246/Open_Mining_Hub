// DataService.swift

import Foundation

@MainActor
class DataService: ObservableObject {
    private let networkScanner = NetworkScanner()
    private let btcInfoFetcher = BitcoinInfoFetcher()

    func scanForDevices(ips: [String]) async -> [BitaxeDevice] {
        await networkScanner.scanForDevices(ips: ips)
    }

    func fetchDeviceInfo(ip: String) async -> BitaxeDevice? {
        await networkScanner.fetchDeviceInfo(ip: ip)
    }

    func fetchAsicInfo(ip: String) async -> AsicInfo? {
        await networkScanner.fetchAsicInfo(ip: ip)
    }

    func fetchDeviceStatistics(ip: String) async -> DeviceStatisticsResponse? {
        await networkScanner.fetchDeviceStatistics(ip: ip)
    }

    func restartDevice(ip: String) async -> Bool {
        await networkScanner.restartDevice(ip: ip)
    }

    func fetchBitcoinInfo(currency: String) async -> BitcoinNetworkInfo {
        await btcInfoFetcher.fetchInfo(currency: currency)
    }
}
