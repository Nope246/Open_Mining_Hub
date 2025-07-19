// DashboardView.swift

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var listRefreshID = UUID()
    @State private var showingTotalStats = false
    
    @State private var showingNetworkSettings = false
    @AppStorage("dashboardViewMode_v1") private var dashboardViewMode: DashboardViewMode = .compact

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    DashboardControlsView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .background(themeManager.colors.groupedBackground.opacity(0.5))

                    if viewModel.isLoading && viewModel.devices.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView("Scanning for devices...")
                            
                            Text(viewModel.currentBitcoinFact)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(themeManager.colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .transition(.opacity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.devices.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Text("No Devices Found")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Text("Check your scan mode or add devices to your IP list in settings.")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                showingNetworkSettings = true
                            } label: {
                                Label("Configure Scan Settings", systemImage: "wifi.router")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(themeManager.colors.accent)
                            .padding(.top)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        switch dashboardViewMode {
                        case .grid:
                            SuperCompactGridView(devices: viewModel.devices, viewModel: viewModel)
                                .padding(.horizontal)
                        case .normal, .compact:
                            List {
                                ForEach(viewModel.devices) { device in
                                    NavigationLink(destination: DeviceDetailView(deviceIP: device.ip)) {
                                        DashboardDeviceRow(device: device, viewModel: viewModel, isCompact: dashboardViewMode == .compact)
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .listStyle(PlainListStyle())
                            .refreshable {
                                viewModel.loadDeviceData()
                                viewModel.loadBitcoinInfo()
                            }
                            .id(listRefreshID)
                        }
                    }

                    DashboardFooterView(viewModel: viewModel, onInfoButtonTapped: {
                        self.showingTotalStats = true
                    })
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(themeManager.colors.groupedBackground.opacity(0.5))
                }

                if let message = viewModel.ipAddConfirmationMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(themeManager.colors.accent.opacity(0.90))
                        .foregroundColor(Color.white)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring(), value: viewModel.ipAddConfirmationMessage)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Open Mining Hub")
            .onReceive(viewModel.$lastUpdated) { _ in
                self.listRefreshID = UUID()
            }
            .sheet(isPresented: $showingTotalStats) {
                TotalMiningStatsView(viewModel: self.viewModel)
            }
            .sheet(isPresented: $showingNetworkSettings) {
                NavigationView {
                    NetworkScanSettingsView()
                        .environmentObject(themeManager)
                }
            }
        }
    }
}


// MARK: - Helper Views

struct DashboardDeviceRow: View {
    let device: BitaxeDevice
    @ObservedObject var viewModel: DashboardViewModel
    let isCompact: Bool

    var body: some View {
        DeviceRowView(device: device, viewModel: viewModel, isCompact: isCompact)
            .equatable() // This modifier prevents unnecessary re-renders
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if viewModel.scanMode == .subnetScan {
                    if viewModel.isIpInPersistentList(ip: device.ip) {
                        Button(role: .destructive) {
                            viewModel.removeIpFromPersistentList(device.ip)
                        } label: {
                            Label("Remove from List", systemImage: "trash.circle")
                        }
                    } else {
                        Button {
                            viewModel.addIpToPersistentList(device.ip)
                        } label: {
                            Label("Add to List", systemImage: "plus.circle.fill")
                        }
                        .tint(.green)
                    }
                } else {
                    Button(role: .destructive) {
                        viewModel.removeIpFromPersistentList(device.ip)
                    } label: {
                        Label("Remove from List", systemImage: "trash.circle")
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    viewModel.restartDevice(device)
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise.circle.fill")
                }
                .tint(.orange)
            }
    }
}

