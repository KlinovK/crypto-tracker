//
//  CryptocurrencyPriceFormatter.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 01/07/25.
//

import SwiftUI

class CryptocurrencyPriceFormatter {
    static let shared = CryptocurrencyPriceFormatter()
    
    private let currencyFormatter: NumberFormatter
    private let percentageFormatter: NumberFormatter
    
    private init() {
        // Currency formatter setup
        currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        currencyFormatter.currencySymbol = "$"
        
        // Percentage formatter setup
        percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = 2
        percentageFormatter.minimumFractionDigits = 2
        percentageFormatter.positivePrefix = "+"
    }
    
    // Format price based on magnitude
    func formatPrice(_ price: Double) -> String {
        // Adjust decimal places based on price magnitude
        if price >= 1000 {
            currencyFormatter.maximumFractionDigits = 0
            currencyFormatter.minimumFractionDigits = 0
        } else if price >= 1 {
            currencyFormatter.maximumFractionDigits = 2
            currencyFormatter.minimumFractionDigits = 2
        } else if price >= 0.01 {
            currencyFormatter.maximumFractionDigits = 4
            currencyFormatter.minimumFractionDigits = 4
        } else {
            currencyFormatter.maximumFractionDigits = 8
            currencyFormatter.minimumFractionDigits = 2
        }
        
        return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
    
    // Format percentage change
    func formatPercentageChange(_ change: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: change / 100)) ?? "0.00%"
    }
    
    // Format compact price (for small displays)
    func formatCompactPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        
        if price >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            let millions = price / 1_000_000
            return "$\(formatter.string(from: NSNumber(value: millions))?.dropFirst() ?? "0")M"
        } else if price >= 1000 {
            formatter.maximumFractionDigits = 1
            let thousands = price / 1000
            return "$\(formatter.string(from: NSNumber(value: thousands))?.dropFirst() ?? "0")K"
        } else {
            return formatPrice(price)
        }
    }
    
    // Get color for percentage change
    func colorForPercentageChange(_ change: Double) -> Color {
        return change >= 0 ? .green : .red
    }
    
    // Format market cap
    func formatMarketCap(_ marketCap: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if marketCap >= 1_000_000_000_000 {
            formatter.maximumFractionDigits = 2
            let trillions = marketCap / 1_000_000_000_000
            return "$\(formatter.string(from: NSNumber(value: trillions)) ?? "0")T"
        } else if marketCap >= 1_000_000_000 {
            formatter.maximumFractionDigits = 2
            let billions = marketCap / 1_000_000_000
            return "$\(formatter.string(from: NSNumber(value: billions)) ?? "0")B"
        } else if marketCap >= 1_000_000 {
            formatter.maximumFractionDigits = 2
            let millions = marketCap / 1_000_000
            return "$\(formatter.string(from: NSNumber(value: millions)) ?? "0")M"
        } else {
            return formatPrice(marketCap)
        }
    }
}
