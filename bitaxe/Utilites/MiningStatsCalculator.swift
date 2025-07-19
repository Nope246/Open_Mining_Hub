// MiningStatsCalculator.swift

import Foundation

struct MiningStatsCalculator {
    
    // Renamed for clarity
    struct MiningProjections {
        let nextBlock: Double
        let next24Hours: Double
        let nextYear: Double
        // --- New Property ---
        let timeToFindBlockYears: Double
    }
    
    /// Calculates mining projections including probabilities and estimated time to find a block.
    /// - Parameters:
    ///   - deviceHashrate: The hashrate of the user's device in hashes per second (H/s).
    ///   - networkHashrate: The total network hashrate in hashes per second (H/s).
    /// - Returns: A struct containing the calculated projections.
    static func calculateProjections(deviceHashrate: Double, networkHashrate: Double) -> MiningProjections? {
        guard deviceHashrate > 0, networkHashrate > 0 else {
            return nil
        }
        
        let pNextBlock = deviceHashrate / networkHashrate
        
        // --- Probability Calculations (same as before) ---
        let avgBlockTimeSeconds = 600.0 // 10 minutes
        let secondsIn24Hours = 86400.0
        let blocksIn24Hours = secondsIn24Hours / avgBlockTimeSeconds
        let pNotFindingBlockIn24Hours = pow((1.0 - pNextBlock), blocksIn24Hours)
        let pNext24Hours = 1.0 - pNotFindingBlockIn24Hours
        
        let secondsInYear = 31536000.0
        let blocksInYear = secondsInYear / avgBlockTimeSeconds
        let pNotFindingBlockInYear = pow((1.0 - pNextBlock), blocksInYear)
        let pNextYear = 1.0 - pNotFindingBlockInYear
        
        // --- New: Time to Find a Block Calculation ---
        // Time (in seconds) = (1 / probability) * average_block_time
        let timeToFindInSeconds = (1.0 / pNextBlock) * avgBlockTimeSeconds
        let timeToFindInYears = timeToFindInSeconds / secondsInYear
        
        return MiningProjections(
            nextBlock: pNextBlock,
            next24Hours: pNext24Hours,
            nextYear: pNextYear,
            timeToFindBlockYears: timeToFindInYears
        )
    }
}
