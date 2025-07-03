//
//  PriceChangeMonitor.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

protocol PriceMonitorProtocol {
    func start()
    func stop()
}

/// A background service that periodically checks for significant price changes in favorite cryptocurrencies
/// and sends local notifications when a price changes by more than 1%.
final class PriceChangeMonitor: PriceMonitorProtocol {
    
    // MARK: - Properties
    
    /// The background task responsible for monitoring prices.
    private var task: Task<Void, Never>?
    
    /// The delay between successive price checks (in nanoseconds).
    private let delay: UInt64
    
    /// Service used to fetch current cryptocurrency data.
    private let networkService: NetworkServiceProtocol
    
    /// Service used to access the user's favorite cryptocurrencies.
    private let favoritesService: FavoritesServiceProtocol
    
    /// Service used to send notifications to the user.
    private let notifier: NotificationServiceProtocol

    // MARK: - Initialization
    
    /// Initializes a new instance of `PriceChangeMonitor`.
    ///
    /// - Parameters:
    ///   - networkService: The service responsible for fetching updated cryptocurrency data.
    ///   - favoritesService: The service used to retrieve user-selected favorite cryptocurrencies.
    ///   - notifier: The service responsible for delivering notifications to the user.
    ///   - delay: The time between each monitoring cycle in nanoseconds. Defaults to 5 minutes.
    init(
        networkService: NetworkServiceProtocol,
        favoritesService: FavoritesServiceProtocol,
        notifier: NotificationServiceProtocol,
        delay: UInt64 = 300 * 1_000_000_000
    ) {
        self.networkService = networkService
        self.favoritesService = favoritesService
        self.notifier = notifier
        self.delay = delay
    }

    // MARK: - Public Methods

    /// Starts monitoring for significant price changes in the user's favorite cryptocurrencies.
    /// This creates a background task that runs periodically at the configured interval.
    func start() {
        task?.cancel()
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: delay)
                await checkPrices()
            }
        }
    }

    /// Stops the ongoing price monitoring task, if any.
    func stop() {
        task?.cancel()
        task = nil
    }

    // MARK: - Private Methods

    /// Checks the current prices of favorite cryptocurrencies and sends notifications
    /// if a price has changed by more than 1% compared to the last saved price.
    private func checkPrices() async {
        let ids = favoritesService.getFavorites()
        let oldData = DataStorageService.shared.getFavoriteCryptocurrencies(ids: ids)
        let oldMap = Dictionary(uniqueKeysWithValues: oldData.map { ($0.id, $0.currentPrice) })

        do {
            let updated = try await networkService.fetchCryptocurrenciesByIds(ids: ids)
            for crypto in updated {
                guard let oldPrice = oldMap[crypto.id], oldPrice > 0 else { continue }
                let change = abs((crypto.currentPrice - oldPrice) / oldPrice)
                
                // Notify user if the price has changed by 5% or more
                if change >= 0.05 {
                    let msg = String(format: "%.2f%%", change * 100)
                    notifier.send(
                        title: "\(crypto.name) Price Alert",
                        body: "\(crypto.symbol.uppercased()) changed by \(msg)"
                    )
                }
            }
        } catch {
            print("Price check failed: \(error.localizedDescription)")
        }
    }
}
