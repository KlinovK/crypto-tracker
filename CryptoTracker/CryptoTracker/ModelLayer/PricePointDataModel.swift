//
//  PricePointDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

struct PricePoint: Identifiable {
    let id = UUID()
    let index: Int
    let price: Double
    let timestamp: Date?
    
    init(index: Int, price: Double, timestamp: Date? = nil) {
        self.index = index
        self.price = price
        self.timestamp = timestamp
    }
}
