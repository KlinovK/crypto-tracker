//
//  FavoritesListView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct FavoritesListView: View {
    
    @ObservedObject var viewModel: FavoritesListViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                if viewModel.isLoading && viewModel.favoriteCryptocurrencies.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                } else if let errorMessage = viewModel.errorMessage, viewModel.favoriteCryptocurrencies.isEmpty {
                    ErrorView(message: errorMessage) {
                        Task { await viewModel.loadFavorites() }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if viewModel.favoriteCryptocurrencies.isEmpty {
                    EmptyStateView(
                        message:
                            "No favorite cryptocurrencies yet"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(viewModel.favoriteCryptocurrencies) { crypto in
                            CryptocurrencyRowView(
                                cryptocurrency: crypto,
                                isFavorite: true,
                                onFavoriteToggle: { viewModel.removeFavorite(crypto) },
                                onTap: { coordinator.navigateToDetail(crypto) }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                    .refreshable {
                        await viewModel.refreshFavorites()
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadFavorites()
            }
        }
    }
}
