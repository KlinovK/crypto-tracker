//
//  TimePeriodDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

enum TimePeriod: String, CaseIterable {
    case oneDay = "1"
    case oneWeek = "7"
    case oneMonth = "30"
    case threeMonths = "90"
    case oneYear = "365"
    
    var displayName: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "7D"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .oneYear: return "1Y"
        }
    }
    
    var apiValue: String {
        return self.rawValue
    }
}
