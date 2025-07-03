//
//  FavoritesListViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

/// ViewModel responsible for managing the list of favorite cryptocurrencies.
/// Handles data loading, local caching, network fallback, and sorting.
@MainActor
class FavoritesListViewModel: ObservableObject {
    
    // MARK: - Published Properties

    /// All cryptocurrencies loaded from the API or cache.
    @Published var cryptocurrencies: [Cryptocurrency] = []

    /// The user's favorite cryptocurrencies filtered from the main list.
    @Published var favoriteCryptocurrencies: [Cryptocurrency] = []

    /// Indicates whether data is currently being loaded.
    @Published var isLoading = false

    /// An error message to display in case of a failure.
    @Published var errorMessage: String?

    /// The current search text for filtering.
    @Published var searchText = ""

    /// Whether the search UI is visible.
    @Published var showingSearch = false

    /// The current sort option applied to the favorites list.
    @Published var sortOption: SortOption = .marketCap

    // MARK: - Dependencies

    /// The service used to fetch cryptocurrency data.
    private let networkService: NetworkServiceProtocol

    /// The service used to manage user's favorite cryptocurrencies.
    private let favoritesService: FavoritesServiceProtocol

    /// The current pagination page.
    private var currentPage = 1

    // MARK: - Initialization

    /// Initializes the view model with necessary services.
    /// - Parameters:
    ///   - networkService: Service for API calls.
    ///   - favoritesService: Service for managing favorites.
    init(networkService: NetworkServiceProtocol, favoritesService: FavoritesServiceProtocol) {
        self.networkService = networkService
        self.favoritesService = favoritesService
    }

    // MARK: - Data Loading

    /// Loads the user's favorite cryptocurrencies from API or local cache.
    /// Automatically filters out non-favorite entries.
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
                
                // Cache result locally
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

    /// Attempts to load cached data and filter by user's favorites.
    /// - Parameter favoriteIds: The list of favorite cryptocurrency IDs.
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

    /// Refreshes the favorites list by reloading data.
    func refreshFavorites() async {
        await loadFavorites()
    }

    // MARK: - Favorites Management

    /// Removes a cryptocurrency from the favorites list.
    /// - Parameter cryptocurrency: The cryptocurrency to remove.
    func removeFavorite(_ cryptocurrency: Cryptocurrency) {
        favoritesService.removeFromFavorites(cryptocurrency)
        favoriteCryptocurrencies.removeAll { $0.id == cryptocurrency.id }
    }
}
