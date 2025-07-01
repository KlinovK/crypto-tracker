//
//  CryptoPriceChart.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 01/07/25.
//

import SwiftUI
import Charts

struct CryptoPriceChart: View {
    
    let priceHistory: [Double]
    let isLoading: Bool
    let timeRange: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Chart (\(timeRange) days)")
                .font(.headline)
                .padding(.horizontal, 20)
            
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
                    .padding(.horizontal)
            } else if priceHistory.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("No chart data available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal)
            } else {
                SparklineChartView(prices: priceHistory)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
        }
    }
}
