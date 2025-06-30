//
//  FavoritesService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

protocol FavoritesServiceProtocol {
    func addToFavorites(_ crypto: Cryptocurrency)
    func removeFromFavorites(_ crypto: Cryptocurrency)
    func isFavorite(_ crypto: Cryptocurrency) -> Bool
    func getFavorites() -> [String]
}

class FavoritesService: FavoritesServiceProtocol, ObservableObject {
    @Published var favoriteIds: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "FavoriteCryptocurrencies"
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.insert(crypto.id)
        saveFavorites()
    }
    
    func removeFromFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.remove(crypto.id)
        saveFavorites()
    }
    
    func isFavorite(_ crypto: Cryptocurrency) -> Bool {
        favoriteIds.contains(crypto.id)
    }
    
    func getFavorites() -> [String] {
        Array(favoriteIds)
    }
    
    private func saveFavorites() {
        userDefaults.set(Array(favoriteIds), forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        let favorites = userDefaults.stringArray(forKey: favoritesKey) ?? []
        favoriteIds = Set(favorites)
    }
}

extension FavoritesService {
    var favoritesDidChange: AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continuation.yield(())
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
