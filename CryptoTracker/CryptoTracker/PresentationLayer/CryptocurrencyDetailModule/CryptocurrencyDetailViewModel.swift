//
//  CryptocurrencyDetailViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

/// ViewModel responsible for managing the detail view of a specific cryptocurrency,
/// including price history loading and favorite status toggling.
@MainActor
class CryptocurrencyDetailViewModel: ObservableObject {

    // MARK: - Dependencies

    /// Service responsible for fetching network data.
    private let networkService: NetworkServiceProtocol

    /// Service responsible for managing favorite cryptocurrencies.
    private let favoritesService: FavoritesServiceProtocol

    // MARK: - Properties

    /// The cryptocurrency being displayed.
    var cryptocurrency: Cryptocurrency

    /// Historical price data used for charting.
    @Published var priceHistory: [Double] = []

    /// The currently selected time period for price history.
    @Published var selectedTimePeriod: TimePeriod = .oneWeek

    /// Indicates whether the view is currently loading data.
    @Published var isLoading = false

    /// An optional error message to show in the UI when something goes wrong.
    @Published var errorMessage: String?

    /// Internal cache of favorite cryptocurrency IDs (unused in current implementation).
    private var favoriteIds = Set<String>()

    /// Caches price history by time period to avoid unnecessary network calls.
    private var priceHistoryCache: [TimePeriod: [Double]] = [:]

    // MARK: - Initialization

    /// Initializes the detail view model with the required dependencies.
    /// - Parameters:
    ///   - cryptocurrency: The cryptocurrency to display.
    ///   - networkService: The service used to fetch network data.
    ///   - favoritesService: The service used to manage favorites.
    init(
        cryptocurrency: Cryptocurrency,
        networkService: NetworkServiceProtocol,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.cryptocurrency = cryptocurrency
        self.networkService = networkService
        self.favoritesService = favoritesService
    }

    // MARK: - Favorites

    /// Toggles the favorite status of the current cryptocurrency.
    func toggleFavorite() {
        if favoritesService.isFavorite(cryptocurrency) {
            favoritesService.removeFromFavorites(cryptocurrency)
        } else {
            favoritesService.addToFavorites(cryptocurrency)
        }
    }

    /// Returns whether the current cryptocurrency is marked as a favorite.
    /// - Returns: A Boolean indicating the favorite status.
    func isFavorite() -> Bool {
        favoritesService.isFavorite(cryptocurrency)
    }

    // MARK: - Price History

    /// Loads the price history for the current cryptocurrency and selected time period.
    ///
    /// If cached data is available, it uses that. Otherwise, it attempts to fetch data
    /// from the network. If offline or an error occurs, it updates the error message.
    func loadPriceHistory() async {
        if let cached = priceHistoryCache[selectedTimePeriod] {
            self.priceHistory = cached
            return
        }

        isLoading = true
        errorMessage = nil

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
