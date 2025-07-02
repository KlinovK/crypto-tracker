//
//  CryptocurrencyEntity+CoreDataProperties.swift
//  
//
//  Created by Константин Клинов on 02/07/25.
//
//

import Foundation
import CoreData

extension CryptocurrencyEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CryptocurrencyEntity> {
        return NSFetchRequest<CryptocurrencyEntity>(entityName: "CryptocurrencyEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var symbol: String?
    @NSManaged public var image: String?
    @NSManaged public var currentPrice: Double
    @NSManaged public var marketCap: Double
    @NSManaged public var totalVolume: Double
    @NSManaged public var priceChangePercentage: Double
    @NSManaged public var high24h: Double
    @NSManaged public var low24h: Double
    @NSManaged public var circulatingSupply: Double
    @NSManaged public var maxSupply: Double

}
