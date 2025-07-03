//
//  FavoritesService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation
import Combine

/// A protocol defining the behavior of a service managing favorite cryptocurrencies.
protocol FavoritesServiceProtocol {
    
    /// Adds a cryptocurrency to the favorites list.
    /// - Parameter crypto: The cryptocurrency to add.
    func addToFavorites(_ crypto: Cryptocurrency)
    
    /// Removes a cryptocurrency from the favorites list.
    /// - Parameter crypto: The cryptocurrency to remove.
    func removeFromFavorites(_ crypto: Cryptocurrency)
    
    /// Checks if a cryptocurrency is marked as a favorite.
    /// - Parameter crypto: The cryptocurrency to check.
    /// - Returns: A Boolean indicating whether the cryptocurrency is a favorite.
    func isFavorite(_ crypto: Cryptocurrency) -> Bool
    
    /// Retrieves the list of favorite cryptocurrency IDs.
    /// - Returns: An array of favorite cryptocurrency IDs.
    func getFavorites() -> [String]
    
    /// Provides a stream that emits an event whenever the favorites list changes.
    /// - Returns: An `AsyncStream<Void>` that signals favorites changes.
    func favoritesDidChangeStream() -> AsyncStream<Void>
}

/// A concrete implementation of `FavoritesServiceProtocol` using `UserDefaults` for persistence.
class FavoritesService: FavoritesServiceProtocol {

    /// The stream continuation for publishing changes.
    private var changeContinuation: AsyncStream<Void>.Continuation?
    
    /// The stream that emits values when favorites change.
    private let changeStream: AsyncStream<Void>

    /// Persistent storage for saving favorite IDs.
    private let userDefaults = UserDefaults.standard
    
    /// Key used to store favorite IDs in UserDefaults.
    private let favoritesKey = "FavoriteCryptocurrencies"

    /// A set of currently favorited cryptocurrency IDs.
    private var favoriteIds: Set<String> = []

    /// Initializes the service and loads saved favorites.
    init() {
        var continuation: AsyncStream<Void>.Continuation?
        self.changeStream = AsyncStream<Void> { cont in
            continuation = cont
        }
        self.changeContinuation = continuation
        loadFavorites()
    }

    /// Adds the specified cryptocurrency to the favorites list.
    /// - Parameter crypto: The cryptocurrency to add.
    func addToFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.insert(crypto.id)
        saveFavorites()
        changeContinuation?.yield()
    }

    /// Removes the specified cryptocurrency from the favorites list.
    /// - Parameter crypto: The cryptocurrency to remove.
    func removeFromFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.remove(crypto.id)
        saveFavorites()
        changeContinuation?.yield()
    }

    /// Checks if the given cryptocurrency is in the favorites list.
    /// - Parameter crypto: The cryptocurrency to check.
    /// - Returns: `true` if the cryptocurrency is a favorite, `false` otherwise.
    func isFavorite(_ crypto: Cryptocurrency) -> Bool {
        favoriteIds.contains(crypto.id)
    }

    /// Returns the list of favorite cryptocurrency IDs.
    /// - Returns: An array of IDs representing favorited cryptocurrencies.
    func getFavorites() -> [String] {
        Array(favoriteIds)
    }

    /// Saves the current favorites list to persistent storage.
    private func saveFavorites() {
        userDefaults.set(Array(favoriteIds), forKey: favoritesKey)
    }

    /// Loads the favorites list from persistent storage.
    private func loadFavorites() {
        let favorites = userDefaults.stringArray(forKey: favoritesKey) ?? []
        favoriteIds = Set(favorites)
    }

    /// Returns a stream that emits a signal whenever the favorites list changes.
    /// - Returns: An `AsyncStream<Void>` that can be awaited or observed.
    func favoritesDidChangeStream() -> AsyncStream<Void> {
        changeStream
    }
}
