//
//  FavoritesListViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

class FavoritesListViewModel: ObservableObject {
    
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var favoriteCryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var showingSearch = false
    @Published var sortOption: SortOption = .marketCap
    
    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesService
    private var currentPage = 1
    
    init(networkService: NetworkServiceProtocol, favoritesService: FavoritesService) {
        self.networkService = networkService
        self.favoritesService = favoritesService
    }
    
    @MainActor
    func loadFavorites() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let favoriteIds = favoritesService.getFavorites()
            if favoriteIds.isEmpty {
                favoriteCryptocurrencies = []
                isLoading = false
                return
            }
            
            let cryptos = try await networkService.fetchCryptocurrencies(page: 1, sortBy: sortOption)
            cryptocurrencies = cryptos
            currentPage = 1
            
            favoriteCryptocurrencies = cryptocurrencies.filter { favoriteIds.contains($0.id) }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
