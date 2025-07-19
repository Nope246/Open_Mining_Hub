// DeviceDetailView.swift

import SwiftUI
import Charts

struct DeviceDetailView: View {
    let deviceIP: String
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: DashboardViewModel
    
    @State private var showFeedbackToast: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var refreshID = UUID()

    private var device: BitaxeDevice? {
        viewModel.devices.first { $0.ip == deviceIP }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if let device = device {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading) {
                            if let ipURL = URL(string: "http://\(device.ip)") {
                                Link(destination: ipURL) {
                                    Text(device.hostname ?? "Unknown Host")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                }
                                .tint(themeManager.colors.primaryText)
                            } else {
                                Text(device.hostname ?? "Unknown Host")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                            
                            if let ipURL = URL(string: "http://\(device.ip)") {
                                Link(device.ip, destination: ipURL)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .tint(themeManager.colors.accent)
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                            InfoCard(label: "Hashrate", value: device.hashrateDisplay, color: themeManager.colors.accent)
                            InfoCard(label: "Power", value: device.powerDisplay, color: .green)
                            InfoCard(label: "Temperature", value: device.tempDisplay, color: .orange, isWarning: (device.temp ?? 0.0) > 75.0)
                            InfoCard(label: "Fan Speed", value: device.fanDisplay, color: .blue)
                            InfoCard(label: "Uptime", value: device.formattedUptime, color: .purple)
                            InfoCard(label: "Shares A/R", value: "\(device.sharesAccepted ?? 0)/\(device.sharesRejected ?? 0)", color: .teal, infoText: "Accepted shares are valid proofs of work submitted to the mining pool. Rejected shares are invalid and do not contribute to your earnings.")
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All Stats")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .padding(.top)

                            DetailRow(label: "ASIC Model", value: device.ASICModel)
                            DetailRow(label: "Firmware Version", value: device.version)
                            
                            // --- Display NerdQaxe version if available ---
                            if let nerdVersion = device.nerdqaxe_version {
                                DetailRow(label: "NerdQaxe Version", value: nerdVersion)
                            }
                            
                            DetailRow(label: "Session Difficulty", value: device.bestSessionDiff, infoText: "The highest difficulty of a share accepted in the current mining session. This resets when the device reconnects to the pool.")
                            DetailRow(label: "Best Difficulty", value: device.bestDiff, infoText: "The highest difficulty of a share ever accepted by this device across all sessions. This is a historical maximum.")
                            DetailRow(label: "Stratum URL", value: device.stratumURL)
                            DetailRow(label: "Stratum User", value: device.stratumUser)
                            
                            // --- Display NerdQaxe tuning stats if available ---
                            if let powerTune = device.powerTune {
                                DetailRow(label: "Power Tune", value: "\(powerTune)W")
                            }
                            if let autoTune = device.autoTune {
                                DetailRow(label: "Auto Tune", value: autoTune ? "Enabled" : "Disabled")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshDevice(withIP: deviceIP)
                    refreshID = UUID()
                }
                .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
                .navigationTitle(device.hostname ?? "Device Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        NavigationLink(destination: DeviceEditView(device: device)) {
                            Text("Edit")
                        }
                        
                        if viewModel.isIpInPersistentList(ip: device.ip) {
                            Button {
                                viewModel.removeIpFromPersistentList(device.ip)
                                presentFeedbackToast(message: "Removed from IP List")
                            } label: {
                                Label("Remove from List", systemImage: "trash.circle")
                            }
                            .tint(.red)
                        } else {
                            Button {
                                viewModel.addIpToPersistentList(device.ip)
                                presentFeedbackToast(message: "Added to IP List")
                            } label: {
                                Label("Add to List", systemImage: "plus.circle.fill")
                            }
                            .tint(themeManager.colors.accent)
                        }
                    }
                }
            } else {
                VStack {
                    Text("Device not found")
                        .font(.title)
                    Text("It may have been removed from the list.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if showFeedbackToast {
                Text(feedbackMessage)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background((themeManager.colors.accent).opacity(0.90))
                    .foregroundColor(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 20)
            }
        }
    }
    
    private func presentFeedbackToast(message: String) {
        self.feedbackMessage = message
        withAnimation(.spring()) {
            showFeedbackToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFeedbackToast = false
            }
        }
    }
}