struct DashboardControlsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    viewModel.loadDeviceData()
                    viewModel.loadBitcoinInfo()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(themeManager.colors.accent)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.leading, 5)
                }

                Spacer()

                NavigationLink(destination: SupportedDevicesView()) {
                    Label("Supported Devices", systemImage: "")
                }
                .buttonStyle(.bordered)
                .tint(themeManager.colors.accent)

                Picker("Interval:", selection: $viewModel.refreshInterval) {
                    Text("5s").tag(5.0)
                    Text("10s").tag(10.0)
                    Text("15s").tag(15.0)
                    Text("30s").tag(30.0)
                    Text("60s").tag(60.0)
                    Text("Off").tag(0.0)
                }
                .pickerStyle(MenuPickerStyle())
                .tint(themeManager.colors.accent)
                .onChange(of: viewModel.refreshInterval) { _, newValue in
                    viewModel.updateRefreshInterval(newInterval: newValue)
                }
            }

            Picker("Scan Mode:", selection: $viewModel.scanMode) {
                ForEach(ScanMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.scanMode) { _, _ in
                viewModel.loadDeviceData()
            }

            if !(viewModel.isLoading && viewModel.devices.isEmpty) {
                Text("\(viewModel.devices.count) device\(viewModel.devices.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 5)
    }
}


struct DeviceRowView: View, Equatable {
    let device: BitaxeDevice
    @ObservedObject var viewModel: DashboardViewModel
    let isCompact: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hostnameColorManager: HostnameColorManager

    @State private var flashRed: Bool = false

    private var isHashrateZero: Bool {
        (device.hashRate ?? 0) == 0
    }
    
    private var rowBackground: Color {
        if viewModel.isIpInPersistentList(ip: device.ip) {
            return themeManager.colors.positiveHighlight
        } else {
            return themeManager.colors.neutralHighlight
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 3 : 6) {
            HStack {
                Text(device.hostname ?? "Unknown Host")
                    .font(isCompact ? .subheadline : .headline)
                    .lineLimit(1)
                    .foregroundColor(hostnameColor(device.hostname))
                Spacer()
                if let ipURL = URL(string: "http://\(device.ip)") {
                    Link(device.ip, destination: ipURL)
                        .font(isCompact ? .caption : .subheadline)
                        .foregroundColor(themeManager.colors.accent)
                } else {
                    Text(device.ip)
                        .font(isCompact ? .caption : .subheadline)
                        .foregroundColor(themeManager.colors.accent)
                }
            }

            if isCompact {
                Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
                    GridRow {
                        SmallStatView(label: "Hash", value: device.hashrateDisplay)
                        SmallStatView(label: "Temp", value: device.tempDisplay, isWarning: (device.temp ?? 0.0) > 75.0)
                        SmallStatView(label: "Pwr", value: device.powerDisplay)
                        SmallStatView(label: "Fan", value: (device.fanspeed ?? 0) > 0 ? device.fanDisplay : "Off", isWarning: (device.fanspeed ?? 0) > 90)
                        SmallStatView(label: "Up", value: device.formattedUptime)
                    }
                    GridRow {
                        SmallStatView(label: "A/R", value: "\(device.sharesAccepted ?? 0)/\(device.sharesRejected ?? 0)")
                        SmallStatView(label: "Diff", value: "S:\(device.bestSessionDiff ?? "N/A")/B:\(device.bestDiff ?? "N/A")")
                            .gridCellColumns(2)
                        SmallStatView(label: "ASIC", value: device.ASICModel ?? "N/A")
                        SmallStatView(label: "Ver", value: device.version ?? "N/A")
                    }
                }
                .font(.caption2)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                    StatView(label: "Hashrate", value: device.hashrateDisplay)
                    StatView(label: "Temp", value: device.tempDisplay, isWarning: (device.temp ?? 0.0) > 75.0)
                    StatView(label: "Power", value: device.powerDisplay)
                    StatView(label: "Fan", value: device.fanDisplay, isWarning: (device.fanspeed ?? 0) > 90 && (device.fanspeed ?? 0) != 0)
                    StatView(label: "Uptime", value: device.formattedUptime)
                    StatView(label: "Shares A/R", value: "\(device.sharesAccepted ?? 0)/\(device.sharesRejected ?? 0)")
                    StatView(label: "Difficulty", value: "S: \(device.bestSessionDiff ?? "N/A")/B: \(device.bestDiff ?? "N/A")")
                    StatView(label: "ASIC Model", value: device.ASICModel ?? "N/A")
                    StatView(label: "Version", value: device.version ?? "N/A")
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            isHashrateZero ? (flashRed ? Color.red.opacity(0.3) : Color.red.opacity(0.15)) : rowBackground
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            guard isHashrateZero else { return }
            withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                flashRed.toggle()
            }
        }
    }

    private func hostnameColor(_ hostname: String?) -> Color {
        // Check for a color from the rule manager first.
        if let customColor = hostnameColorManager.color(for: hostname) {
            return customColor
        }
        
        // If no rule matches, return the default primary text color.
        return themeManager.colors.primaryText
    }
    
    static func == (lhs: DeviceRowView, rhs: DeviceRowView) -> Bool {
        lhs.device == rhs.device
    }
}

