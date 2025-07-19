// DeviceEditView.swift

import SwiftUI
import UniformTypeIdentifiers

struct DeviceEditView: View {
    
    enum ExpandableSection {
        case system, statistics, performance, fan, pool, ota
    }
    
    let device: BitaxeDevice
    private let initialExpandedSection: ExpandableSection?
    
    init(device: BitaxeDevice, initialExpandedSection: ExpandableSection? = nil) {
        self.device = device
        self.initialExpandedSection = initialExpandedSection
        _selectedFrequency = State(initialValue: device.frequency ?? 0)
        _selectedVoltage = State(initialValue: device.coreVoltage ?? 0)
    }
    
    @EnvironmentObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var otaViewModel = OtaUpdateViewModel()
    @StateObject private var dataService = DataService()
    
    // MARK: - State for Form Fields
    @State private var hostname: String = ""
    
    @State private var stratumURL: String = ""
    @State private var stratumPort: String = ""
    @State private var stratumUser: String = ""
    @State private var stratumPassword: String = ""
    
    @State private var fallbackStratumURL: String = ""
    @State private var fallbackStratumPort: String = ""
    @State private var fallbackStratumUser: String = ""
    @State private var fallbackStratumPassword: String = ""
    
    // --- Fan Control State ---
    @State private var autoFanSpeed: Bool = true
    @State private var manualFanSpeed: Double = 50.0
    @State private var targetTemp: String = ""
    @State private var overheatModeEnabled: Bool = true
    
    // --- Performance State ---
    @State private var asicInfo: AsicInfo?
    @State private var selectedFrequency: Int
    @State private var selectedVoltage: Int
    
    // --- Statistics State ---
    @State private var statsLimit: Int = 60

    // --- NerdQaxe Specific State ---
    @State private var powerTune: Double = 0.0
    @State private var autoTuneEnabled: Bool = false
    @State private var isSavingNerdQaxe: Bool = false
    @State private var nerdQaxeSaveStatus: String?
    @State private var nerdQaxeSaveSucceeded: Bool?

    // MARK: - State for Save Actions
    @State private var isSavingPool: Bool = false
    @State private var poolSaveStatus: String?
    @State private var poolSaveSucceeded: Bool?
    
    @State private var isSavingSystem: Bool = false
    @State private var systemSaveStatus: String?
    @State private var systemSaveSucceeded: Bool?
    
    @State private var isSavingFan: Bool = false
    @State private var fanSaveStatus: String?
    @State private var fanSaveSucceeded: Bool?

    @State private var isSavingPerformance: Bool = false
    @State private var performanceSaveStatus: String?
    @State private var performanceSaveSucceeded: Bool?
    
    @State private var isSavingStats: Bool = false
    @State private var statsSaveStatus: String?
    @State private var statsSaveSucceeded: Bool?

    @State private var showRestartAlert = false
    @State private var restartMessage = ""
    
    // --- State for DisclosureGroups ---
    @State private var isSystemExpanded: Bool = false
    @State private var isStatsExpanded: Bool = false
    @State private var isPerformanceExpanded: Bool = false
    @State private var isFanControlExpanded: Bool = false
    @State private var isMiningPoolExpanded: Bool = false
    @State private var isOtaExpanded: Bool = false
    
    // --- Picker Options ---
    private let limitOptions = stride(from: 60, through: 720, by: 60).map { $0 }

