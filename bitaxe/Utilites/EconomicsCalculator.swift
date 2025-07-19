//
//  EconomicsCalculator.swift
//  bitaxe
//
//  Created by Brent Parks on 6/15/25.
//

// EconomicsCalculator.swift

import Foundation

struct EconomicsCalculator {
    
    struct Costs {
        let perDay: Double
        let perMonth: Double
        let perYear: Double
    }
    
    struct PoolRevenue {
        let perDay: Double
        let perMonth: Double
        let perYear: Double
    }

    static func calculateCosts(totalWatts: Double, ratePerKWH: Double) -> Costs? {
        guard totalWatts > 0, ratePerKWH >= 0 else {
            return nil
        }
        
        let totalKW = totalWatts / 1000.0
        let costPerHour = totalKW * ratePerKWH
        
        let costPerDay = costPerHour * 24
        let costPerMonth = costPerDay * 30.44
        let costPerYear = costPerDay * 365.25
        
        return Costs(
            perDay: costPerDay,
            perMonth: costPerMonth,
            perYear: costPerYear
        )
    }
    
    static func calculatePoolRevenue(totalHashrateGHs: Double, networkHashrateHs: Double, btcPrice: Double, poolFeePercent: Double) -> PoolRevenue? {
        guard totalHashrateGHs > 0, networkHashrateHs > 0, btcPrice > 0 else {
            return nil
        }
        
        // --- Constants for Bitcoin Network ---
        let blocksPerDay: Double = 144 // Average 24 * 6
        let blockSubsidy: Double = 3.125 // Current block reward post-2024 halving
        // Note: This doesn't include transaction fees, which add a small variable amount to the reward.
        
        let totalHashesPerSecond = totalHashrateGHs * 1_000_000_000
        
        // Calculate the user's share of the total network hashrate
        let userShareOfNetwork = totalHashesPerSecond / networkHashrateHs
        
        // Calculate estimated BTC earned per day
        let btcPerDay = userShareOfNetwork * blocksPerDay * blockSubsidy
        
        // Calculate revenue in USD
        let grossRevenuePerDay = btcPerDay * btcPrice
        
        // Account for pool fee
        let poolFee = grossRevenuePerDay * (poolFeePercent / 100.0)
        let netRevenuePerDay = grossRevenuePerDay - poolFee
        
        return PoolRevenue(
            perDay: netRevenuePerDay,
            perMonth: netRevenuePerDay * 30.44,
            perYear: netRevenuePerDay * 365.25
        )
    }
}
