//
//  MainViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation

@MainActor
final class MainViewModel: ObservableObject {
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
    private var preloadTask: Task<Void, Never>? // Tracks preloading task

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
                        } else {
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
        preloadTask?.cancel() // Cancel old task

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
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            }
        }
    }

    private func preload(page: Int) async {
        do {
            let cryptos = try await networkService.fetchCryptocurrencies(page: page, sortBy: .marketCap)
            DataStorageService.shared.save(cryptos)
            print("✅ Successfully preloaded page \(page) with \(cryptos.count) cryptocurrencies.")
        } catch {
            print("❌ Failed to preload page \(page): \(error.localizedDescription)")
        }
    }
}
