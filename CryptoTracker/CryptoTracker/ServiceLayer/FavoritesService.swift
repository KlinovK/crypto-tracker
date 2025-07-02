//
//  FavoritesService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation
import Combine

protocol FavoritesServiceProtocol {
    func addToFavorites(_ crypto: Cryptocurrency)
    func removeFromFavorites(_ crypto: Cryptocurrency)
    func isFavorite(_ crypto: Cryptocurrency) -> Bool
    func getFavorites() -> [String]
    func favoritesDidChangeStream() -> AsyncStream<Void>
}

class FavoritesService: FavoritesServiceProtocol {

    private var changeContinuation: AsyncStream<Void>.Continuation?
    private let changeStream: AsyncStream<Void>

    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "FavoriteCryptocurrencies"

    private var favoriteIds: Set<String> = []

    init() {
        var continuation: AsyncStream<Void>.Continuation?
        self.changeStream = AsyncStream<Void> { cont in
            continuation = cont
        }
        self.changeContinuation = continuation
        loadFavorites()
    }

    func addToFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.insert(crypto.id)
        saveFavorites()
        changeContinuation?.yield()
    }

    func removeFromFavorites(_ crypto: Cryptocurrency) {
        favoriteIds.remove(crypto.id)
        saveFavorites()
        changeContinuation?.yield()
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

    func favoritesDidChangeStream() -> AsyncStream<Void> {
        changeStream
    }
}
