// DashboardViewModel.swift

import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var devices: [BitaxeDevice] = []
    @Published var isLoading: Bool = false
    @Published var totalHashrate: Double = 0.0
    @Published var totalPower: Double = 0.0
    @Published var bitcoinInfo = BitcoinNetworkInfo()
    @Published var lastUpdated: Date?
    @Published var ipAddConfirmationMessage: String?
    @Published var overallBestSessionDiffDisplay: String = "N/A"
    @Published var overallBestDiffDisplay: String = "N/A"
    
    @Published var currentBitcoinFact: String = ""
    @Published var refreshingDeviceIPs: Set<String> = []
    @Published var currentPersistentIPs: [String] = []

    // MARK: - AppStorage Properties
    @AppStorage("scanMode_v2") var scanMode: ScanMode = .subnetScan
    @AppStorage("isCompactViewEnabled_v1") var isCompactViewEnabled: Bool = true
    @AppStorage("autoAddDevices_v1") private var autoAddDevices: Bool = true
    @AppStorage("refreshIntervalSeconds_v2") var refreshInterval: Double = 30.0
    @AppStorage("targetIPs_v2_data") private var ipListStoreData: Data = Data()
    @AppStorage("subnetScanPrefix_v1") var subnetPrefix: String = "192.168.1."
    @AppStorage("subnetScanRangeStart_v1") var subnetScanRangeStart: Int = 1
    @AppStorage("subnetScanRangeEnd_v1") var subnetScanRangeEnd: Int = 254
    @AppStorage("financialCurrency_v1") var selectedCurrency: String = "usd"
    
    // Sorting Preferences
    @AppStorage("deviceSortOption_v1") private var deviceSortOptionRawValue: String = DeviceSortOption.hostname.rawValue
    @AppStorage("deviceSortDirection_v1") private var deviceSortDirectionRawValue: String = SortDirection.ascending.rawValue

    private var currentSortOption: DeviceSortOption {
        DeviceSortOption(rawValue: deviceSortOptionRawValue) ?? .hostname
    }
    private var currentSortDirection: SortDirection {
        SortDirection(rawValue: deviceSortDirectionRawValue) ?? .ascending
    }

    // MARK: - Private Properties
    private var dataService = DataService()
    private var refreshTimer: Timer?
    private var confirmationMessageTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        self.currentPersistentIPs = (try? JSONDecoder().decode([String].self, from: ipListStoreData)) ?? []
        subscribeToIpListChanges()
        subscribeToSortOptionChanges()
        subscribeToSortDirectionChanges()
        subscribeToCurrencyChanges()
        
        self.currentBitcoinFact = BitcoinFacts.getRandomFact()
        
        self.loadBitcoinInfo()
        loadDeviceData()
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
        confirmationMessageTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Notification Subscriptions
    private func subscribeToCurrencyChanges() {
        NotificationCenter.default
            .publisher(for: .currencyDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBitcoinInfo()
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToIpListChanges() {
        NotificationCenter.default
            .publisher(for: .persistentIpListDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentPersistentIPs = (try? JSONDecoder().decode([String].self, from: self.ipListStoreData)) ?? []
                if self.scanMode == .ipList {
                    self.loadDeviceData()
                } else {
                     self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    private func subscribeToSortOptionChanges() {
        NotificationCenter.default
            .publisher(for: .deviceSortOptionDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.devices.isEmpty else { return }
                self.devices = self.sortDevices(self.devices)
                self.lastUpdated = Date()
            }
            .store(in: &cancellables)
    }

    private func subscribeToSortDirectionChanges() {
        NotificationCenter.default
            .publisher(for: .deviceSortDirectionDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.devices.isEmpty else { return }
                self.devices = self.sortDevices(self.devices)
                self.lastUpdated = Date()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading and Refreshing
    
    /// Refreshes the data for a single, specific device without clearing the main list.
    func refreshDevice(withIP ip: String) async {
        refreshingDeviceIPs.insert(ip)
        defer { refreshingDeviceIPs.remove(ip) }

        guard let index = devices.firstIndex(where: { $0.ip == ip }) else {
            print("[DashboardViewModel] Could not find device with IP \(ip) to refresh.")
            return
        }
        
        if let updatedDevice = await dataService.fetchDeviceInfo(ip: ip) {
            devices[index] = updatedDevice
            lastUpdated = Date()
        } else {
            print("[DashboardViewModel] Failed to refresh device at IP \(ip). It might be offline.")
        }
    }

    func loadDeviceData(withForcedIpList forcedList: [String]? = nil) {
        isLoading = true
        currentBitcoinFact = BitcoinFacts.getRandomFact()
        
        let ipsToScan = self.scanMode == .ipList ? (forcedList ?? currentPersistentIPs) : generateSubnetIPs()
        
        Task {
            if ipsToScan.isEmpty {
                if self.scanMode == .ipList {
                    self.devices.removeAll()
                }
                self.isLoading = false
                self.lastUpdated = Date()
                return
            }

            let discoveredDevices = await dataService.scanForDevices(ips: ipsToScan)
            
            if self.scanMode == .subnetScan && self.autoAddDevices {
                let discoveredIPs = discoveredDevices.map { $0.ip }
                let newIPsToAdd = discoveredIPs.filter { !self.currentPersistentIPs.contains($0) }

                if !newIPsToAdd.isEmpty {
                    var updatedIPs = self.currentPersistentIPs
                    updatedIPs.append(contentsOf: newIPsToAdd)
                    
                    if let encodedIPs = try? JSONEncoder().encode(updatedIPs) {
                        self.ipListStoreData = encodedIPs
                        NotificationCenter.default.post(name: .persistentIpListDidChange, object: nil)
                        self.showConfirmationMessage("Auto-added \(newIPsToAdd.count) new device(s).")
                    }
                }
            }
            
            var newDeviceList = self.devices
            let discoveredIPsSet = Set(discoveredDevices.map { $0.ip })

            // Remove devices that were scanned but are no longer found
            newDeviceList.removeAll { device in
                return ipsToScan.contains(device.ip) && !discoveredIPsSet.contains(device.ip)
            }
            
            // Update existing devices and add new ones
            for device in discoveredDevices {
                if let index = newDeviceList.firstIndex(where: { $0.ip == device.ip }) {
                    newDeviceList[index] = device // Update
                } else {
                    newDeviceList.append(device) // Add new
                }
            }
            
            self.devices = self.sortDevices(newDeviceList)
            self.calculateTotals()
            self.isLoading = false
            self.lastUpdated = Date()
        }
    }
    
    // MARK: - Sorting Logic
    private func sortDevices(_ devicesToSort: [BitaxeDevice]) -> [BitaxeDevice] {
        let sortOption = self.currentSortOption
        let direction = self.currentSortDirection

        return devicesToSort.sorted { d1, d2 in
            func compareOptionals<T: Comparable>(_ val1: T?, _ val2: T?) -> Bool {
                if direction == .ascending {
                    if val1 == nil { return false }
                    if val2 == nil { return true }
                    return val1! < val2!
                } else {
                    if val1 == nil { return true }
                    if val2 == nil { return false }
                    return val1! > val2!
                }
            }
            
            switch sortOption {
            case .hostname:
                let name1 = d1.hostname ?? d1.ip
                let name2 = d2.hostname ?? d2.ip
                return direction == .ascending ? (name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending) : (name1.localizedCaseInsensitiveCompare(name2) == .orderedDescending)
            case .currentHashRate: return compareOptionals(d1.hashRate, d2.hashRate)
            case .wattage: return compareOptionals(d1.power, d2.power)
            case .bestSessionDiff: return compareOptionals(DifficultyConverter.toDouble(difficultyString: d1.bestSessionDiff), DifficultyConverter.toDouble(difficultyString: d2.bestSessionDiff))
            case .bestOverallDiff: return compareOptionals(DifficultyConverter.toDouble(difficultyString: d1.bestDiff), DifficultyConverter.toDouble(difficultyString: d2.bestDiff))
            case .uptime: return compareOptionals(d1.uptimeSeconds, d2.uptimeSeconds)
            case .acceptedShares: return compareOptionals(d1.sharesAccepted, d2.sharesAccepted)
            case .rejectedShares: return compareOptionals(d1.sharesRejected, d2.sharesRejected)
            case .temperature: return compareOptionals(d1.temp, d2.temp)
            }
        }
    }
    
    // MARK: - Helper Methods
    func isIpInPersistentList(ip: String) -> Bool {
        return currentPersistentIPs.contains(ip)
    }

    func loadBitcoinInfo() {
        Task {
            self.bitcoinInfo = await dataService.fetchBitcoinInfo(currency: selectedCurrency)
        }
    }

    func restartDevice(_ device: BitaxeDevice) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        Task {
            let success = await dataService.restartDevice(ip: device.ip)
            showConfirmationMessage(success ? "Restart command sent to \(device.hostname ?? device.ip)." : "Failed to send restart to \(device.hostname ?? device.ip).")
            haptic.impactOccurred(intensity: success ? 1.0 : 0.7)
        }
    }

    func calculateTotals() {
        totalHashrate = devices.reduce(0.0) { $0 + ($1.hashRate ?? 0.0) }
        totalPower = devices.reduce(0.0) { $0 + ($1.powerValue ?? 0.0) }
        
        var maxSessionDiff: Double = -1
        var maxOverallDiff: Double = -1
        overallBestSessionDiffDisplay = "N/A"
        overallBestDiffDisplay = "N/A"

        for device in devices {
            if let sds = device.bestSessionDiff, let sdn = DifficultyConverter.toDouble(difficultyString: sds), sdn > maxSessionDiff {
                maxSessionDiff = sdn
                overallBestSessionDiffDisplay = sds
            }
            if let ods = device.bestDiff, let odn = DifficultyConverter.toDouble(difficultyString: ods), odn > maxOverallDiff {
                maxOverallDiff = odn
                overallBestDiffDisplay = ods
            }
        }
    }

    func addIpToPersistentList(_ ipToAdd: String) {
        var currentStoredIPs = self.currentPersistentIPs
        if !currentStoredIPs.contains(ipToAdd) {
            currentStoredIPs.append(ipToAdd)
            if let encodedIPs = try? JSONEncoder().encode(currentStoredIPs) {
                self.ipListStoreData = encodedIPs
                NotificationCenter.default.post(name: .persistentIpListDidChange, object: nil)
                showConfirmationMessage("\(ipToAdd) added to IP list.")
            }
        }
    }
    
    func removeIpFromPersistentList(_ ipToRemove: String) {
        var currentStoredIPs = self.currentPersistentIPs
        let originalCount = currentStoredIPs.count
        currentStoredIPs.removeAll(where: { $0 == ipToRemove })
        
        if currentStoredIPs.count < originalCount {
            if let encodedIPs = try? JSONEncoder().encode(currentStoredIPs) {
                self.ipListStoreData = encodedIPs
                NotificationCenter.default.post(name: .persistentIpListDidChange, object: nil)
                showConfirmationMessage("\(ipToRemove) removed from IP list.")
            }
        }
    }
    
    private func showConfirmationMessage(_ message: String) {
        self.ipAddConfirmationMessage = message
        confirmationMessageTimer?.invalidate()
        confirmationMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.ipAddConfirmationMessage = nil
            }
        }
    }

    func setupAutoRefresh() {
        refreshTimer?.invalidate()
        guard refreshInterval > 0 else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.loadDeviceData()
                await self?.loadBitcoinInfo()
            }
        }
    }

    func updateRefreshInterval(newInterval: Double) {
        refreshInterval = newInterval
        setupAutoRefresh()
    }

    private func generateSubnetIPs() -> [String] {
        let prefix = subnetPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefix.isEmpty else { return [] }
        let finalPrefix = prefix.hasSuffix(".") ? prefix : prefix + "."
        return (subnetScanRangeStart...subnetScanRangeEnd).map { "\(finalPrefix)\($0)" }
    }
}
