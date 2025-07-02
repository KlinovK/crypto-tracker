//
//  InfoCardView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct InfoCardView: View {
    
    let title: String
    var largeNumber: Double? = nil
    var currencyValue: Double? = nil
    var numberValue: Double? = nil
    var decimals: Int = 2
    let icon: String
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let largeNumber = largeNumber {
                Text(CryptocurrencyPriceFormatter.shared.formatLargeNumber(largeNumber))
                    .font(.headline)
                    .fontWeight(.semibold)
            } else if let currencyValue = currencyValue {
                Text("$\(currencyValue, specifier: "%.\(decimals)f")")
                    .font(.headline)
                    .fontWeight(.semibold)
            } else if let numberValue = numberValue {
                Text("\(numberValue, specifier: "%.\(decimals)f")")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
}
