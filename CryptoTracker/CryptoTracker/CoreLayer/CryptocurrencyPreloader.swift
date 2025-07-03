//
//  CryptocurrencyPreloader.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

protocol PreloaderProtocol {
    func start(fromPage: Int)
    func stop()
}

final class CryptocurrencyPreloader: PreloaderProtocol {
    private var task: Task<Void, Never>?
    private let delay: UInt64
    private let networkService: NetworkServiceProtocol

    init(
        networkService: NetworkServiceProtocol,
        delay: UInt64 = 60 * 1_000_000_000
    ) {
        self.networkService = networkService
        self.delay = delay
    }

    func start(fromPage: Int = 1) {
        task?.cancel()
        task = Task {
            var page = fromPage
            while !Task.isCancelled {
                do {
                    let cryptos = try await networkService.fetchCryptocurrencies(page: page, sortBy: .marketCap)

                    if cryptos.isEmpty {
                        print("🛑 Page \(page) returned empty. Stopping preloader.")
                        break
                    }

                    DataStorageService.shared.save(cryptos)
                    print("✅ Preloaded Page \(page) saved \(cryptos.count) items.")
                    page += 1
                } catch {
                    print("❌ Preloader failed on page \(page): \(type(of: error)) - \(error.localizedDescription)")
                    page += 1
                }

                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
