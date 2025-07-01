//
//  SparklineChartView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 01/07/25.
//

import SwiftUI
import Charts

struct SparklineChartView: View {
    let prices: [Double]
    
    var body: some View {
        let pricePoints = prices.enumerated().map { index, price in
            PricePoint(index: index, price: price)
        }
        
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let rangePadding = (maxPrice - minPrice) * 0.05
        let paddedMin = minPrice - rangePadding
        let paddedMax = maxPrice + rangePadding
        
        let xDomain = 0...(prices.count - 1)
        let priceChange = (prices.last ?? 0) >= (prices.first ?? 0)
        
        Chart(pricePoints) { point in
            LineMark(
                x: .value("Time", point.index),
                y: .value("Price", point.price)
            )
            .foregroundStyle(priceChange ? .green : .red)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: paddedMin...paddedMax)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisTick()
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisTick()
                    .foregroundStyle(.gray.opacity(0.5))
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(price, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
