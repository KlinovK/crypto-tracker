//
//  TabBarViewModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation

@MainActor
final class TabBarViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var selectedTab: Int = 0
    @Published var showOfflineMessage: Bool = false
    @Published private(set) var isOffline: Bool = false

    let listViewModel: CryptocurrencyListViewModel
    let favoritesViewModel: FavoritesListViewModel

    private let preloader: PreloaderProtocol
    private let priceMonitor: PriceMonitorProtocol

    init(
        listViewModel: CryptocurrencyListViewModel,
        favoritesViewModel: FavoritesListViewModel,
        preloader: PreloaderProtocol,
        priceMonitor: PriceMonitorProtocol
    ) {
        self.listViewModel = listViewModel
        self.favoritesViewModel = favoritesViewModel
        self.preloader = preloader
        self.priceMonitor = priceMonitor

        monitorConnectivityAndStartServices()
    }

    /// Monitors network changes and controls preloading and monitoring tasks.
    private func monitorConnectivityAndStartServices() {
        Task {
            var hasStartedServices = false

            for await isConnected in NetworkMonitor.shared.$isConnected.values {
                isOffline = !isConnected
                showOfflineMessage = !isConnected

                if isConnected {
                    if !hasStartedServices {
                        isLoading = true
                        preloader.start(fromPage: 1)
                        priceMonitor.start()
                        isLoading = false
                        hasStartedServices = true
                    } else {
                        // Reconnect case
                        preloader.start(fromPage: 1)
                        priceMonitor.start()
                    }
                } else {
                    priceMonitor.stop()
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    showOfflineMessage = false
                }
            }
        }
    }
}