// --- STATISTICS VIEW (ENHANCED) ---
struct StatisticsCard: View {
    let device: BitaxeDevice
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var dataService = DataService()
    
    @State private var hashrateData: [ChartDataPoint] = []
    @State private var temperatureData: [ChartDataPoint] = []
    @State private var error: String?

    @State private var isInitialLoad = true

    var body: some View {
        VStack(alignment: .leading) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(themeManager.colors.secondaryText)
            
            VStack(spacing: 20) {
                if isInitialLoad {
                    ProgressView("Loading chart data...")
                        .frame(height: 300)
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 300)
                } else if hashrateData.isEmpty && temperatureData.isEmpty {
                     if (device.statsLimit ?? 0) == 0 {
                         NavigationLink(destination: DeviceEditView(device: device, initialExpandedSection: .statistics)) {
                             VStack(spacing: 8) {
                                 Image(systemName: "chart.bar.xaxis.ascending")
                                     .font(.largeTitle)
                                     .foregroundColor(.secondary)
                                 Text("Statistics Disabled")
                                     .font(.headline)
                                 Text("Tap here to set a 'Data Point Limit' in the edit screen to enable charts.")
                                     .font(.caption)
                                     .multilineTextAlignment(.center)
                                     .foregroundColor(themeManager.colors.secondaryText)
                                     .padding(.horizontal)
                             }
                         }
                         .buttonStyle(.plain)
                         .frame(height: 300)
                     } else {
                         Text("No statistics data available.")
                            .frame(height: 300)
                            .foregroundColor(themeManager.colors.secondaryText)
                     }
                } else {
                    Group {
                        if !hashrateData.isEmpty {
                            InteractiveChartView(
                                title: "Hashrate",
                                data: hashrateData,
                                color: themeManager.colors.accent,
                                unit: "GH/s",
                                specifier: "%.2f"
                            )
                        }
                        if !temperatureData.isEmpty {
                           InteractiveChartView(
                                title: "Chip Temperature",
                                data: temperatureData,
                                color: .orange,
                                unit: "°C",
                                specifier: "%.1f"
                            )
                        }
                    }
                    .frame(height: 150)
                    .animation(.easeInOut, value: hashrateData)
                    .animation(.easeInOut, value: temperatureData)
                }
            }
            .padding()
            .background(themeManager.colors.cardBackground)
            .cornerRadius(12)
        }
        .onAppear(perform: loadStatistics)
        .onChange(of: device) {
            loadStatistics()
        }
    }

    private func loadStatistics() {
        Task {
            let fetchTime = Date()
            let response = await dataService.fetchDeviceStatistics(ip: device.ip)
            
            await MainActor.run {
                if isInitialLoad {
                    isInitialLoad = false
                }
                
                guard let response = response, let deviceUptimeInMillis = response.currentTimestamp else {
                    self.error = "Failed to load statistics or get device uptime."
                    return
                }
                
                guard let labels = response.labels, let statistics = response.statistics else {
                    self.error = "Statistics data is missing or malformed."
                    return
                }
                
                let deviceUptimeInSeconds = deviceUptimeInMillis / 1000.0
                let bootTime = fetchTime.addingTimeInterval(-deviceUptimeInSeconds)

                var tempHashratePoints: [ChartDataPoint] = []
                var tempTemperaturePoints: [ChartDataPoint] = []
                
                let timestampIndex = labels.firstIndex(of: "timestamp")
                let hashrateIndex = labels.firstIndex(of: "hashrate") ?? labels.firstIndex(of: "hashRate")
                let tempIndex = labels.firstIndex(of: "chipTemperature") ?? labels.firstIndex(of: "temp")
                
                guard let tsIndex = timestampIndex else {
                    self.error = "Timestamp data not found in API response."
                    return
                }

                for statArray in statistics {
                    guard statArray.count > tsIndex else { continue }
                    
                    let timeSinceBootInMillis = statArray[tsIndex]
                    let timeSinceBootInSeconds = timeSinceBootInMillis / 1000.0
                    let date = bootTime.addingTimeInterval(timeSinceBootInSeconds)
                    
                    if let hrIndex = hashrateIndex, statArray.count > hrIndex {
                        let hashrateInGhs = statArray[hrIndex] / 1000
                        tempHashratePoints.append(ChartDataPoint(date: date, value: hashrateInGhs))
                    }
                    
                    if let tIndex = tempIndex, statArray.count > tIndex {
                        let temperature = statArray[tIndex]
                        tempTemperaturePoints.append(ChartDataPoint(date: date, value: temperature))
                    }
                }
                
                self.hashrateData = tempHashratePoints
                self.temperatureData = tempTemperaturePoints
            }
        }
    }
}


