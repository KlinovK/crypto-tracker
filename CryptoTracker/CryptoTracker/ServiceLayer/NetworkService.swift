//
//  NetworkService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

protocol NetworkServiceProtocol {
    func fetchCryptocurrencies(page: Int, sortBy: SortOption) async throws -> [Cryptocurrency]
    func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency]
    func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint]
}

class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchCryptocurrencies(page: Int = 1, sortBy: SortOption = .marketCap) async throws -> [Cryptocurrency] {
        let url = URL(string: "\(baseURL)/coins/markets?vs_currency=usd&order=\(sortBy.rawValue)&per_page=50&page=\(page)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode([Cryptocurrency].self, from: data)
    }
    
    func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "\(baseURL)/coins/markets?vs_currency=usd&ids=\(encodedQuery)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode([Cryptocurrency].self, from: data)
    }
    
    func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint] {
        let url = URL(string: "\(baseURL)/coins/\(coinId)/market_chart?vs_currency=usd&days=\(days)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let prices = json?["prices"] as? [[Double]] ?? []
        
        return prices.compactMap { priceData in
            guard priceData.count >= 2 else { return nil }
            let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
            let price = priceData[1]
            return PricePoint(timestamp: timestamp, price: price)
        }
    }
}

