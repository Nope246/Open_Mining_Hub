// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Convenience init for Previews
    init(navigateToNetworkSettings: Binding<Bool> = .constant(false)) {
        _navigateToNetworkSettings = navigateToNetworkSettings
    }
    
    @AppStorage("miningMode_v1") private var miningMode: MiningMode = .solo
    @AppStorage("dashboardViewMode_v1") private var dashboardViewMode: DashboardViewMode = .compact
    @AppStorage("poolFee_v1") private var poolFee: Double = 1.0
    @AppStorage("electricityRateKWH_v1") private var electricityRate: Double = 0.15
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.default.rawValue
    @AppStorage("deviceSortOption_v1") private var selectedSortOptionRawValue: String = DeviceSortOption.hostname.rawValue
    @AppStorage("deviceSortDirection_v1") private var selectedSortDirectionRawValue: String = SortDirection.ascending.rawValue
    
    @AppStorage("financialCurrency_v1") private var selectedCurrency: String = "usd"
    let supportedCurrencies = ["usd", "eur", "gbp", "cad", "aud", "jpy", "cny", "inr"]
    
    @AppStorage("isBitcoinFallAnimationEnabled_v1") private var isBitcoinFallAnimationEnabled: Bool = true
    
    @Binding var navigateToNetworkSettings: Bool
    
    private let currencySymbols: [String: String] = [
        "usd": "$", "eur": "€", "gbp": "£", "jpy": "¥", "cny": "¥", "cad": "$", "aud": "$", "inr": "₹"
    ]
    private var currencySymbol: String {
        currencySymbols[selectedCurrency] ?? selectedCurrency.uppercased()
    }

    @State private var isEditingCustomTheme = false
    @State private var initialCurrency: String = ""
    
    @State private var showingWelcomeScreen = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Financial Settings")) {
                    Picker("Display Currency", selection: $selectedCurrency) {
                        ForEach(supportedCurrencies, id: \.self) { currency in
                            let symbol = currencySymbols[currency] ?? ""
                            Text("\(currency.uppercased()) (\(symbol))").tag(currency)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Mining Mode", selection: $miningMode) {
                        ForEach(MiningMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Image(systemName: "powercord.fill").foregroundColor(themeManager.colors.accent)
                        Text("Electricity Rate (\(currencySymbol) / kWh)")
                        Spacer()
                        TextField("Rate", value: $electricityRate, format: .number.precision(.fractionLength(2...4)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if miningMode == .pool {
                        HStack {
                            Text("Mining Pool Fee (%)")
                            Spacer()
                            TextField("Fee", value: $poolFee, format: .number.precision(.fractionLength(1...2)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
                
                Section(header: Text("Network Configuration")) {
                    
                    NavigationLink(destination: NetworkScanSettingsView()) {
                        HStack {
                            Image(systemName: "network.badge.shield.half.filled")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Scan Settings")
                        }
                    }
                    
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)

                Section(header: Text("Display Settings")) {
                   
                    Picker("Device View Style", selection: $dashboardViewMode) {
                        ForEach(DashboardViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    NavigationLink("Hostname Color Rules", destination: HostnameColorRulesView())
                    
                    Picker("Theme:", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if selectedTheme == AppTheme.bitcoin.rawValue {
                        Toggle("Enable Bitcoin Fall Animation", isOn: $isBitcoinFallAnimationEnabled)
                    }

                    if selectedTheme == AppTheme.custom.rawValue {
                        Button(action: { isEditingCustomTheme = true }) {
                            HStack {
                                Label("Edit Custom Theme", systemImage: "paintbrush.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                            }
                        }
                        .foregroundColor(themeManager.colors.primaryText)
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)

                Section(header: Text("Data Sorting")) {
                    Picker("Sort Devices By:", selection: $selectedSortOptionRawValue) {
                        ForEach(DeviceSortOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSortOptionRawValue) {
                        NotificationCenter.default.post(name: .deviceSortOptionDidChange, object: nil)
                    }

                    Picker("Order:", selection: $selectedSortDirectionRawValue) {
                        ForEach(SortDirection.allCases) { direction in
                            Text(direction.rawValue).tag(direction.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedSortDirectionRawValue) {
                        NotificationCenter.default.post(name: .deviceSortDirectionDidChange, object: nil)
                    }
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)

                Section(header: Text("About & Support")) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(themeManager.colors.accent)
                        Text(AppInfo.fullAppVersion)
                    }

                    Button(action: { showingWelcomeScreen = true }) {
                        // Icon added here
                        HStack {
                            Image(systemName: "receipt.fill")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Review Welcome Screen")
                        }
                    }
                    .tint(themeManager.colors.primaryText)
                    
                    NavigationLink(destination: SupportedDevicesView()) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Supported Devices")
                        }
                    }
                    
                    if let url = URL(string: "https://github.com/Nope246/Open_Mining_Hub.git") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(themeManager.colors.accent)
                                Text("Source Code")
                            }
                        }
                    }

                    NavigationLink(destination: PrivacyInfoView()) {
                        // Icon added here
                        HStack {
                            Image(systemName: "lock.document.fill")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Privacy Policy")
                        }
                    }

                    NavigationLink(destination: DisclaimerView()) {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Disclaimer & Liability")
                        }
                    }


                    
                    if let url = URL(string: "mailto:sushi_tackler.5i@icloud.com?subject=Open_Mining_Hub%20Feedback") {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(themeManager.colors.accent)
                                Text("Feedback")
                            }
                        }
                    }
                 
                    NavigationLink(destination: TipJarView()) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .foregroundColor(themeManager.colors.accent)
                            Text("Send a Tip")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("API Credits:")
                            .font(.footnote)
                        Text("• Bitcoin Price data provided by CoinGecko.")
                            .font(.caption)
                        Text("• Block Height data by Blockstream.info.")
                            .font(.caption)
                        Text("• Network Difficulty by Blockchain.com.")
                            .font(.caption)
                        
                        Text("Special thanks to the awesome developers of the open source mining community.")
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    .foregroundColor(themeManager.colors.secondaryText)
                }
                .listRowBackground(themeManager.colors.cardBackground)
                .foregroundColor(themeManager.colors.primaryText)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $navigateToNetworkSettings) {
                NetworkScanSettingsView()
            }
            .navigationDestination(isPresented: $isEditingCustomTheme) {
                CustomThemeEditorView()
            }
            .sheet(isPresented: $showingWelcomeScreen) {
                WelcomeView(
                    onGetStarted: { showingWelcomeScreen = false },
                    onGoToSettings: { showingWelcomeScreen = false }
                )
                .environmentObject(themeManager)
            }
            .onChange(of: selectedTheme) { _, newValue in
                if newValue == AppTheme.custom.rawValue {
                    isEditingCustomTheme = true
                }
                themeManager.objectWillChange.send()
            }
            .onAppear {
                initialCurrency = selectedCurrency
            }
            .onDisappear {
                if initialCurrency != selectedCurrency {
                    print("Currency changed from \(initialCurrency) to \(selectedCurrency). Posting notification.")
                    NotificationCenter.default.post(name: .currencyDidChange, object: nil)
                }
            }
        }
    }
}
