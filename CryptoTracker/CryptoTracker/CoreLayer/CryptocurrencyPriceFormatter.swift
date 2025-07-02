//
//  CryptocurrencyPriceFormatter.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 01/07/25.
//

import SwiftUI

class CryptocurrencyPriceFormatter {
    static let shared = CryptocurrencyPriceFormatter()
    
    // MARK: - Private Properties
    private let currencyFormatter: NumberFormatter
    private let percentageFormatter: NumberFormatter
    private let decimalFormatter: NumberFormatter
    
    // MARK: - Constants
    private enum Constants {
        static let trillion: Double = 1_000_000_000_000
        static let billion: Double = 1_000_000_000
        static let million: Double = 1_000_000
        static let thousand: Double = 1_000
        
        enum PriceThresholds {
            static let highPrice: Double = 1000
            static let mediumPrice: Double = 1
            static let lowPrice: Double = 0.01
        }
        
        enum DecimalPlaces {
            static let none = 0
            static let standard = 2
            static let precise = 4
            static let crypto = 8
        }
    }
    
    // MARK: - Initialization
    private init() {
        currencyFormatter = NumberFormatter()
        percentageFormatter = NumberFormatter()
        decimalFormatter = NumberFormatter()
        
        setupCurrencyFormatter()
        setupPercentageFormatter()
        setupDecimalFormatter()
    }
    
    // MARK: - Setup Methods
    private func setupCurrencyFormatter() {
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        currencyFormatter.currencySymbol = "$"
    }
    
    private func setupPercentageFormatter() {
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = Constants.DecimalPlaces.standard
        percentageFormatter.minimumFractionDigits = Constants.DecimalPlaces.standard
        percentageFormatter.positivePrefix = "+"
    }
    
    private func setupDecimalFormatter() {
        decimalFormatter.numberStyle = .decimal
    }
    
    // MARK: - Public Methods
    
    /// Format price with appropriate decimal places based on magnitude
    public func formatPrice(_ price: Double) -> String {
        let decimalPlaces = getDecimalPlacesForPrice(price)
        
        currencyFormatter.maximumFractionDigits = decimalPlaces.max
        currencyFormatter.minimumFractionDigits = decimalPlaces.min
        
        return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
    
    /// Format percentage change with appropriate sign
    public func formatPercentageChange(_ change: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: change / 100)) ?? "0.00%"
    }
    
    /// Format price in compact notation (K, M, B, T)
    public func formatCompactPrice(_ price: Double) -> String {
        if price >= Constants.million {
            return formatLargeNumber(price, includeSymbol: true)
        } else {
            return formatPrice(price)
        }
    }
    
    /// Format market cap with appropriate suffix
    public func formatMarketCap(_ marketCap: Double) -> String {
        return formatLargeNumber(marketCap, includeSymbol: true)
    }
    
    /// Format large numbers with K, M, B, T suffixes
    public func formatLargeNumber(_ number: Double, includeSymbol: Bool = true) -> String {
        let (scaledValue, suffix) = getScaledValueAndSuffix(for: number)
        let decimalPlaces = getDecimalPlacesForLargeNumber(scaledValue)
        
        if includeSymbol {
            currencyFormatter.maximumFractionDigits = decimalPlaces
            currencyFormatter.minimumFractionDigits = 0
            let formattedValue = currencyFormatter.string(from: NSNumber(value: scaledValue)) ?? "$0"
            return formattedValue + suffix
        } else {
            decimalFormatter.maximumFractionDigits = decimalPlaces
            decimalFormatter.minimumFractionDigits = 0
            let formattedValue = decimalFormatter.string(from: NSNumber(value: scaledValue)) ?? "0"
            return formattedValue + suffix
        }
    }
    
    /// Get appropriate color for percentage change
    public func colorForPercentageChange(_ change: Double) -> Color {
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .primary
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getDecimalPlacesForPrice(_ price: Double) -> (min: Int, max: Int) {
        switch price {
        case Constants.PriceThresholds.highPrice...:
            return (Constants.DecimalPlaces.none, Constants.DecimalPlaces.none)
        case Constants.PriceThresholds.mediumPrice..<Constants.PriceThresholds.highPrice:
            return (Constants.DecimalPlaces.standard, Constants.DecimalPlaces.standard)
        case Constants.PriceThresholds.lowPrice..<Constants.PriceThresholds.mediumPrice:
            return (Constants.DecimalPlaces.precise, Constants.DecimalPlaces.precise)
        default:
            return (Constants.DecimalPlaces.standard, Constants.DecimalPlaces.crypto)
        }
    }
    
    private func getScaledValueAndSuffix(for number: Double) -> (value: Double, suffix: String) {
        switch number {
        case Constants.trillion...:
            return (number / Constants.trillion, "T")
        case Constants.billion..<Constants.trillion:
            return (number / Constants.billion, "B")
        case Constants.million..<Constants.billion:
            return (number / Constants.million, "M")
        case Constants.thousand..<Constants.million:
            return (number / Constants.thousand, "K")
        default:
            return (number, "")
        }
    }
    
    private func getDecimalPlacesForLargeNumber(_ scaledValue: Double) -> Int {
        return scaledValue >= 100 ? 0 : (scaledValue >= 10 ? 1 : 2)
    }
}

