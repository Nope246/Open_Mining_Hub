//
//  DifficultyConverter.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.
//

// File: DifficultyConverter.swift (or add to an existing utility/model file)
import Foundation

struct DifficultyConverter {
    static func toDouble(difficultyString: String?) -> Double? {
        guard var stringValue = difficultyString?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !stringValue.isEmpty else {
            return nil
        }

        var multiplier: Double = 1.0
        // Order suffixes from largest to smallest for correct parsing if a value could contain multiple (e.g. "1.5GK" - though unlikely for this data)
        let suffixes: [(String, Double)] = [
            ("P", 1e15), // Peta
            ("T", 1e12), // Tera
            ("G", 1e9),  // Giga
            ("M", 1e6),  // Mega
            ("K", 1e3)   // Kilo
        ]

        for (suffix, factor) in suffixes {
            if stringValue.hasSuffix(suffix) {
                multiplier = factor
                // Remove the suffix from the string
                stringValue = String(stringValue.dropLast(suffix.count))
                break // Found the suffix, no need to check others
            }
        }

        // Attempt to convert the remaining string part to a Double
        guard let numericValue = Double(stringValue) else {
            return nil // Not a valid number after removing suffix (or if it was non-numeric initially)
        }

        return numericValue * multiplier
    }

    // Optional: If you ever need to format a double back to a K/M/G/T string.
    // For this request, we'll use the original string from the device.
    /*
    static func format(value: Double?) -> String {
        guard let val = value, val > 0 else { return "N/A" }

        let suffixes: [(String, Double)] = [
            ("P", 1e15), ("T", 1e12), ("G", 1e9), ("M", 1e6), ("K", 1e3)
        ]

        for (suffix, threshold) in suffixes {
            if val >= threshold {
                return String(format: "%.2f%@", val / threshold, suffix)
            }
        }
        // Format for numbers smaller than K, adjust precision as needed
        return String(format: "%.0f", val)
    }
    */
}


//  End of DifficultyConverter.swift
