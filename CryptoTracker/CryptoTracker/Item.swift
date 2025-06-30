//
//  Item.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
