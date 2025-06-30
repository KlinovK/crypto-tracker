//
//  InfoCard.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct InfoCard: View {
    let title: String
    var largeNumber: Double?
    var currencyValue: Double?
    var numberValue: Double?
    var decimals: Int = 2
    var icon: String = "info.circle.fill"
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Group {
                if let largeNumber = largeNumber {
                    Text(InfoCard.formatLargeNumber(largeNumber))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else if let currencyValue = currencyValue {
                    Text("$\(currencyValue, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else if let numberValue = numberValue {
                    Text("\(numberValue, specifier: "%.\(decimals)f")")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    private static func formatLargeNumber(_ number: Double) -> String {
        let trillion = 1_000_000_000_000.0
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        let thousand = 1_000.0
        
        switch number {
        case trillion...:
            return String(format: "$%.2fT", number / trillion)
        case billion...:
            return String(format: "$%.2fB", number / billion)
        case million...:
            return String(format: "$%.2fM", number / million)
        case thousand...:
            return String(format: "$%.2fK", number / thousand)
        default:
            return String(format: "$%.2f", number)
        }
    }
}
