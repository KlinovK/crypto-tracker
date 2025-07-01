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
        // Debug: Print the URL being requested
        let urlString = "\(baseURL)/coins/\(coinId)/market_chart?vs_currency=usd&days=\(days)"
        print("🔍 Requesting URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Debug: Print response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response Status: \(httpResponse.statusCode)")
                print("📡 Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response")
                throw NetworkError.invalidResponse
            }
            
            // Check for specific error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Success response: \(httpResponse.statusCode)")
            case 400:
                print("❌ Bad Request (400) - Check coinId: '\(coinId)' and days: '\(days)'")
                throw NetworkError.invalidResponse
            case 404:
                print("❌ Not Found (404) - Coin '\(coinId)' may not exist")
                throw NetworkError.invalidResponse
            case 429:
                print("❌ Rate Limited (429) - Too many requests")
                throw NetworkError.invalidResponse
            default:
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                throw NetworkError.invalidResponse
            }
            
            // Debug: Print response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response Data (first 200 chars): \(String(responseString.prefix(200)))")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let prices = json?["prices"] as? [[Double]] ?? []
                
                print("📊 Found \(prices.count) price points")
                
               
                let pricePoints = prices.enumerated().compactMap { (index, priceData) -> PricePoint? in
                    guard priceData.count >= 2 else { return nil }
                    let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
                    let price = priceData[1]
                    
                    // Validate the price is reasonable
                    guard price > 0 && price.isFinite else { return nil }
                    
                    return PricePoint(index: index, price: price, timestamp: timestamp)
                }
                print("✅ Processed \(pricePoints.count) valid price points")
                
                // Sort by timestamp to ensure proper chart rendering
                return pricePoints.sorted { ($0.timestamp ?? .now) < ($1.timestamp ?? .now) }
                
            } catch {
                print("❌ JSON Parsing Error: \(error)")
                throw NetworkError.decodingError
            }
            
        } catch {
            print("❌ Network Error: \(error)")
            throw error
        }
    }
}

