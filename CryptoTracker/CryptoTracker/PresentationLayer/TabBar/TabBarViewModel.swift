//
//  TabBarViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation
import UserNotifications

@MainActor
final class TabBarViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var selectedTab: Int = 0
    @Published var showOfflineMessage: Bool = false
    @Published private(set) var isOffline: Bool = false

    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesServiceProtocol

    let listViewModel: CryptocurrencyListViewModel
    let favoritesViewModel: FavoritesListViewModel

    private let monitor = NetworkMonitor.shared
    private var previousConnectionState: Bool = true
    private var preloadTask: Task<Void, Never>?
    private var priceCheckTask: Task<Void, Never>?

    init(
        networkService: NetworkServiceProtocol,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.networkService = networkService
        self.favoritesService = favoritesService

        self.listViewModel = CryptocurrencyListViewModel(
            networkService: networkService,
            favoritesService: favoritesService
        )

        self.favoritesViewModel = FavoritesListViewModel(
            networkService: networkService,
            favoritesService: favoritesService
        )

        observeNetwork()
        startPreloading(fromPage: 1)
    }

    private func observeNetwork() {
        Task {
            for await isConnected in monitor.$isConnected.values {
                await MainActor.run {
                    if isConnected != previousConnectionState {
                        previousConnectionState = isConnected
                        isOffline = !isConnected

                        if isConnected {
                            preloadTask?.cancel()
                            startPreloading(fromPage: 1)
                            startPriceChangeMonitoring()
                        } else {
                            stopPriceChangeMonitoring()
                            showOfflineMessage = true

                            Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                await MainActor.run {
                                    self.showOfflineMessage = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func startPreloading(fromPage pageStart: Int = 1) {
        preloadTask?.cancel()

        preloadTask = Task {
            var page = pageStart

            while !Task.isCancelled {
                if !monitor.isConnected {
                    await MainActor.run {
                        isOffline = true
                        if page == pageStart {
                            isLoading = false
                        }
                    }

                    try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                    continue
                }

                await preload(page: page)

                if page == pageStart {
                    await MainActor.run {
                        isLoading = false
                        isOffline = false
                    }
                }

                page += 1
                try? await Task.sleep(nanoseconds: 100 * 1_000_000_000)
            }
        }
    }

    private func preload(page: Int) async {
        do {
            let newCryptos = try await networkService.fetchCryptocurrencies(page: page, sortBy: .marketCap)
            DataStorageService.shared.save(newCryptos)
            print("✅ Successfully preloaded page \(page) with \(newCryptos.count) cryptocurrencies.")
        } catch {
            print("❌ Failed to preload page \(page): \(error.localizedDescription)")
        }
    }
    
    private func startPriceChangeMonitoring() {
        priceCheckTask?.cancel()

        priceCheckTask = Task {
            while !Task.isCancelled {
                await checkFavoritePriceChangesAndNotify()
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            }
        }
    }

    private func stopPriceChangeMonitoring() {
        priceCheckTask?.cancel()
        priceCheckTask = nil
    }
    
    func checkFavoritePriceChangesAndNotify() async {
        let favoriteIDs = favoritesService.getFavorites()
        guard !favoriteIDs.isEmpty else { return }

        let oldFavotireCryptos = DataStorageService.shared.getFavoriteCryptocurrencies(ids: favoriteIDs)

        // Convert to dictionary for fast lookup
        let oldPriceMap: [String: Double] = Dictionary(uniqueKeysWithValues: oldFavotireCryptos.map {
            ($0.id, $0.currentPrice)
        })

        do {
            // Fetch updated prices from network
            let updatedCryptos = try await networkService.fetchCryptocurrenciesByIds(ids: favoriteIDs)

            for crypto in updatedCryptos {
                guard let oldPrice = oldPriceMap[crypto.id], oldPrice > 0 else { continue }

                let newPrice = crypto.currentPrice
                let percentageChange = abs((newPrice - oldPrice) / oldPrice)

                if percentageChange >= 0.01 {
                    sendLocalNotification(
                        title: "\(crypto.name) Price Alert",
                        body: "\(crypto.symbol.uppercased()) changed by \(String(format: "%.2f", percentageChange * 100))%"
                    )
                }
            }

        } catch {
            print("❌ Failed to fetch updated prices: \(error.localizedDescription)")
        }
    }
    
    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Show notification immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

}
