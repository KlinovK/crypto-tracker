//
//  CryptocurrencyDetailView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI
import Charts

struct CryptocurrencyDetailView: View {
    
    @ObservedObject var viewModel: CryptocurrencyDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    HStack {
                        AsyncImage(url: URL(string: viewModel.cryptocurrency.image)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "bitcoinsign.circle")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.title2)
                                )
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.cryptocurrency.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(viewModel.cryptocurrency.symbol.uppercased())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.toggleFavorite() }) {
                            Image(systemName: viewModel.isFavorite() ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(viewModel.isFavorite() ? .red : .gray)
                                .scaleEffect(viewModel.isFavorite() ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.isFavorite())
                        }
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    
                    // Price Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Price")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            Text("$\(viewModel.cryptocurrency.currentPrice, specifier: "%.2f")")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            if let change = viewModel.cryptocurrency.priceChangePercentage24h {
                                HStack(spacing: 4) {
                                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    
                                    Text("\(abs(change), specifier: "%.2f")%")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(change >= 0 ? .green : .red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill((change >= 0 ? Color.green : Color.red).opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                // Time Period Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chart Period")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedTimePeriod) { _ in
                        Task { await viewModel.loadPriceHistory() }
                    }
                }
                
                // Chart Section
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading chart...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.05))
                        )
                        .padding(.horizontal)
                    } else if !viewModel.priceHistory.isEmpty {
                        Chart(viewModel.priceHistory) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Price", point.price)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Price", point.price)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Market Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Market Information")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        if let marketCap = viewModel.cryptocurrency.marketCap {
                            InfoCard(title: "Market Cap", largeNumber: marketCap, icon: "chart.bar.fill")
                        }
                        
                        if let volume = viewModel.cryptocurrency.totalVolume {
                            InfoCard(title: "24h Volume", largeNumber: volume, icon: "arrow.left.arrow.right")
                        }
                        
                        if let high = viewModel.cryptocurrency.high24h {
                            InfoCard(title: "24h High", currencyValue: high, icon: "arrow.up.circle.fill", accentColor: .green)
                        }
                        
                        if let low = viewModel.cryptocurrency.low24h {
                            InfoCard(title: "24h Low", currencyValue: low, icon: "arrow.down.circle.fill", accentColor: .red)
                        }
                        
                        if let supply = viewModel.cryptocurrency.circulatingSupply {
                            InfoCard(title: "Circulating Supply", numberValue: supply, decimals: 0, icon: "repeat.circle.fill")
                        }
                        
                        if let maxSupply = viewModel.cryptocurrency.maxSupply {
                            InfoCard(title: "Max Supply", numberValue: maxSupply, decimals: 0, icon: "infinity.circle.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Bottom spacing
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.cryptocurrency.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.loadPriceHistory()
        }
    }
}