struct StatView: View {
    let label: String
    let value: String
    var isWarning: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.colors.secondaryText)
            Text(value)
                .font(Font.caption.weight(.medium))
                .foregroundColor(isWarning ? .red : themeManager.colors.primaryText)
                .lineLimit(1)
        }
    }
}

struct SmallStatView: View {
    let label: String
    let value: String
    var isWarning: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.colors.secondaryText)
            Text(value)
                .font(.caption2.weight(.medium))
                .foregroundColor(isWarning ? .red : themeManager.colors.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DashboardFooterView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var onInfoButtonTapped: () -> Void

    private func formattedCurrency(from value: Double?) -> String {
        guard let value = value else { return "–" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.bitcoinInfo.currency.uppercased()
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formattedNumber(_ value: Double, decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimalPlaces)f", value)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                if viewModel.totalHashrate > 99999.99 {
                    let totalTeraHash = viewModel.totalHashrate / 1000
                    Text("Total Hashrate: \(formattedNumber(totalTeraHash, decimalPlaces: 2)) TH/s")
                        .font(viewModel.totalHashrate > 0 ? .title2.weight(.bold) : .title3.weight(.medium))
                        .foregroundColor(viewModel.totalHashrate > 0 ? themeManager.colors.primaryText : themeManager.colors.secondaryText)
                } else {
                    Text("Total Hashrate: \(formattedNumber(viewModel.totalHashrate, decimalPlaces: 2)) GH/s")
                        .font(viewModel.totalHashrate > 0 ? .title2.weight(.bold) : .title3.weight(.medium))
                        .foregroundColor(viewModel.totalHashrate > 0 ? themeManager.colors.primaryText : themeManager.colors.secondaryText)
                }
                
                Button(action: onInfoButtonTapped) {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.colors.accent)
                }
                // ACCESSIBILITY: Add a descriptive label for the info button.
                .accessibilityLabel("View total mining statistics")
                .padding(.leading, -5)
            }

            HStack(alignment: .top, spacing: 15) {
                FooterInfoItem(label: "BTC Price", value: formattedCurrency(from: viewModel.bitcoinInfo.btcPrice))
                FooterInfoItem(label: "Sats/\(viewModel.bitcoinInfo.currency.uppercased())", value: viewModel.bitcoinInfo.satsPerUSD.map { String(format: "%.0f", $0) } ?? "–")
                FooterInfoItem(label: "Block Height", value: viewModel.bitcoinInfo.blockHeight.map { "\($0)" } ?? "–")
                FooterInfoItem(label: "Difficulty", value: "S: \(viewModel.overallBestSessionDiffDisplay) / B: \(viewModel.overallBestDiffDisplay)")
            }
            .font(.caption)

            HStack {
                Text("Total Power: \(formattedNumber(viewModel.totalPower, decimalPlaces: 1)) W")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.primaryText)
                Spacer()
                if let lastUpdated = viewModel.lastUpdated {
                    Text("Updated: \(lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.secondaryText)
                }
            }
        }
    }
}

struct FooterInfoItem: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.colors.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.colors.primaryText)
        }
    }
}

struct SuperCompactGridView: View {
    let devices: [BitaxeDevice]
    let viewModel: DashboardViewModel

    let columns = [
        GridItem(.adaptive(minimum: 120))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(devices) { device in
                    NavigationLink(destination: DeviceDetailView(deviceIP: device.ip)) {
                        MinerGridCardView(device: device)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct MinerGridCardView: View {
    let device: BitaxeDevice
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hostnameColorManager: HostnameColorManager
    @State private var flashRed: Bool = false

    private var isHashrateZero: Bool {
        (device.hashRate ?? 0) == 0
    }
    
    private var statusColor: Color {
        if isHashrateZero {
            return .red
        } else if (device.temp ?? 0) > 75.0 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func hostnameColor(_ hostname: String?) -> Color {
        if let customColor = hostnameColorManager.color(for: hostname) {
            return customColor
        }
        return themeManager.colors.primaryText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                
                Text(device.hostname ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(hostnameColor(device.hostname))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.hashrateDisplay)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(device.tempDisplay)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(height: 85)
        .background(
            ZStack {
                if isHashrateZero {
                    (flashRed ? Color.red.opacity(0.3) : Color.red.opacity(0.15))
                } else {
                    themeManager.colors.cardBackground
                }
            }
        )
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            guard isHashrateZero else { return }
            withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                flashRed.toggle()
            }
        }
    }
}


#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(HostnameColorManager())
    }
}
#endif
