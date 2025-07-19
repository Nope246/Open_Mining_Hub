// TotalMiningStatsView.swift

import SwiftUI

struct TotalMiningStatsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    // --- DEFAULT CHANGED ---
    @AppStorage("miningMode_v1") private var miningMode: MiningMode = .solo
    
    @AppStorage("poolFee_v1") private var poolFee: Double = 1.0
    @AppStorage("electricityRateKWH_v1") private var electricityRate: Double = 0.15

    @AppStorage("isBitcoinFallAnimationEnabled_v1") private var isBitcoinFallAnimationEnabled: Bool = true
    
    // State variables to track the format of the odds
    @State private var showNextBlockAsPercentage = false
    @State private var show24HourAsPercentage = false
    @State private var showYearAsPercentage = false
    @State private var showPowerballAsPercentage = false
    @State private var showMegaMillionsAsPercentage = false

    // Constants for jackpot odds
    private let powerballOdds: Double = 1.0 / 292_201_338.0
    private let megaMillionsOdds: Double = 1.0 / 302_575_350.0
    
    private let currencySymbols: [String: String] = [
        "usd": "$", "eur": "€", "gbp": "£", "jpy": "¥", "cny": "¥", "cad": "$", "aud": "$", "inr": "₹"
    ]
    private var currencySymbol: String {
        currencySymbols[viewModel.bitcoinInfo.currency] ?? viewModel.bitcoinInfo.currency.uppercased()
    }

    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    themeManager.colors.backgroundGradient
                        .ignoresSafeArea()

                    List {
                        Section(header: Text("Totals").foregroundColor(themeManager.colors.secondaryText)) {
                            StatRow(label: "Combined Hashrate", value: formatTotalHashrate(viewModel.totalHashrate))
                            StatRow(label: "Total Power", value: formatPower(viewModel.totalPower))
                            StatRow(label: "Mining Efficiency", value: formatEfficiency(), infoText: "Efficiency measures how many Joules of energy are used to produce one Terahash of computing power. A lower number is more efficient.")
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                        
                        Section(header: Text("Estimated Electricity Cost (at \(currencySymbol)\(electricityRate, specifier: "%.3f")/kWh)").foregroundColor(themeManager.colors.secondaryText)) {
                            if let costs = calculateCosts() {
                                StatRow(label: "Per Day", value: formatCurrency(costs.perDay))
                                StatRow(label: "Per Month", value: formatCurrency(costs.perMonth))
                                StatRow(label: "Per Year", value: formatCurrency(costs.perYear))
                            } else {
                                Text("Not enough data to calculate costs.")
                                    .foregroundColor(themeManager.colors.secondaryText)
                            }
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                        
                        if miningMode == .pool {
                            poolMiningSection
                        } else {
                            soloMiningSection
                        }
                        
                        Section(header: Text("Network").foregroundColor(themeManager.colors.secondaryText)) {
                            StatRow(label: "Total Hashrate", value: formatNetworkHashrate(viewModel.bitcoinInfo.networkHashrate))
                            StatRow(label: "Difficulty", value: formatDifficulty(viewModel.bitcoinInfo.networkDifficulty), infoText: "A measure of how difficult it is to find a new block compared to the easiest it can ever be. A higher difficulty means more computing power is needed to find a block.")
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                        
                        Section(header: Text("For Comparison (Jackpot Odds)").foregroundColor(themeManager.colors.secondaryText)) {
                            StatRow(label: "Powerball", value: showPowerballAsPercentage ? formatProbability(powerballOdds) : "1 in 292,201,338", onToggle: {
                                withAnimation {
                                    showPowerballAsPercentage.toggle()
                                }
                            })
                            
                            StatRow(label: "Mega Millions", value: showMegaMillionsAsPercentage ? formatProbability(megaMillionsOdds) : "1 in 302,575,350", onToggle: {
                                withAnimation {
                                    showMegaMillionsAsPercentage.toggle()
                                }
                            })
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationTitle("Total Mining Stats")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .tint(themeManager.colors.accent)
                    }
                }
            }
            
            if themeManager.selectedTheme == .bitcoin && isBitcoinFallAnimationEnabled {
                BitcoinFallView()
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var poolMiningSection: some View {
        Section(header: Text("Pool Mining Projections").foregroundColor(themeManager.colors.secondaryText)) {
            if let costs = calculateCosts(), let revenue = calculateRevenue() {
                let profit = revenue.perDay - costs.perDay
                
                StatRow(label: "Est. Daily Revenue", value: formatCurrency(revenue.perDay), infoText: "Estimated daily earnings in USD before electricity costs, based on your hashrate, current Bitcoin price, and pool fees.")
                StatRow(label: "Est. Daily Profit", value: formatCurrency(profit), infoText: "Estimated daily profit in USD after subtracting electricity costs from your revenue.")
                    .foregroundColor(profit >= 0 ? .green : .red)
            } else {
                Text("Not enough data to calculate projections.")
            }
        }
        .listRowBackground(themeManager.colors.cardBackground)
    }
    
    private var soloMiningSection: some View {
        Section(header: Text("Solo Mining Projections").foregroundColor(themeManager.colors.secondaryText)) {
            if let projections = calculateProjections() {
                StatRow(label: "Reward if Block Found", value: "3.125 BTC", infoText: "The current Bitcoin block reward (subsidy) a miner receives for successfully finding a new block. This amount does not include transaction fees.")

                StatRow(label: "Chance to Find Next Block",
                        value: showNextBlockAsPercentage ? formatProbability(projections.nextBlock) : formatOddsOneInX(projections.nextBlock),
                        infoText: "The statistical probability of your miner finding the very next block on the Bitcoin network, based on your share of the total network hashrate.",
                        onToggle: {
                            withAnimation {
                                showNextBlockAsPercentage.toggle()
                            }
                        })
                
                StatRow(label: "Chance in Next 24 Hours",
                        value: show24HourAsPercentage ? formatProbability(projections.next24Hours) : formatOddsOneInX(projections.next24Hours),
                        infoText: "The statistical probability of finding at least one block within the next 24 hours.",
                        onToggle: {
                            withAnimation {
                                show24HourAsPercentage.toggle()
                            }
                        })
                
                StatRow(label: "Chance in Next Year",
                        value: showYearAsPercentage ? formatProbability(projections.nextYear) : formatOddsOneInX(projections.nextYear),
                        infoText: "The statistical probability of finding at least one block within the next year.",
                        onToggle: {
                            withAnimation {
                                showYearAsPercentage.toggle()
                            }
                        })

                StatRow(label: "Est. Time to Find Block", value: formatYears(projections.timeToFindBlockYears), infoText: "On average, this is how long it would take for your miner to find a block if you were mining solo 24/7. This is a statistical average, not a guarantee.")
            } else {
                Text("Not enough data to calculate projections.")
            }
        }
        .listRowBackground(themeManager.colors.cardBackground)
    }
    
    private func calculateCosts() -> EconomicsCalculator.Costs? {
        return EconomicsCalculator.calculateCosts(totalWatts: viewModel.totalPower, ratePerKWH: electricityRate)
    }
    
    private func calculateRevenue() -> EconomicsCalculator.PoolRevenue? {
        guard let networkHashrate = viewModel.bitcoinInfo.networkHashrate,
              let btcPrice = viewModel.bitcoinInfo.btcPrice else { return nil }
        
        return EconomicsCalculator.calculatePoolRevenue(
            totalHashrateGHs: viewModel.totalHashrate,
            networkHashrateHs: networkHashrate,
            btcPrice: btcPrice,
            poolFeePercent: poolFee
        )
    }
    
    private func calculateProjections() -> MiningStatsCalculator.MiningProjections? {
        let totalHashesPerSecond = viewModel.totalHashrate * 1_000_000_000
        guard let networkHashes = viewModel.bitcoinInfo.networkHashrate else { return nil }
        return MiningStatsCalculator.calculateProjections(deviceHashrate: totalHashesPerSecond, networkHashrate: networkHashes)
    }
    
    private func createNumberFormatter(decimalPlaces: Int = 2) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.bitcoinInfo.currency.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func formatYears(_ years: Double) -> String {
        let formatter = createNumberFormatter()
        let yearString = formatter.string(from: NSNumber(value: years)) ?? "\(years)"
        return "\(yearString) years"
    }

    private func formatTotalHashrate(_ gigaHashes: Double) -> String {
        let formatter = createNumberFormatter()
        let hashString = formatter.string(from: NSNumber(value: gigaHashes)) ?? "\(gigaHashes)"
        return "\(hashString) GH/s"
    }
    
    private func formatPower(_ watts: Double) -> String {
        let formatter = createNumberFormatter(decimalPlaces: 1)
        let powerString = formatter.string(from: NSNumber(value: watts)) ?? "\(watts)"
        return "\(powerString) W"
    }
    
    private func formatEfficiency() -> String {
        guard viewModel.totalPower > 0, viewModel.totalHashrate > 0 else { return "N/A" }
        let totalTeraHashes = viewModel.totalHashrate / 1000.0
        guard totalTeraHashes > 0 else { return "N/A" }
        let efficiency = viewModel.totalPower / totalTeraHashes
        let formatter = createNumberFormatter(decimalPlaces: 1)
        let efficiencyString = formatter.string(from: NSNumber(value: efficiency)) ?? "\(efficiency)"
        return "\(efficiencyString) J/TH"
    }
    
    private func formatNetworkHashrate(_ hashrate: Double?) -> String {
        guard let hashrate = hashrate else { return "N/A" }
        let formatter = createNumberFormatter()
        let ehs = hashrate / 1_000_000_000_000_000_000
        let hashString = formatter.string(from: NSNumber(value: ehs)) ?? "\(ehs)"
        return "\(hashString) EH/s"
    }
    
    private func formatDifficulty(_ difficulty: Double?) -> String {
        guard let difficulty = difficulty else { return "N/A" }
        let formatter = createNumberFormatter()
        let trillions = difficulty / 1_000_000_000_000
        let diffString = formatter.string(from: NSNumber(value: trillions)) ?? "\(trillions)"
        return "\(diffString) T"
    }
    
    private func formatOddsOneInX(_ probability: Double) -> String {
        guard probability > 0 else { return "N/A" }
        
        let oneInX = 1.0 / probability
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        
        if oneInX < 100 {
            formatter.maximumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }
        
        let numberString = formatter.string(from: NSNumber(value: oneInX)) ?? "\(oneInX)"
        return "1 in \(numberString)"
    }
    
    private func formatProbability(_ probability: Double) -> String {
        let percentage = probability * 100
        if percentage < 0.000001 {
            return String(format: "%.10f %%", percentage)
        } else if percentage < 0.001 {
            return String(format: "%.6f %%", percentage)
        } else {
            return String(format: "%.4f %%", percentage)
        }
    }
}
