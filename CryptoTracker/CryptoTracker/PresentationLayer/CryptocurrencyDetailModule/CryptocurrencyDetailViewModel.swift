//
//  CryptocurrencyDetailViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

@MainActor
class CryptocurrencyDetailViewModel: ObservableObject {
    
    @Published var cryptocurrency: Cryptocurrency
    @Published var priceHistory: [PricePoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimePeriod: TimePeriod = .day
    
    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesService
    
    init(cryptocurrency: Cryptocurrency, networkService: NetworkServiceProtocol, favoritesService: FavoritesService) {
        self.cryptocurrency = cryptocurrency
        self.networkService = networkService
        self.favoritesService = favoritesService
    }
    
    func loadPriceHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            priceHistory = try await networkService.fetchPriceHistory(
                coinId: cryptocurrency.id,
                days: selectedTimePeriod.rawValue
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func isFavorite() -> Bool {
        favoritesService.isFavorite(cryptocurrency)
    }
    
    func toggleFavorite() {
        if favoritesService.isFavorite(cryptocurrency) {
            favoritesService.removeFromFavorites(cryptocurrency)
        } else {
            favoritesService.addToFavorites(cryptocurrency)
        }
    }
}
