//
//  DataStorageService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation
import CoreData

final class DataStorageService {

    // MARK: - Singleton
    static let shared = DataStorageService()

    // MARK: - Properties
    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initializer
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CryptoTrackerDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Failed to load persistent stores: \(error.localizedDescription)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Public API

    func saveContext() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func fetchCryptocurrencies() -> [Cryptocurrency] {
        let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { Cryptocurrency(entity: $0) }
        } catch {
            print("❌ Core Data fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    func countCryptocurrencies(with predicate: NSPredicate? = nil) throws -> Int {
        let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
        request.predicate = predicate
        return try context.count(for: request)
    }

    func deleteCryptocurrency(_ object: CryptocurrencyEntity) {
        context.delete(object)
    }

    func save(_ cryptocurrencies: [Cryptocurrency]) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            for crypto in cryptocurrencies {
                let fetchRequest: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", crypto.id)
                fetchRequest.fetchLimit = 1

                let existingEntity = try? context.fetch(fetchRequest).first
                let entity = existingEntity ?? CryptocurrencyEntity(context: context)

                entity.id = crypto.id
                entity.name = crypto.name
                entity.symbol = crypto.symbol
                entity.image = crypto.image
                entity.currentPrice = crypto.currentPrice
                entity.marketCap = crypto.marketCap ?? 0
                entity.totalVolume = crypto.totalVolume ?? 0
                entity.priceChangePercentage = crypto.priceChangePercentage24h ?? 0
                entity.high24h = crypto.high24h ?? 0
                entity.low24h = crypto.low24h ?? 0
                entity.circulatingSupply = crypto.circulatingSupply ?? 0
                entity.maxSupply = crypto.maxSupply ?? 0
            }

            do {
                try context.save()
            } catch {
                print("❌ Failed to save cryptocurrencies to Core Data in background: \(error.localizedDescription)")
            }
        }
    }
}
