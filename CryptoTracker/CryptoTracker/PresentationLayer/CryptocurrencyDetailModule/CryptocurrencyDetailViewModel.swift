//
//  CryptocurrencyDetailViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

@MainActor
class CryptocurrencyDetailViewModel: ObservableObject {

    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesServiceProtocol

    var cryptocurrency: Cryptocurrency
    @Published var priceHistory: [Double] = []
    @Published var selectedTimePeriod: TimePeriod = .oneWeek
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var favoriteIds = Set<String>()
    private var priceHistoryCache: [TimePeriod: [Double]] = [:]

    init(cryptocurrency: Cryptocurrency, networkService: NetworkServiceProtocol, favoritesService: FavoritesServiceProtocol) {
        self.cryptocurrency = cryptocurrency
        self.networkService = networkService
        self.favoritesService = favoritesService
    }

    func toggleFavorite() {
        if favoritesService.isFavorite(cryptocurrency) {
            favoritesService.removeFromFavorites(cryptocurrency)
        } else {
            favoritesService.addToFavorites(cryptocurrency)
        }
    }

    func isFavorite() -> Bool {
        favoritesService.isFavorite(cryptocurrency)
    }

    func loadPriceHistory() async {
        if let cached = priceHistoryCache[selectedTimePeriod] {
            self.priceHistory = cached
            return
        }

        isLoading = true
        errorMessage = nil

        // 🔌 Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            errorMessage = "No internet connection. Please try again when you're back online."
            priceHistory = []
            isLoading = false
            return
        }

        do {
            let pricePoints = try await networkService.fetchPriceHistory(
                coinId: cryptocurrency.id,
                days: selectedTimePeriod.rawValue
            )

            let prices = pricePoints.map { $0.price }
            priceHistory = prices
            priceHistoryCache[selectedTimePeriod] = prices

        } catch {
            print("❌ Failed to load price history: \(error.localizedDescription)")
            errorMessage = "Failed to fetch price history: \(error.localizedDescription)"
            priceHistory = []
        }

        isLoading = false
    }
}
