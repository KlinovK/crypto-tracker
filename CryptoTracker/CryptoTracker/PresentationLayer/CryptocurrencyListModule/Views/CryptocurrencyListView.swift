//
//  CryptocurrencyListView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct CryptocurrencyListView: View {
    @ObservedObject var viewModel: CryptocurrencyListViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingSortOptions = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            mainContentView
        }
        .navigationTitle("All Cryptos")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                if viewModel.cryptocurrencies.isEmpty {
                    await viewModel.loadCryptocurrencies()
                }
            }
        }
        .confirmationDialog("Sort by", isPresented: $showingSortOptions, titleVisibility: .visible) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(option.displayName) {
                    Task { await viewModel.applySorting(option) }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
    }
    
    // MARK: - Header View (Search Bar + Sort Button)
    private var headerView: some View {
        HStack(spacing: 12) {
            SearchBar(text: $viewModel.searchText)
            
            Button(action: { showingSortOptions = true }) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Content View (Loading, Error, Empty, or List)
    private var contentView: some View {
        Group {
            if viewModel.isLoading && viewModel.cryptocurrencies.isEmpty {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else if let errorMessage = viewModel.errorMessage, viewModel.cryptocurrencies.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await viewModel.loadCryptocurrencies() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else if viewModel.filteredCryptocurrencies.isEmpty {
                EmptyStateView(message: "No cryptocurrencies found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else {
                cryptocurrencyListView
            }
        }
    }
    
    // MARK: - Cryptocurrency List View
    private var cryptocurrencyListView: some View {
        List {
            ForEach(viewModel.filteredCryptocurrencies) { crypto in
                cryptocurrencyRowView(for: crypto)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        if crypto == viewModel.filteredCryptocurrencies.last {
                            Task { await viewModel.loadMoreCryptocurrencies() }
                        }
                    }
            }
            
            if viewModel.isLoading {
                loadingIndicatorView
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Cryptocurrency Row View
    private func cryptocurrencyRowView(for crypto: Cryptocurrency) -> some View {
        CryptocurrencyRowView(
            cryptocurrency: crypto,
            isFavorite: viewModel.isFavorite(crypto),
            onFavoriteToggle: { viewModel.toggleFavorite(crypto) },
            onTap: { coordinator.navigateToDetail(crypto) }
        )
    }
    
    // MARK: - Loading Indicator View
    private var loadingIndicatorView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            Spacer()
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

