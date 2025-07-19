//
//  BitcoinFacts.swift
//  bitaxe
//
//  Created by Brent Parks on 6/16/25.
//

// BitcoinFacts.swift

import Foundation

struct BitcoinFacts {
    
    /// A static collection of interesting facts about Bitcoin.
    static let facts: [String] = [
        "1 BTC == 1 BTC",
        "USD < BTC",
    ]
    
    /// Returns a random fact from the static list.
    /// - Returns: A random Bitcoin fact as a `String`.
    static func getRandomFact() -> String {
        return facts.randomElement() ?? "Bitcoin is a decentralized digital currency."
    }
}
