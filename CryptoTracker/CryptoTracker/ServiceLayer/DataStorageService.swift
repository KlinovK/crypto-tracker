//
//  DataStorageService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation
import CoreData

/// A Core Data service for managing cryptocurrency data.
final class DataStorageService {
    
    // MARK: - Singleton Instance
    
    static let shared = DataStorageService()

    // MARK: - Core Data Stack
    
    let container: NSPersistentContainer

    /// Shortcut to main view context.
    var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization
    
    /// Initializes the persistent container with optional in-memory store (for testing).
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CryptoTrackerDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("❌ Failed to load persistent stores: \(error.localizedDescription)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Saving

    /// Saves changes in the main context if any exist.
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Fetching

    /// Fetches all stored cryptocurrencies.
    func fetchCryptocurrencies() -> [Cryptocurrency] {
        let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
        
        do {
            return try context.fetch(request).compactMap(Cryptocurrency.init)
        } catch {
            print("❌ Failed to fetch cryptocurrencies: \(error.localizedDescription)")
            return []
        }
    }

    /// Returns the count of cryptocurrency entities matching the given predicate.
    func countCryptocurrencies(with predicate: NSPredicate? = nil) throws -> Int {
        let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
        request.predicate = predicate
        return try context.count(for: request)
    }

    // MARK: - Deleting

    /// Deletes a given cryptocurrency entity from the main context.
    func deleteCryptocurrency(_ object: CryptocurrencyEntity) {
        context.delete(object)
    }

    // MARK: - Saving Bulk Data

    /// Saves or updates a batch of cryptocurrencies in the background.
    func save(_ cryptocurrencies: [Cryptocurrency]) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            for crypto in cryptocurrencies {
                let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", crypto.id)
                request.fetchLimit = 1

                let entity = (try? context.fetch(request).first) ?? CryptocurrencyEntity(context: context)
                crypto.update(entity)
            }

            do {
                try context.save()
            } catch {
                print("❌ Failed to save cryptocurrencies: \(error.localizedDescription)")
            }
        }
    }
    
    func getFavoriteCryptocurrencies(ids: [String]) -> [Cryptocurrency] {
        let request: NSFetchRequest<CryptocurrencyEntity> = CryptocurrencyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { Cryptocurrency(entity: $0) }
        } catch {
            print("❌ Failed to fetch favorite cryptocurrencies: \(error.localizedDescription)")
            return []
        }
    }
}
