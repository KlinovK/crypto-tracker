//
//  CryptocurrencyListViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

/// ViewModel responsible for managing a list of cryptocurrencies,
/// including loading, sorting, searching, filtering by favorites,
/// and observing favorites updates.
@MainActor
class CryptocurrencyListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The full list of cryptocurrencies retrieved from the network or cache.
    @Published var cryptocurrencies: [Cryptocurrency] = []

    /// The filtered and sorted list of cryptocurrencies for display.
    @Published var filteredCryptocurrencies: [Cryptocurrency] = []

    /// Indicates whether data is currently being loaded.
    @Published var isLoading = false

    /// Error message displayed when loading fails.
    @Published var errorMessage: String?

    /// Search text used to filter the list of cryptocurrencies.
    @Published var searchText = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // Debounce
                if !Task.isCancelled {
                    await filterAndSortCryptocurrencies()
                }
            }
        }
    }

    /// The current sort option applied to the cryptocurrency list.
    @Published var sortOption: SortOption = .marketCap {
        didSet {
            Task {
                await filterAndSortCryptocurrencies()
            }
        }
    }

    /// Whether to show only the user's favorite cryptocurrencies.
    @Published var showingFavoritesOnly = false {
        didSet {
            Task {
                await filterAndSortCryptocurrencies()
            }
        }
    }

    // MARK: - Services

    let networkService: NetworkServiceProtocol
    let favoritesService: FavoritesServiceProtocol

    // MARK: - Private Properties

    private var currentPage = 1
    private var searchTask: Task<Void, Never>?
    private var favoritesObservationTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Initializes the ViewModel with dependencies.
    /// - Parameters:
    ///   - networkService: Service used to fetch cryptocurrency data.
    ///   - favoritesService: Service used to manage favorite cryptocurrencies.
    init(
        networkService: NetworkServiceProtocol,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.networkService = networkService
        self.favoritesService = favoritesService

        setupFavoritesObservation()
    }

    deinit {
        searchTask?.cancel()
        favoritesObservationTask?.cancel()
    }

    // MARK: - Data Loading

    /// Loads the initial page of cryptocurrencies from the network or Core Data (if offline).
    func loadCryptocurrencies() async {
        isLoading = true
        errorMessage = nil

        let isConnected = NetworkMonitor.shared.isConnected

        if isConnected {
            do {
                let cryptos = try await networkService.fetchCryptocurrencies(page: 1, sortBy: sortOption)
                cryptocurrencies = cryptos
                currentPage = 1
                DataStorageService.shared.save(cryptos)
                await filterAndSortCryptocurrencies()

                print("✅ Fetched from API and saved to Core Data.")
            } catch {
                errorMessage = error.localizedDescription
                print("❌ API fetch failed: \(error.localizedDescription)")

                let cached = DataStorageService.shared.fetchCryptocurrencies()
                if !cached.isEmpty {
                    cryptocurrencies = cached
                    await filterAndSortCryptocurrencies()
                    print("⚠️ Using cached data from Core Data after API failure.")
                }
            }
        } else {
            let cached = DataStorageService.shared.fetchCryptocurrencies()
            if !cached.isEmpty {
                cryptocurrencies = cached
                currentPage = 1
                await filterAndSortCryptocurrencies()
                print("📴 Offline: Loaded \(cached.count) cryptocurrencies from Core Data.")
            } else {
                errorMessage = "No internet and no local data available."
                print("❌ Offline and no local data.")
            }
        }

        isLoading = false
    }

    /// Loads the next page of cryptocurrencies for pagination.
    func loadMoreCryptocurrencies() async {
        guard !isLoading else { return }

        isLoading = true

        do {
            let cryptos = try await networkService.fetchCryptocurrencies(page: currentPage + 1, sortBy: sortOption)
            cryptocurrencies.append(contentsOf: cryptos)
            currentPage += 1
            await filterAndSortCryptocurrencies()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refreshes the cryptocurrency list from the beginning.
    func refreshData() async {
        await loadCryptocurrencies()
    }

    // MARK: - Sorting

    /// Applies a new sort option and refreshes the list if needed.
    /// - Parameter newSortOption: The new sort option to apply.
    func applySorting(_ newSortOption: SortOption) async {
        guard sortOption != newSortOption else { return }

        sortOption = newSortOption

        if cryptocurrencies.isEmpty {
            await loadCryptocurrencies()
        } else {
            await filterAndSortCryptocurrencies()

            Task {
                await loadCryptocurrencies()
            }
        }
    }

    // MARK: - Favorites

    /// Starts observing changes in favorites and refreshes the list when changes occur.
    private func setupFavoritesObservation() {
        favoritesObservationTask = Task { [weak self] in
            guard let self = self else { return }

            for await _ in self.favoritesService.favoritesDidChangeStream() {
                await self.filterAndSortCryptocurrencies()
            }
        }
    }

    /// Checks if a cryptocurrency is marked as a favorite.
    /// - Parameter crypto: The cryptocurrency to check.
    func isFavorite(_ crypto: Cryptocurrency) -> Bool {
        favoritesService.isFavorite(crypto)
    }

    /// Toggles the favorite status of a cryptocurrency.
    /// - Parameter crypto: The cryptocurrency to toggle.
    func toggleFavorite(_ crypto: Cryptocurrency) {
        if favoritesService.isFavorite(crypto) {
            favoritesService.removeFromFavorites(crypto)
        } else {
            favoritesService.addToFavorites(crypto)
        }
    }

    // MARK: - Filtering & Sorting

    /// Filters and sorts the cryptocurrency list based on search, favorites, and sort option.
    private func filterAndSortCryptocurrencies() async {
        var filtered = cryptocurrencies

        if showingFavoritesOnly {
            filtered = filtered.filter { favoritesService.isFavorite($0) }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }

        filtered = sortCryptocurrencies(filtered, by: sortOption)
        filteredCryptocurrencies = filtered
    }

    /// Sorts cryptocurrencies based on a given sort option.
    /// - Parameters:
    ///   - cryptos: The cryptocurrencies to sort.
    ///   - sortOption: The selected sorting strategy.
    /// - Returns: A sorted array of cryptocurrencies.
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
