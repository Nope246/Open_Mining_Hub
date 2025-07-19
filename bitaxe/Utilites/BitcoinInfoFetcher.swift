// Project- Bitaxe Dashboard
//  BitcoinInfoFetcher.swift
//  bitaxe
//
//  Created by Brent Parks on 5/31/25.
//

import Foundation

class BitcoinInfoFetcher {
    private let session = URLSession.shared

    private var lastSuccessfulFetchTime: Date?
    private var cachedBitcoinInfo: BitcoinNetworkInfo?
    private let fetchCooldown: TimeInterval = 60.0 // Cooldown of 1 minute
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "bitcoinInfoCache"

    private func loadFromCache() -> BitcoinNetworkInfo? {
        if let data = userDefaults.data(forKey: cacheKey) {
            return try? JSONDecoder().decode(BitcoinNetworkInfo.self, from: data)
        }
        return nil
    }

    private func saveToCache(_ info: BitcoinNetworkInfo) {
        if let data = try? JSONEncoder().encode(info) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }

    func fetchInfo(currency: String) async -> BitcoinNetworkInfo {
        let currentTime = Date()

        if cachedBitcoinInfo == nil {
            cachedBitcoinInfo = loadFromCache()
        }

        if let lastTime = lastSuccessfulFetchTime,
           let cache = cachedBitcoinInfo,
           currentTime.timeIntervalSince(lastTime) < fetchCooldown {
            if cache.currency.lowercased() == currency.lowercased() {
                print("[BitcoinInfoFetcher] Rate limit applied. Returning cached Bitcoin info for \(currency).")
                return cache
            }
        }

        print("[BitcoinInfoFetcher] Fetching fresh Bitcoin info for currency: \(currency).")
        
        async let priceDataResult = fetchPrice(currency: currency)
        async let blockHeightResult = fetchBlockHeight()
        async let networkDifficultyResult = fetchNetworkDifficulty()

        let (price, sats) = await priceDataResult
        let height = await blockHeightResult
        let difficulty = await networkDifficultyResult
        
        let networkHashrate = difficulty.map { ($0 * pow(2, 32)) / 600 }

        let newInfo = BitcoinNetworkInfo(
            btcPrice: price,
            satsPerUSD: sats,
            blockHeight: height,
            networkDifficulty: difficulty,
            networkHashrate: networkHashrate,
            currency: currency
        )

        self.cachedBitcoinInfo = newInfo
        self.lastSuccessfulFetchTime = currentTime
        saveToCache(newInfo)
        print("[BitcoinInfoFetcher] Successfully fetched/updated Bitcoin info.")
        return newInfo
    }

    private func fetchPrice(currency: String) async -> (price: Double?, satsPerUSD: Double?) {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=\(currency)") else {
            print("[BitcoinInfoFetcher] Invalid CoinGecko URL.")
            return (nil, nil)
        }
        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            if let btcData = decoded["bitcoin"], let currencyPrice = btcData[currency.lowercased()] {
                let sats = currencyPrice > 0 ? floor(100_000_000 / currencyPrice) : nil
                return (currencyPrice, sats)
            }
        } catch {
            print("[BitcoinInfoFetcher] Error fetching BTC price from CoinGecko: \(error)")
        }
        return (nil, nil)
    }

    private func fetchBlockHeight() async -> Int? {
        guard let url = URL(string: "https://blockstream.info/api/blocks/tip/height") else {
            print("[BitcoinInfoFetcher] Invalid Blockstream URL.")
            return nil
        }
        do {
            let (data, _) = try await session.data(from: url)
            if let heightString = String(data: data, encoding: .utf8), let height = Int(heightString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return height
            }
        } catch {
            print("[BitcoinInfoFetcher] Error fetching block height from Blockstream: \(error)")
        }
        return nil
    }
    
    private func fetchNetworkDifficulty() async -> Double? {
        guard let url = URL(string: "https://api.blockchain.info/q/getdifficulty") else {
            print("[BitcoinInfoFetcher] Invalid blockchain.info difficulty URL.")
            return nil
        }
        do {
            let (data, _) = try await session.data(from: url)
            if let difficultyString = String(data: data, encoding: .utf8), let difficulty = Double(difficultyString) {
                print("[BitcoinInfoFetcher] Network difficulty fetched: \(difficulty)")
                return difficulty
            }
        } catch {
            print("[BitcoinInfoFetcher] Error fetching network difficulty: \(error)")
        }
        return nil
    }
}
