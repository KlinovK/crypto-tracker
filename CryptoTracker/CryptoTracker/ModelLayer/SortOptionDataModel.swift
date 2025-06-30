//
//  SortOptionDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

// MARK: - Enhanced SortOption enum

enum SortOption: String, CaseIterable {
    case marketCap = "market_cap_desc"
    case price = "price_desc"
    case priceAsc = "price_asc"
    case volume = "volume_desc"
    case priceChange = "price_change_24h_desc"
    
    var displayName: String {
        switch self {
        case .marketCap: return "Market Cap"
        case .price: return "Price ↓"
        case .priceAsc: return "Price ↑"
        case .volume: return "Volume"
        case .priceChange: return "24h Change"
        }
    }
}
