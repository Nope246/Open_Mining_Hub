//
//  CostCalculator.swift
//  bitaxe
//
//  Created by Brent Parks on 6/15/25.
//

// CostCalculator.swift

import Foundation

struct CostCalculator {
    
    struct Costs {
        let perDay: Double
        let perMonth: Double
        let perYear: Double
    }
    
    /// Calculates the estimated electricity cost for a given power usage and rate.
    /// - Parameters:
    ///   - totalWatts: The total power consumption in Watts.
    ///   - ratePerKWH: The cost of electricity per kilowatt-hour.
    /// - Returns: A struct containing the daily, monthly, and yearly costs.
    static func calculateCosts(totalWatts: Double, ratePerKWH: Double) -> Costs? {
        guard totalWatts > 0, ratePerKWH > 0 else {
            return nil
        }
        
        let totalKW = totalWatts / 1000.0
        let costPerHour = totalKW * ratePerKWH
        
        let costPerDay = costPerHour * 24
        let costPerMonth = costPerDay * 30.44 // Average days in a month
        let costPerYear = costPerDay * 365.25 // Accounts for leap years
        
        return Costs(
            perDay: costPerDay,
            perMonth: costPerMonth,
            perYear: costPerYear
        )
    }
}
