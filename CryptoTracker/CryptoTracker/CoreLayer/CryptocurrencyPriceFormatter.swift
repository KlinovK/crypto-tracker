//
//  CryptocurrencyPriceFormatter.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 01/07/25.
//

import SwiftUI

/// A utility class for formatting cryptocurrency-related values (price, market cap, percentage change, etc.).
final class CryptocurrencyPriceFormatter {
    static let shared = CryptocurrencyPriceFormatter()

    // MARK: - Formatters

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter
    }()

    private let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter
    }()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    // MARK: - Constants

    private enum Threshold {
        static let thousand = 1_000.0
        static let million = 1_000_000.0
        static let billion = 1_000_000_000.0
        static let trillion = 1_000_000_000_000.0
    }

    private enum PriceRange {
        static let high = 1_000.0
        static let medium = 1.0
        static let low = 0.01
    }

    private enum Precision {
        static let none = 0
        static let standard = 2
        static let precise = 4
        static let crypto = 8
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Methods

    /// Formats a price using dynamic precision based on its magnitude.
    func formatPrice(_ price: Double) -> String {
        let (min, max) = decimalPrecision(for: price)
        currencyFormatter.minimumFractionDigits = min
        currencyFormatter.maximumFractionDigits = max
        return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }

    /// Formats a percentage change, including sign and 2 decimal places.
    func formatPercentageChange(_ change: Double) -> String {
        percentageFormatter.string(from: NSNumber(value: change / 100)) ?? "0.00%"
    }

    /// Formats price with K, M, B, or T suffix if large enough.
    func formatCompactPrice(_ price: Double) -> String {
        price >= Threshold.million ? formatLargeNumber(price) : formatPrice(price)
    }

    /// Formats a market cap value with suffix.
    func formatMarketCap(_ value: Double) -> String {
        formatLargeNumber(value)
    }

    /// Formats a volume value with suffix.
    func formatVolume(_ value: Double) -> String {
        formatLargeNumber(value)
    }

    /// Formats a coin supply value (without currency symbol).
    func formatSupply(_ value: Double) -> String {
        formatLargeNumber(value, includeSymbol: false)
    }

    /// Returns a `Color` based on change sign (green = positive, red = negative).
    func colorForPercentageChange(_ change: Double) -> Color {
        change > 0 ? .green : change < 0 ? .red : .primary
    }

    /// Determines if a change is significant (> ±5%).
    func isSignificantChange(_ change: Double) -> Bool {
        abs(change) > 5.0
    }

    /// Formats price and change together for display.
    func formatPriceWithChange(_ price: Double, change: Double) -> (price: String, change: String, color: Color) {
        (formatPrice(price), formatPercentageChange(change), colorForPercentageChange(change))
    }

    /// Formats price, market cap, and volume into a summary tuple.
    func formatMarketSummary(price: Double, marketCap: Double, volume: Double) -> (price: String, marketCap: String, volume: String) {
        (formatPrice(price), formatMarketCap(marketCap), formatVolume(volume))
    }
}

extension CryptocurrencyPriceFormatter {
    
    /// Formats price for Y-axis labels in charts using compact logic.
    func formatYAxisPrice(_ price: Double) -> String {
        switch price {
        case ..<0.001: return String(format: "$%.6f", price)
        case ..<0.01: return String(format: "$%.4f", price)
        case ..<1: return String(format: "$%.3f", price)
        case ..<1_000: return String(format: "$%.2f", price)
        case ..<1_000_000:
            let kValue = price / 1_000
            return kValue < 10 ? String(format: "$%.1fK", kValue) : String(format: "$%.0fK", kValue)
        default:
            return formatCompactYAxisPrice(price)
        }
    }

    /// Formats very large values for Y-axis using suffix notation.
    private func formatCompactYAxisPrice(_ price: Double) -> String {
        let formatter: (Double, String) -> String = { value, suffix in
            value < 10 ? String(format: "$%.1f%@", value, suffix) : String(format: "$%.0f%@", value, suffix)
        }
        
        if price >= Threshold.trillion { return formatter(price / Threshold.trillion, "T") }
        if price >= Threshold.billion  { return formatter(price / Threshold.billion, "B") }
        if price >= Threshold.million  { return formatter(price / Threshold.million, "M") }
        return formatYAxisPrice(price)
    }

    /// Determines ideal Y-axis tick count based on price range.
    func getOptimalYAxisTickCount(minPrice: Double, maxPrice: Double) -> Int {
        let magnitude = log10(maxPrice - minPrice)
        switch magnitude {
        case ..<(-3): return 6
        case ..<(-1): return 5
        case ..<1: return 4
        case ..<3: return 5
        default: return 4
        }
    }
}

private extension CryptocurrencyPriceFormatter {
    
    func decimalPrecision(for price: Double) -> (Int, Int) {
        switch price {
        case PriceRange.high...:
            return (Precision.none, Precision.none)
        case PriceRange.medium..<PriceRange.high:
            return (Precision.standard, Precision.standard)
        case PriceRange.low..<PriceRange.medium:
            return (Precision.precise, Precision.precise)
        default:
            return (Precision.standard, Precision.crypto)
        }
    }

    func formatLargeNumber(_ number: Double, includeSymbol: Bool = true) -> String {
        let (value, suffix) = scaledValue(for: number)
        let digits = value >= 100 ? 0 : value >= 10 ? 1 : 2
        
        let formatter = includeSymbol ? currencyFormatter : decimalFormatter
        formatter.maximumFractionDigits = digits
        formatter.minimumFractionDigits = 0
        
        let formatted = formatter.string(from: NSNumber(value: value)) ?? (includeSymbol ? "$0" : "0")
        return formatted + suffix
    }

    func scaledValue(for number: Double) -> (Double, String) {
        switch number {
        case Threshold.trillion...: return (number / Threshold.trillion, "T")
        case Threshold.billion...:  return (number / Threshold.billion, "B")
        case Threshold.million...:  return (number / Threshold.million, "M")
        case Threshold.thousand...: return (number / Threshold.thousand, "K")
        default: return (number, "")
        }
    }
}
