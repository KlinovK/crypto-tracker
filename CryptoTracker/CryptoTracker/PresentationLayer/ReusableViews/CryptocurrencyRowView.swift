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
                Text("$\(cryptocurrency.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                
                if let change = cryptocurrency.priceChangePercentage24h {
                    Text("\(change, specifier: "%.2f")%")
                        .font(.caption)
                        .foregroundColor(change >= 0 ? .green : .red)
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