// --- INTERACTIVE CHART VIEW ---
struct InteractiveChartView: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    let unit: String
    let specifier: String

    @State private var selectedValue: Double?
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading) {
            // Header showing the selected value and time
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let selectedValue = selectedValue, let selectedDate = selectedDate {
                    Text("\(String(format: specifier, selectedValue)) \(unit) at \(formatTimeAgo(from: selectedDate))")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.primary)
                } else if let latestPoint = data.last {
                    Text("Latest: \(String(format: "%.2f", latestPoint.value)) \(unit)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.primary)
                }
            }
            .animation(.none, value: selectedValue) // Prevent animation on text change

            // The Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color)

                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [color.opacity(0.4), .clear]), startPoint: .top, endPoint: .bottom))
                }
                
                // RuleMark to show the scrubber line
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected Time", selectedDate))
                        .foregroundStyle(Color.gray.opacity(0.6))
                        .zIndex(-1)
                }
            }
            .chartXSelection(value: $selectedDate)
            .onChange(of: selectedDate) {
                 // Find the corresponding value for the selected date
                if let date = selectedDate {
                    let closestPoint = data.min(by: { abs($0.date.distance(to: date)) < abs($1.date.distance(to: date)) })
                    if let point = closestPoint {
                        selectedValue = point.value
                    }
                } else {
                    selectedValue = nil
                }
            }
        }
    }

    private func formatTimeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s ago"
        } else {
            return "\(seconds)s ago"
        }
    }
}

// --- Helper Views for the Detail Screen ---

struct InfoCard: View {
    let label: String
    let value: String
    let color: Color
    var isWarning: Bool = false
    var infoText: String? = nil
    
    @State private var showingInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                if let infoText = infoText {
                    Spacer()
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .accessibilityLabel("More information about \(label)")
                    .sheet(isPresented: $showingInfo) {
                        VStack(spacing: 20) {
                            Text(label)
                                .font(.title.bold())
                            Text(infoText)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .presentationDetents([.fraction(0.25)])
                    }
                }
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isWarning ? Color.red.gradient : color.gradient)
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String?
    var infoText: String? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingInfo = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .foregroundColor(themeManager.colors.primaryText)
                
                if let infoText = infoText {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("More information about \(label)")
                    .sheet(isPresented: $showingInfo) {
                        VStack(spacing: 20) {
                            Text(label)
                                .font(.title.bold())
                            Text(infoText)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .presentationDetents([.fraction(0.3)])
                    }
                }
                
                Spacer()
                Text(value ?? "N/A")
                    .foregroundColor(themeManager.colors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.vertical, 4)
            Divider().background(themeManager.colors.secondaryText.opacity(0.5))
        }
    }
}

#if DEBUG
struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let previewDevice: BitaxeDevice = {
            var device = BitaxeDevice()
            device.hostname = "My-Bitaxe"
            device.ip = "192.168.1.100"
            device.power = 5.5
            device.temp = 65.0
            device.hashRate = 500
            device.bestDiff = "1.2M"
            device.bestSessionDiff = "1M"
            device.sharesAccepted = 100
            device.sharesRejected = 2
            device.uptimeSeconds = 3600
            device.ASICModel = "BM1397"
            device.version = "v1.0.0"
            device.stratumURL = "stratum.pool.io"
            device.stratumUser = "myworker.1"
            return device
        }()
        
        NavigationView {
            DeviceDetailView(deviceIP: previewDevice.ip)
                .environmentObject(ThemeManager())
                .environmentObject(DashboardViewModel())
        }
    }
}
#endif
