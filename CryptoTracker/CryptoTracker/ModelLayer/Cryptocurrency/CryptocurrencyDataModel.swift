//
//  CryptocurrencyDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

class Cryptocurrency: Codable, Identifiable, Equatable {
    
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
    
    init(
        id: String,
        name: String,
        symbol: String,
        image: String,
        currentPrice: Double,
        marketCap: Double?,
        totalVolume: Double?,
        priceChangePercentage24h: Double?,
        high24h: Double?,
        low24h: Double?,
        circulatingSupply: Double?,
        maxSupply: Double?
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.image = image
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.totalVolume = totalVolume
        self.priceChangePercentage24h = priceChangePercentage24h
        self.high24h = high24h
        self.low24h = low24h
        self.circulatingSupply = circulatingSupply
        self.maxSupply = maxSupply
    }
    
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
    
    static func == (lhs: Cryptocurrency, rhs: Cryptocurrency) -> Bool {
        lhs.id == rhs.id
    }
    
}

extension Cryptocurrency {
    
    /// Initializes a `Cryptocurrency` model from a `CryptocurrencyEntity` (Core Data).
    ///
    /// - Parameter entity: The Core Data entity.
    /// - Returns: A `Cryptocurrency` instance or `nil` if required fields are missing.
    convenience init?(entity: CryptocurrencyEntity) {
        guard let id = entity.id,
              let symbol = entity.symbol,
              let name = entity.name,
              let image = entity.image else {
            return nil
        }

        self.init(
            id: id,
            name: name,
            symbol: symbol,
            image: image,
            currentPrice: entity.currentPrice,
            marketCap: entity.marketCap,
            totalVolume: entity.totalVolume,
            priceChangePercentage24h: entity.priceChangePercentage,
            high24h: entity.high24h,
            low24h: entity.low24h,
            circulatingSupply: entity.circulatingSupply,
            maxSupply: entity.maxSupply
        )
    }
    
    /// Updates a `CryptocurrencyEntity` with the current model's data.
    ///
    /// - Parameter entity: The Core Data entity to update.
    func update(_ entity: CryptocurrencyEntity) {
        entity.id = self.id
        entity.name = self.name
        entity.symbol = self.symbol
        entity.image = self.image
        entity.currentPrice = self.currentPrice
        entity.marketCap = self.marketCap ?? 0
        entity.totalVolume = self.totalVolume ?? 0
        entity.priceChangePercentage = self.priceChangePercentage24h ?? 0
        entity.high24h = self.high24h ?? 0
        entity.low24h = self.low24h ?? 0
        entity.circulatingSupply = self.circulatingSupply ?? 0
        entity.maxSupply = self.maxSupply ?? 0
    }
}

