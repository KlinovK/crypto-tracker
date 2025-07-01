//
//  CryptocurrencyRowView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct CryptocurrencyRowView: View {
    
    let cryptocurrency: Cryptocurrency
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    private let priceFormatter = CryptocurrencyPriceFormatter.shared
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: cryptocurrency.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cryptocurrency.name)
                    .font(.headline)
                Text(cryptocurrency.symbol.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Use price formatter
                Text(priceFormatter.formatPrice(cryptocurrency.currentPrice))
                    .font(.headline)
                    .fontWeight(.medium)
                
                // Show 24h high/low if available
                if let high = cryptocurrency.high24h, let low = cryptocurrency.low24h {
                    HStack(spacing: 4) {
                        Text("H: \(priceFormatter.formatPrice(high))")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("L: \(priceFormatter.formatPrice(low))")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                // Show percentage change
                if let change = cryptocurrency.priceChangePercentage24h {
                    Text(priceFormatter.formatPercentageChange(change))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(priceFormatter.colorForPercentageChange(change))
                }
            }
            
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}