// MARK: - Extensions

extension CryptocurrencyPriceFormatter {
    /// Format volume with appropriate suffix
    public func formatVolume(_ volume: Double) -> String {
        return formatLargeNumber(volume, includeSymbol: true)
    }
    
    /// Format supply (typically without currency symbol)
    public func formatSupply(_ supply: Double) -> String {
        return formatLargeNumber(supply, includeSymbol: false)
    }
    
    /// Check if a price change is significant (> 5%)
    public func isSignificantChange(_ change: Double) -> Bool {
        return abs(change) > 5.0
    }
}

// MARK: - Chart Formatting

extension CryptocurrencyPriceFormatter {
    /// Format price for Y-axis labels in charts
    public func formatYAxisPrice(_ price: Double) -> String {
        // For very small prices, show more precision
        if price < 0.001 {
            return String(format: "$%.6f", price)
        }
        // For small prices, show 4 decimal places
        else if price < 0.01 {
            return String(format: "$%.4f", price)
        }
        // For medium prices, show 2-3 decimal places
        else if price < 1 {
            return String(format: "$%.3f", price)
        }
        // For prices $1-$999, show 2 decimal places
        else if price < 1000 {
            return String(format: "$%.2f", price)
        }
        // For prices $1K-$999K, show 1 decimal place and K suffix
        else if price < 1_000_000 {
            let thousands = price / 1000
            if thousands < 10 {
                return String(format: "$%.1fK", thousands)
            } else {
                return String(format: "$%.0fK", thousands)
            }
        }
        // For prices $1M+, use M/B/T suffixes
        else {
            return formatCompactYAxisPrice(price)
        }
    }
    
    /// Format very large prices for Y-axis with compact notation
    private func formatCompactYAxisPrice(_ price: Double) -> String {
        if price >= Constants.trillion {
            let trillions = price / Constants.trillion
            return String(format: trillions < 10 ? "$%.1fT" : "$%.0fT", trillions)
        } else if price >= Constants.billion {
            let billions = price / Constants.billion
            return String(format: billions < 10 ? "$%.1fB" : "$%.0fB", billions)
        } else if price >= Constants.million {
            let millions = price / Constants.million
            return String(format: millions < 10 ? "$%.1fM" : "$%.0fM", millions)
        }
        return formatYAxisPrice(price)
    }
    
    /// Get optimal number of Y-axis ticks based on price range
    public func getOptimalYAxisTickCount(minPrice: Double, maxPrice: Double) -> Int {
        let range = maxPrice - minPrice
        let magnitude = log10(range)
        
        switch magnitude {
        case ..<(-3): return 6  // Very small ranges
        case (-3)..<(-1): return 5
        case (-1)..<1: return 4
        case 1..<3: return 5
        default: return 4  // Large ranges
        }
    }
}

// MARK: - Convenience Methods

extension CryptocurrencyPriceFormatter {
    /// Format a complete price display with change
    public func formatPriceWithChange(_ price: Double, change: Double) -> (price: String, change: String, color: Color) {
        return (
            price: formatPrice(price),
            change: formatPercentageChange(change),
            color: colorForPercentageChange(change)
        )
    }
    
    /// Format market data summary
    public func formatMarketSummary(price: Double, marketCap: Double, volume: Double) -> (price: String, marketCap: String, volume: String) {
        return (
            price: formatPrice(price),
            marketCap: formatMarketCap(marketCap),
            volume: formatVolume(volume)
        )
    }
}