    var body: some View {
        ZStack {
            themeManager.colors.backgroundGradient.ignoresSafeArea()
            
            Form {
                // All other sections remain the same
                
                // --- System Settings Section ---
                Section {
                    DisclosureGroup("System Settings", isExpanded: $isSystemExpanded) {
                        HStack {
                            Text("Hostname")
                            Spacer()
                            TextField("Device Hostname", text: $hostname)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Button("Save System Settings") { saveSystemSettings() }
                                .tint(themeManager.colors.accent)
                            if isSavingSystem { ProgressView().padding(.leading, 10) }
                        }
                        
                        if let status = systemSaveStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(systemSaveSucceeded == true ? .green : .red)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                .disabled(isSavingSystem)
                
                // --- Statistics Settings Section ---
                Section {
                    DisclosureGroup("Statistics Settings", isExpanded: $isStatsExpanded) {
                        Picker("Data Point Limit", selection: $statsLimit) {
                            ForEach(limitOptions, id: \.self) { limit in
                                Text("\(limit)").tag(limit)
                            }
                        }

                        HStack {
                            Button("Save Statistics Settings") { saveStatisticsSettings() }
                                .tint(themeManager.colors.accent)
                            if isSavingStats { ProgressView().padding(.leading, 10) }
                        }

                        if let status = statsSaveStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(statsSaveSucceeded == true ? .green : .red)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                .disabled(isSavingStats)
                
                // --- Performance / Overclocking Section ---
                Section {
                    DisclosureGroup("Performance / Overclocking", isExpanded: $isPerformanceExpanded) {
                        if let info = asicInfo {
                            VStack(alignment: .leading, spacing: 4) {
                                Picker("Core Voltage", selection: $selectedVoltage) {
                                    ForEach(info.voltageOptions ?? [], id: \.self) { voltage in
                                        let isDefault = (voltage == info.defaultVoltage)
                                        Text("\(voltage) mV\(isDefault ? " (D)" : "")").tag(voltage)
                                    }
                                }
                                if let currentVoltage = device.coreVoltageActual {
                                    Text("Current: \(currentVoltage) mV").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Picker("Frequency", selection: $selectedFrequency) {
                                    ForEach(info.frequencyOptions ?? [], id: \.self) { frequency in
                                        let isDefault = (frequency == info.defaultFrequency)
                                        Text("\(frequency) MHz\(isDefault ? " (D)" : "")").tag(frequency)
                                    }
                                }
                                if let currentFrequency = device.frequency {
                                    Text("Current: \(currentFrequency) MHz").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Toggle("Overheat Protection", isOn: $overheatModeEnabled)
                            HStack {
                                Button("Save Performance Settings") { savePerformanceSettings() }
                                    .tint(themeManager.colors.accent)
                                if isSavingPerformance { ProgressView().padding(.leading, 10) }
                            }
                            if let status = performanceSaveStatus {
                                Text(status).font(.caption).foregroundColor(performanceSaveSucceeded == true ? .green : .red)
                            }
                        } else {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Loading performance options...").foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                .disabled(isSavingPerformance)

                // --- NerdQaxe Performance Section ---
                if device.deviceModel?.lowercased().contains("nerdqaxe") == true {
                    Section(header: Text("NerdQaxe Performance")) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Power Tune (Watts)")
                                Spacer()
                                TextField("e.g., 5", value: $powerTune, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                            Text("Set target power consumption. Set to 0 to disable.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Toggle("Auto Tune", isOn: $autoTuneEnabled)

                        HStack {
                            Button("Save NerdQaxe Settings") { saveNerdQaxeSettings() }
                                .tint(themeManager.colors.accent)
                            if isSavingNerdQaxe { ProgressView().padding(.leading, 10) }
                        }

                        if let status = nerdQaxeSaveStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(nerdQaxeSaveSucceeded == true ? .green : .red)
                        }
                    }
                    .listRowBackground(themeManager.colors.cardBackground)
                    .foregroundColor(themeManager.colors.primaryText)
                    .disabled(isSavingNerdQaxe)
                }
                
                // --- Fan Control Section ---
                Section {
                    DisclosureGroup("Fan Control", isExpanded: $isFanControlExpanded) {
                        Toggle("Automatic Fan Speed", isOn: $autoFanSpeed)
                        
                        if autoFanSpeed {
                            HStack {
                                Text("Target Temperature (°C)")
                                Spacer()
                                TextField("e.g. 65", text: $targetTemp)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        } else {
                            VStack {
                                HStack {
                                    Text("Manual Speed")
                                    Spacer()
                                    Text("\(Int(manualFanSpeed))%")
                                }
                                Slider(value: $manualFanSpeed, in: 0...100, step: 1)
                            }
                        }
                        
                        HStack {
                            Button("Save Fan Settings") { saveFanSettings() }
                                .tint(themeManager.colors.accent)
                            if isSavingFan { ProgressView().padding(.leading, 10) }
                        }
                        
                        if let status = fanSaveStatus {
                            Text(status).font(.caption).foregroundColor(fanSaveSucceeded == true ? .green : .red)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                .disabled(isSavingFan)
                
                // --- Mining Pool Configuration Section ---
                Section {
                    DisclosureGroup("Mining Pool Configuration", isExpanded: $isMiningPoolExpanded) {
                        TextField("Primary Pool URL", text: $stratumURL).autocapitalization(.none).disableAutocorrection(true)
                        TextField("Primary Pool Port", text: $stratumPort).keyboardType(.numberPad)
                        TextField("Primary Worker Name", text: $stratumUser).autocapitalization(.none).disableAutocorrection(true)
                        SecureField("Primary Password", text: $stratumPassword)
                        
                        Divider().padding(.vertical, 5)

                        TextField("Fallback Pool URL", text: $fallbackStratumURL).autocapitalization(.none).disableAutocorrection(true)
                        TextField("Fallback Pool Port", text: $fallbackStratumPort).keyboardType(.numberPad)
                        TextField("Fallback Worker Name", text: $fallbackStratumUser).autocapitalization(.none).disableAutocorrection(true)
                        SecureField("Fallback Password", text: $fallbackStratumPassword)

                        HStack {
                            Button("Save Pool Settings") { savePoolSettings() }.tint(themeManager.colors.accent)
                            if isSavingPool { ProgressView().padding(.leading, 10) }
                        }
                        
                        if let status = poolSaveStatus {
                            Text(status).font(.caption).foregroundColor(poolSaveSucceeded == true ? .green : .red)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                .disabled(isSavingPool)
                
                // --- OTA Update Section ---
               //
                Section {
                    DisclosureGroup("Over-the-Air (OTA) Updates (Alpha- Use at your own risk! Only tested on Bitaxe 601)", isExpanded: $isOtaExpanded) {
                        Button { otaViewModel.selectFile(for: .firmware, deviceIP: device.ip) } label: { Label("Update Firmware (.bin)", systemImage: "cpu") }
                        Button { otaViewModel.selectFile(for: .webInterface, deviceIP: device.ip) } label: { Label("Update Web Interface (www.bin)", systemImage: "globe") }

                        if otaViewModel.isUpdating {
                            VStack(alignment: .leading, spacing: 5) {
                                ProgressView(value: otaViewModel.uploadProgress).tint(themeManager.colors.accent)
                                Text(otaViewModel.updateStatusMessage ?? "Updating...").font(.caption).foregroundColor(.secondary)
                            }
                        } else if let status = otaViewModel.updateStatusMessage {
                            Text(status).font(.caption).foregroundColor(otaViewModel.updateSucceeded == false ? .red : .green)
                        }
                    }
                }
                
                .listRowBackground(themeManager.colors.cardBackground)
                .disabled(otaViewModel.isUpdating)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit \(device.hostname ?? "Device")")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(isPresented: $otaViewModel.isFilePickerPresented, allowedContentTypes: [UTType.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { otaViewModel.performUpdate(with: url) }
                case .failure(let error):
                    otaViewModel.updateStatusMessage = "Failed to select file: \(error.localizedDescription)"
                }
            }
            .onAppear {
                populateFields()
                fetchAsicOptions()
                if let section = initialExpandedSection {
                    switch section {
                    case .system: isSystemExpanded = true
                    case .statistics: isStatsExpanded = true
                    case .performance: isPerformanceExpanded = true
                    case .fan: isFanControlExpanded = true
                    case .pool: isMiningPoolExpanded = true
                    case .ota: isOtaExpanded = true
                    }
                } else {
                    isSystemExpanded = true
                }
            }
            .alert("Restart Required", isPresented: $showRestartAlert) {
                Button("Restart Now") { viewModel.restartDevice(device) }
                Button("Later", role: .cancel) {}
            } message: { Text(restartMessage) }
        }
    }
    
    private func fetchAsicOptions() {
        Task {
            self.asicInfo = await dataService.fetchAsicInfo(ip: device.ip)
            
            if let info = self.asicInfo {
                selectedFrequency = device.frequency ?? info.defaultFrequency ?? 0
                selectedVoltage = device.coreVoltage ?? info.defaultVoltage ?? 0
            } else {
                selectedFrequency = device.frequency ?? 0
                selectedVoltage = device.coreVoltage ?? 0
            }
        }
    }
    
    private func populateFields() {
        hostname = device.hostname ?? ""
        stratumURL = device.stratumURL ?? ""
        stratumPort = device.stratumPort.map(String.init) ?? ""
        stratumUser = device.stratumUser ?? ""
        fallbackStratumURL = device.fallbackStratumURL ?? ""
        fallbackStratumPort = device.fallbackStratumPort.map(String.init) ?? ""
        fallbackStratumUser = device.fallbackStratumUser ?? ""
        autoFanSpeed = (device.autofanspeed ?? 1) != 0
        manualFanSpeed = Double(device.fanspeed ?? 50)
        targetTemp = device.temptarget.map(String.init) ?? ""
        overheatModeEnabled = (device.overheat_mode ?? 1) != 0
        statsLimit = device.statsLimit ?? 60
        
        // --- Populate NerdQaxe fields ---
        powerTune = Double(device.powerTune ?? 0)
        autoTuneEnabled = device.autoTune ?? false
    }
    
    private func saveSystemSettings() {
        isSavingSystem = true
        systemSaveStatus = "Saving..."
        systemSaveSucceeded = nil
        let settings = SystemSettings(hostname: self.hostname.nilIfEmpty())
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingSystem = false
                handleSaveResult(result, status: &systemSaveStatus, success: &systemSaveSucceeded, restartMessage: "The hostname change requires a restart to be applied.")
            }
        }
    }
    
    private func saveFanSettings() {
        isSavingFan = true
        fanSaveStatus = "Saving..."
        fanSaveSucceeded = nil
        let settings = SystemSettings(autofanspeed: autoFanSpeed, fanspeed: autoFanSpeed ? nil : Int(manualFanSpeed), temptarget: autoFanSpeed ? Int(targetTemp) : nil)
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingFan = false
                handleSaveResult(result, status: &fanSaveStatus, success: &fanSaveSucceeded)
            }
        }
    }
    
    private func savePerformanceSettings() {
        isSavingPerformance = true
        performanceSaveStatus = "Saving..."
        performanceSaveSucceeded = nil
        let settings = SystemSettings(overheat_mode: overheatModeEnabled ? 1 : 0, frequency: selectedFrequency, coreVoltage: selectedVoltage)
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingPerformance = false
                handleSaveResult(result, status: &performanceSaveStatus, success: &performanceSaveSucceeded, restartMessage: "Performance settings have been updated. The device must be restarted for the changes to apply.")
            }
        }
    }
    
    private func saveStatisticsSettings() {
        isSavingStats = true
        statsSaveStatus = "Saving..."
        statsSaveSucceeded = nil
        let settings = SystemSettings(statsLimit: statsLimit)
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingStats = false
                handleSaveResult(result, status: &statsSaveStatus, success: &statsSaveSucceeded, restartMessage: "Statistics settings have been updated. The device must be restarted for changes to take effect.")
            }
        }
    }

    private func savePoolSettings() {
        isSavingPool = true
        poolSaveStatus = "Saving..."
        poolSaveSucceeded = nil
        let settings = SystemSettings(
            stratumURL: self.stratumURL.nilIfEmpty(),
            stratumPort: Int(self.stratumPort),
            stratumUser: self.stratumUser.nilIfEmpty(),
            stratumPassword: self.stratumPassword.nilIfEmpty(),
            fallbackStratumURL: self.fallbackStratumURL.nilIfEmpty(),
            fallbackStratumPort: Int(self.fallbackStratumPort),
            fallbackStratumUser: self.fallbackStratumUser.nilIfEmpty(),
            fallbackStratumPassword: self.fallbackStratumPassword.nilIfEmpty()
        )
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingPool = false
                handleSaveResult(result, status: &poolSaveStatus, success: &poolSaveSucceeded, restartMessage: "Pool settings have been updated. The device must be restarted for changes to take effect.")
            }
        }
    }

    // --- Save function for NerdQaxe specific settings ---
    private func saveNerdQaxeSettings() {
        isSavingNerdQaxe = true
        nerdQaxeSaveStatus = "Saving..."
        nerdQaxeSaveSucceeded = nil
        
        let settings = SystemSettings(autoTune: autoTuneEnabled, powerTune: Int(powerTune))
        
        updateDeviceSettings(deviceIP: device.ip, settings: settings) { result in
            DispatchQueue.main.async {
                isSavingNerdQaxe = false
                handleSaveResult(result, status: &nerdQaxeSaveStatus, success: &nerdQaxeSaveSucceeded, restartMessage: "NerdQaxe settings have been updated. A restart may be required.")
            }
        }
    }
    
    private func handleSaveResult(_ result: Result<Bool, ConfigUpdateError>, status: inout String?, success: inout Bool?, restartMessage: String? = nil) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        switch result {
        case .success:
            success = true
            status = "Settings saved successfully!"
            haptic.impactOccurred()
            
            // Refresh the device data in the background after a successful save.
            Task {
                await viewModel.refreshDevice(withIP: device.ip)
            }

            if let msg = restartMessage {
                self.restartMessage = msg
                self.showRestartAlert = true
            }
        case .failure(let error):
            success = false
            status = "Error: \(error.localizedDescription)"
            haptic.impactOccurred(intensity: 0.7)
        }
    }
}

// Helper to convert empty strings to nil for cleaner JSON
extension String {
    func nilIfEmpty() -> String? {
        self.isEmpty ? nil : self
    }
}
