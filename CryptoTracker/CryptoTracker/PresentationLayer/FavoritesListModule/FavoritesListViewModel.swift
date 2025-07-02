//
//  FavoritesListViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

@MainActor
class FavoritesListViewModel: ObservableObject {
    
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var favoriteCryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var showingSearch = false
    @Published var sortOption: SortOption = .marketCap

    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesServiceProtocol
    private var currentPage = 1

    init(networkService: NetworkServiceProtocol, favoritesService: FavoritesServiceProtocol) {
        self.networkService = networkService
        self.favoritesService = favoritesService
    }

    func loadFavorites() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let isConnected = NetworkMonitor.shared.isConnected
        let favoriteIds = favoritesService.getFavorites()

        if favoriteIds.isEmpty {
            favoriteCryptocurrencies = []
            isLoading = false
            return
        }

        if isConnected {
            do {
                let cryptos = try await networkService.fetchCryptocurrencies(page: 1, sortBy: sortOption)
                cryptocurrencies = cryptos
                currentPage = 1
                
                // Cache result
                DataStorageService.shared.save(cryptos)

                favoriteCryptocurrencies = cryptocurrencies
                    .filter { favoriteIds.contains($0.id) }
                print("✅ Loaded favorites from API and saved to Core Data.")
            } catch {
                errorMessage = error.localizedDescription
                print("❌ API fetch failed: \(error.localizedDescription)")
                fallbackToLocalFavorites(favoriteIds: favoriteIds)
            }
        } else {
            fallbackToLocalFavorites(favoriteIds: favoriteIds)
        }

        isLoading = false
    }

    private func fallbackToLocalFavorites(favoriteIds: [String]) {
        let cached = DataStorageService.shared.fetchCryptocurrencies()
        if !cached.isEmpty {
            cryptocurrencies = cached
            favoriteCryptocurrencies = cached.filter { favoriteIds.contains($0.id) }
            print("📴 Offline: Loaded favorites from Core Data.")
        } else {
            errorMessage = "No internet connection and no cached data available."
            print("❌ Offline and no local favorites available.")
        }
    }

    func refreshFavorites() async {
        await loadFavorites()
    }

    func removeFavorite(_ cryptocurrency: Cryptocurrency) {
        favoritesService.removeFromFavorites(cryptocurrency)
        favoriteCryptocurrencies.removeAll { $0.id == cryptocurrency.id }
    }

    private func sortCryptocurrencies(_ cryptos: [Cryptocurrency], by sortOption: SortOption) -> [Cryptocurrency] {
        switch sortOption {
        case .marketCap:
            return cryptos.sorted { ($0.marketCap ?? 0) > ($1.marketCap ?? 0) }
        case .price:
            return cryptos.sorted { $0.currentPrice > $1.currentPrice }
        case .priceAsc:
            return cryptos.sorted { $0.currentPrice < $1.currentPrice }
        case .volume:
            return cryptos.sorted { ($0.totalVolume ?? 0) > ($1.totalVolume ?? 0) }
        case .priceChange:
            return cryptos.sorted { ($0.priceChangePercentage24h ?? 0) > ($1.priceChangePercentage24h ?? 0) }
        }
    }
}
