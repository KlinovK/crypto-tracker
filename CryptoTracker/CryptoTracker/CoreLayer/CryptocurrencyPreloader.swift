//
//  CryptocurrencyPreloader.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

/// A protocol that defines the interface for a data preloader.
protocol PreloaderProtocol {
    /// Starts the preloading process from the specified page.
    /// - Parameter fromPage: The page number to start preloading from.
    func start(fromPage: Int)

    /// Stops the ongoing preloading process.
    func stop()
}

/// A background task that continuously fetches and stores cryptocurrency data from the network.
final class CryptocurrencyPreloader: PreloaderProtocol {
    /// The currently running background task, if any.
    private var task: Task<Void, Never>?

    /// The delay in nanoseconds before starting and between preloading iterations.
    private let delay: UInt64

    /// The network service used to fetch cryptocurrency data.
    private let networkService: NetworkServiceProtocol

    /// Initializes a new `CryptocurrencyPreloader`.
    /// - Parameters:
    ///   - networkService: A service that conforms to `NetworkServiceProtocol` used to fetch data.
    ///   - delay: The delay between each preload attempt, in nanoseconds (default is 60 seconds).
    init(
        networkService: NetworkServiceProtocol,
        delay: UInt64 = 60 * 1_000_000_000
    ) {
        self.networkService = networkService
        self.delay = delay
    }

    /// Starts preloading cryptocurrency data in the background.
    /// - Parameter fromPage: The initial page to start preloading from (default is 1).
    func start(fromPage: Int = 1) {
        // Cancel any existing task before starting a new one
        task?.cancel()
        task = Task {
            // Delay before first preload
            try? await Task.sleep(nanoseconds: delay)

            var page = fromPage
            while !Task.isCancelled {
                do {
                    // Fetch cryptocurrencies from the given page
                    let cryptos = try await networkService.fetchCryptocurrencies(page: page, sortBy: .marketCap)

                    // Stop if no data is returned
                    if cryptos.isEmpty {
                        print("🛑 Page \(page) returned empty. Stopping preloader.")
                        break
                    }

                    // Save the fetched data to persistent storage
                    DataStorageService.shared.save(cryptos)
                    print("✅ Preloaded Page \(page) saved \(cryptos.count) items.")
                    page += 1
                } catch {
                    print("❌ Preloader failed on page \(page): \(type(of: error)) - \(error.localizedDescription)")
                    page += 1
                }

                // Add delay before next preload (optional if only one-time delay is needed)
                 try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    /// Stops the ongoing preload task.
    func stop() {
        task?.cancel()
        task = nil
    }
}
