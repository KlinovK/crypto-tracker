//
//  CryptocurrencyListViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

@MainActor
class CryptocurrencyListViewModel: ObservableObject {
    
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var filteredCryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var searchText = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    await filterAndSortCryptocurrencies()
                }
            }
        }
    }
    
    @Published var sortOption: SortOption = .marketCap {
        didSet {
            Task {
                await filterAndSortCryptocurrencies()
            }
        }
    }
    
    @Published var showingFavoritesOnly = false {
        didSet {
            Task {
                await filterAndSortCryptocurrencies()
            }
        }
    }
    
    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesService
    private var currentPage = 1
    private var searchTask: Task<Void, Never>?
    private var favoritesObservationTask: Task<Void, Never>?
    
    init(networkService: NetworkServiceProtocol, favoritesService: FavoritesService) {
        self.networkService = networkService
        self.favoritesService = favoritesService
        
        setupFavoritesObservation()
    }
    
    deinit {
        searchTask?.cancel()
        favoritesObservationTask?.cancel()
    }
    
    func loadCryptocurrencies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let cryptos = try await networkService.fetchCryptocurrencies(page: 1, sortBy: sortOption)
            cryptocurrencies = cryptos
            currentPage = 1
            await filterAndSortCryptocurrencies()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
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
    
    func refreshData() async {
        await loadCryptocurrencies()
    }
    
    // NEW: Method to apply sorting without reloading all data
    func applySorting(_ newSortOption: SortOption) async {
        guard sortOption != newSortOption else { return }
        
        sortOption = newSortOption
        
        // If you want server-side sorting for new data loads, reload
        // Otherwise, just apply client-side sorting to existing data
        if cryptocurrencies.isEmpty {
            await loadCryptocurrencies()
        } else {
            // For immediate feedback, apply client-side sorting first
            await filterAndSortCryptocurrencies()
            
            // Then optionally reload with server-side sorting in background
            Task {
                await loadCryptocurrencies()
            }
        }
    }
    
    private func setupFavoritesObservation() {
        favoritesObservationTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await _ in self.favoritesService.favoritesDidChange {
                await self.filterAndSortCryptocurrencies()
            }
        }
    }
    
    // CHANGED: Renamed and enhanced to handle both filtering and sorting
    private func filterAndSortCryptocurrencies() async {
        var filtered = cryptocurrencies
        
        // Apply favorites filter
        if showingFavoritesOnly {
            filtered = filtered.filter { favoritesService.isFavorite($0) }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply client-side sorting (as backup/immediate feedback)
        filtered = sortCryptocurrencies(filtered, by: sortOption)
        
        filteredCryptocurrencies = filtered
    }
    
    // NEW: Client-side sorting implementation
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
    
    func isFavorite(_ crypto: Cryptocurrency) -> Bool {
        favoritesService.isFavorite(crypto)
    }
    
    func toggleFavorite(_ crypto: Cryptocurrency) {
        if favoritesService.isFavorite(crypto) {
            favoritesService.removeFromFavorites(crypto)
        } else {
            favoritesService.addToFavorites(crypto)
        }
    }
}
