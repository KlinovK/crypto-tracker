//
//  TimePeriodDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

enum TimePeriod: String, CaseIterable {
    case day = "1"
    case week = "7"
    case month = "30"
    
    var displayName: String {
        switch self {
        case .day: return "1D"
        case .week: return "7D"
        case .month: return "30D"
        }
    }
}
