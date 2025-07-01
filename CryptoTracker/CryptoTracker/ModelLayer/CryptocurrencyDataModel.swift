//
//  CryptocurrencyDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

struct Cryptocurrency: Codable, Identifiable, Equatable {
    static func == (lhs: Cryptocurrency, rhs: Cryptocurrency) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let name: String
    let symbol: String
    let image: String
    let currentPrice: Double
    let marketCap: Double?
    let totalVolume: Double?
    let priceChangePercentage24h: Double?
    let high24h: Double?
    let low24h: Double?
    let circulatingSupply: Double?
    let maxSupply: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, symbol, image
        case currentPrice = "current_price"
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case circulatingSupply = "circulating_supply"
        case maxSupply = "max_supply"
    }
}

