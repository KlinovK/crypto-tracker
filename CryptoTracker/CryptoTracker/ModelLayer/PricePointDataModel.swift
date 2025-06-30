//
//  PricePointDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

struct PricePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let price: Double
}
