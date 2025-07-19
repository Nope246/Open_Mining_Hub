// NetworkScanSettingsView.swift

import SwiftUI
import Foundation // Required for getifaddrs and related networking functions

struct NetworkScanSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - State for UI
    @AppStorage("networkScanModeIsLocal_v1") private var scanLocalNetwork: Bool = true
    
    // --- DEFAULT CHANGED ---
    @AppStorage("autoAddDevices_v1") private var autoAddDevices: Bool = true
    
    @State private var manualStartIP: String = ""
    @State private var manualEndIP: String = ""
    @State private var detectedSubnet: String = "N/A"
    
    // MARK: - State for Persistent IP List
    @State private var currentIpInput: String = ""
    @State private var ipListForEditing: [String] = []
    @AppStorage("targetIPs_v2_data") private var ipListStoreData: Data = Data()
    @FocusState private var isIpFieldFocused: Bool

    @State private var isManualStartIPValid: Bool = true
    @State private var isManualEndIPValid: Bool = true
    @State private var isCurrentIpInputValid: Bool = true

    // MARK: - Unified Toast State
    @State private var showUnifiedToast: Bool = false
    @State private var unifiedToastMessage: String?
    @State private var unifiedToastID: UUID = UUID()
    @State private var unifiedToastIsSuccess: Bool = true

    private let bitcoinOrangeToastColor = Color(hex: "#F7931A") ?? .orange

    var body: some View {
        ZStack(alignment: .bottom) {
            themeManager.colors.backgroundGradient.ignoresSafeArea()
            
            Form {
                // MARK: - Section 1: Network Scan Configuration
                Section(header: Text("Network Scan Method")) {
                    Toggle("Scan Local Network", isOn: $scanLocalNetwork)
                    
                    Toggle("Auto-add discovered devices", isOn: $autoAddDevices)
                        .tint(themeManager.colors.accent)
                    
                    if scanLocalNetwork {
                        HStack {
                            Text("Detected Subnet")
                            Spacer()
                            Text(detectedSubnet)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack {
                            TextField("Start IP Address (e.g., 192.168.1.1)", text: $manualStartIP)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(isManualStartIPValid ? Color.clear : Color.red, lineWidth: 1))
                                .onChange(of: manualStartIP) { _, newValue in
                                    isManualStartIPValid = newValue.isEmpty || isValidIPAddress(newValue)
                                }
                            
                            TextField("End IP Address (e.g., 192.168.1.254)", text: $manualEndIP)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(isManualEndIPValid ? Color.clear : Color.red, lineWidth: 1))
                                .onChange(of: manualEndIP) { _, newValue in
                                    isManualEndIPValid = newValue.isEmpty || isValidIPAddress(newValue)
                                }
                        }
                        .padding(.vertical, 4)
                        
                        Button("Save IP Range", action: saveManualRange)
                            .tint(themeManager.colors.accent)
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)

                // MARK: - Section 2: Device IP List
                Section(header: Text("Device IP List")) {
                    HStack {
                        TextField("Enter IP to add to list", text: $currentIpInput)
                            .keyboardType(.decimalPad)
                            .focused($isIpFieldFocused)
                            .onSubmit { addIpToListAndSave() }
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(isCurrentIpInputValid ? Color.clear : Color.red, lineWidth: 1))
                            .onChange(of: currentIpInput) { _, newValue in
                                isCurrentIpInputValid = newValue.isEmpty || isValidIPAddress(newValue)
                            }

                        Button("Add", action: addIpToListAndSave)
                            .buttonStyle(.bordered)
                            .tint(themeManager.colors.accent)
                            .disabled(currentIpInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if ipListForEditing.isEmpty {
                        Text("No IPs in list. Use this list to scan specific IPs regardless of the scan method chosen above.")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.caption)
                            .padding(.vertical)
                    } else {
                        List {
                            ForEach(ipListForEditing, id: \.self) { ip in
                                Text(ip)
                            }
                            .onDelete(perform: deleteIpFromListAndSave)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Network Scan Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isIpFieldFocused = false }
                        .tint(themeManager.colors.accent)
                }
            }
            .onAppear(perform: loadInitialData)
            .onChange(of: scanLocalNetwork) { _, isLocal in
                if isLocal {
                    updateForLocalScan()
                }
            }

            // Unified Toast Message Display
            if showUnifiedToast, let message = unifiedToastMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(unifiedToastIsSuccess ? bitcoinOrangeToastColor.opacity(0.90) : Color.red.opacity(0.90))
                    .foregroundColor(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                    .id(unifiedToastID)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 40)
                    .zIndex(1)
            }
        }
    }
    
    // MARK: - Methods
    private func loadInitialData() {
        if let decodedIPs = try? JSONDecoder().decode([String].self, from: ipListStoreData) {
            ipListForEditing = decodedIPs
        } else {
            ipListForEditing = []
        }
        
        if scanLocalNetwork {
            updateForLocalScan()
        } else {
            let start = AppStorage<Int>(wrappedValue: 1, "subnetScanRangeStart_v1").wrappedValue
            let end = AppStorage<Int>(wrappedValue: 254, "subnetScanRangeEnd_v1").wrappedValue
            let prefix = AppStorage<String>(wrappedValue: "192.168.1.", "subnetScanPrefix_v1").wrappedValue
            manualStartIP = "\(prefix)\(start)"
            manualEndIP = "\(prefix)\(end)"
        }
    }
    
    private func updateForLocalScan() {
        if let ip = getWiFiIPAddress(), let subnet = getSubnetPrefix(from: ip) {
            detectedSubnet = "\(subnet)1-254"
            AppStorage<String>(wrappedValue: "192.168.1.", "subnetScanPrefix_v1").wrappedValue = subnet
            AppStorage<Int>(wrappedValue: 1, "subnetScanRangeStart_v1").wrappedValue = 1
            AppStorage<Int>(wrappedValue: 254, "subnetScanRangeEnd_v1").wrappedValue = 254
        } else {
            detectedSubnet = "Wi-Fi not connected"
        }
    }
    
    private func saveManualRange() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        guard isValidIPAddress(manualStartIP) else {
            presentUnifiedToast(message: "Invalid Start IP address format.", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        guard isValidIPAddress(manualEndIP) else {
            presentUnifiedToast(message: "Invalid End IP address format.", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        
        guard let (prefix, start) = getPrefixAndLastOctet(from: manualStartIP),
              let (endPrefix, end) = getPrefixAndLastOctet(from: manualEndIP),
              prefix == endPrefix else {
            presentUnifiedToast(message: "Start and End IPs must be in the same subnet (e.g., 192.168.1.x).", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        
        guard start <= end else {
            presentUnifiedToast(message: "Start IP must be less than or equal to End IP.", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        
        AppStorage<String>(wrappedValue: "192.168.1.", "subnetScanPrefix_v1").wrappedValue = prefix
        AppStorage<Int>(wrappedValue: 1, "subnetScanRangeStart_v1").wrappedValue = start
        AppStorage<Int>(wrappedValue: 254, "subnetScanRangeEnd_v1").wrappedValue = end
        
        presentUnifiedToast(message: "IP Range saved!", isSuccess: true)
        haptic.impactOccurred()
    }
    
    private func presentUnifiedToast(message: String, isSuccess: Bool) {
        unifiedToastMessage = message
        unifiedToastIsSuccess = isSuccess
        unifiedToastID = UUID()
        withAnimation(.spring()) {
            showUnifiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showUnifiedToast = false
            }
        }
    }

    private func addIpToListAndSave() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        let trimmedIp = currentIpInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIp.isEmpty else {
            presentUnifiedToast(message: "IP cannot be empty.", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        guard isValidIPAddress(trimmedIp) else {
            presentUnifiedToast(message: "'\(trimmedIp)' is not a valid IP address.", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        guard !ipListForEditing.contains(where: { $0.caseInsensitiveCompare(trimmedIp) == .orderedSame }) else {
            presentUnifiedToast(message: "'\(trimmedIp)' is already in list.", isSuccess: false)
            currentIpInput = ""
            haptic.impactOccurred(intensity: 0.7)
            return
        }
        
        ipListForEditing.append(trimmedIp)
        ipListForEditing.sort()
        currentIpInput = ""
        
        if saveIpListToAppStorage() {
            presentUnifiedToast(message: "Added '\(trimmedIp)' to list.", isSuccess: true)
            haptic.impactOccurred()
        } else {
            presentUnifiedToast(message: "Failed to save '\(trimmedIp)'!", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
        }
        isIpFieldFocused = false
    }

    private func deleteIpFromListAndSave(at offsets: IndexSet) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        let originalListForRevert = ipListForEditing
        ipListForEditing.remove(atOffsets: offsets)
        if saveIpListToAppStorage() {
            presentUnifiedToast(message: "IP removed from list.", isSuccess: true)
            haptic.impactOccurred()
        } else {
            ipListForEditing = originalListForRevert
            presentUnifiedToast(message: "Failed to save removal!", isSuccess: false)
            haptic.impactOccurred(intensity: 0.7)
        }
    }
    
    @discardableResult
    private func saveIpListToAppStorage() -> Bool {
        if let encodedIPs = try? JSONEncoder().encode(ipListForEditing) {
            ipListStoreData = encodedIPs
            NotificationCenter.default.post(name: .persistentIpListDidChange, object: nil, userInfo: ["updatedIpList": ipListForEditing])
            return true
        }
        return false
    }
    
    private func isValidIPAddress(_ ipString: String) -> Bool {
        let octets = ipString.split(separator: ".")
        guard octets.count == 4 else { return false }

        for octetString in octets {
            if octetString.count > 1 && octetString.hasPrefix("0") {
                return false
            }
            guard let value = Int(octetString), (0...255).contains(value) else {
                return false
            }
        }
        return true
    }
    
    private func getPrefixAndLastOctet(from ip: String) -> (String, Int)? {
        let components = ip.split(separator: ".").map(String.init)
        guard components.count == 4, isValidIPAddress(ip),
              let lastOctet = Int(components[3]) else {
            return nil
        }
        let prefix = "\(components[0]).\(components[1]).\(components[2])."
        return (prefix, lastOctet)
    }

    private func getWiFiIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET), let name = interface.ifa_name, String(cString: name) == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

    private func getSubnetPrefix(from ip: String) -> String? {
        let components = ip.split(separator: ".")
        guard components.count == 4 else { return nil }
        return "\(components[0]).\(components[1]).\(components[2])."
    }
}
