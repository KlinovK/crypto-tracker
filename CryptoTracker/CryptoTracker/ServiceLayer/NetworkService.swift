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
    func fetchCryptocurrenciesByIds(ids: [String]) async throws -> [Cryptocurrency] // ← Add this
}

// MARK: - NetworkService
class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    private let session: URLSession
    private let baseURL = "https://api.coingecko.com/api/v3"
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Constants
    private enum Constants {
        static let perPage = 50
        static let currency = "usd"
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Initialization
    init(session: URLSession = .shared, jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
    
    // MARK: - Public Methods
    
    public func fetchCryptocurrencies(page: Int = 1, sortBy: SortOption = .marketCap) async throws -> [Cryptocurrency] {
        let endpoint = "/coins/markets"
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "order", value: sortBy.rawValue),
            URLQueryItem(name: "per_page", value: "\(Constants.perPage)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        let data = try await performRequest(url: url)
        
        return try decode([Cryptocurrency].self, from: data)
    }
    
    public func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency] {
        // Validate input
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw NetworkError.invalidURL
        }
        
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidURL
        }
        
        let endpoint = "/coins/markets"
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "ids", value: encodedQuery)
        ]
        
        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        let data = try await performRequest(url: url)
        
        let cryptocurrencies = try decode([Cryptocurrency].self, from: data)
        
        // Check if search returned results
        guard !cryptocurrencies.isEmpty else {
            throw NetworkError.coinNotFound
        }
        
        return cryptocurrencies
    }
    
    public func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint] {
        // Validate inputs
        guard !coinId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !days.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NetworkError.invalidURL
        }
        
        let endpoint = "/coins/\(coinId)/market_chart"
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "days", value: days)
        ]
        
        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        let data = try await performRequest(url: url)
        
        return try parsePriceHistory(from: data)
    }
    
    public func fetchCryptocurrenciesByIds(ids: [String]) async throws -> [Cryptocurrency] {
        guard !ids.isEmpty else { return [] }

        let endpoint = "/coins/markets"
        let joinedIDs = ids.joined(separator: ",")
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "ids", value: joinedIDs)
        ]

        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        let data = try await performRequestWithRetry(url: url)
        return try decode([Cryptocurrency].self, from: data)
    }
}

// MARK: - Private Methods
private extension NetworkService {
    
    /// Build URL with endpoint and query parameters
    func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: baseURL + endpoint)
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    /// Perform HTTP request with error handling
    func performRequest(url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            try validateHTTPResponse(httpResponse)
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            return data
            
        } catch let error as NetworkError {
            throw error
        } catch {
            // Handle network connectivity and other system errors
            throw NetworkError.invalidResponse
        }
    }
    
    /// Validate HTTP response status codes
    func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            break // Success
        case 400:
            throw NetworkError.invalidResponse
        case 404:
            throw NetworkError.coinNotFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.invalidResponse
        default:
            throw NetworkError.invalidResponse
        }
    }
    
    /// Generic JSON decoding with error handling
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(type, from: data)
        } catch let decodingError as DecodingError {
            // Log specific decoding errors for debugging
            logDecodingError(decodingError)
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Parse price history from raw JSON data
    func parsePriceHistory(from data: Data) throws -> [PricePoint] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pricesArray = json["prices"] as? [[Double]] else {
                throw NetworkError.decodingError
            }
            
            let pricePoints = pricesArray.enumerated().compactMap { (index, priceData) -> PricePoint? in
                guard priceData.count >= 2 else { return nil }
                
                let timestampMs = priceData[0]
                let price = priceData[1]
                
                // Validate data integrity
                guard timestampMs > 0,
                      price > 0,
                      price.isFinite,
                      !price.isNaN else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: timestampMs / 1000)
                return PricePoint(index: index, price: price, timestamp: timestamp)
            }
            
            // Ensure we have valid data
            guard !pricePoints.isEmpty else {
                throw NetworkError.noData
            }
            
            // Sort by timestamp for proper chart rendering
            return pricePoints.sorted {
                ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Log decoding errors for debugging
    func logDecodingError(_ error: DecodingError) {
        #if DEBUG
        switch error {
        case .dataCorrupted(let context):
            print("🔴 Data corrupted: \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            print("🔴 Key '\(key.stringValue)' not found: \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            print("🔴 Type mismatch for \(type): \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("🔴 Value not found for \(type): \(context.debugDescription)")
        @unknown default:
            print("🔴 Unknown decoding error: \(error)")
        }
        #endif
    }
}

// MARK: - NetworkService + Retry Logic
extension NetworkService {
    
    /// Perform request with automatic retry for recoverable errors
    func performRequestWithRetry(url: URL, maxRetries: Int = Constants.maxRetries) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await performRequest(url: url)
            } catch let error as NetworkError {
                lastError = error
                
                // Only retry for recoverable errors
                guard error.isRecoverable && attempt < maxRetries else {
                    throw error
                }
                
                // Wait before retrying
                let delay = min(error.retryDelay, Constants.retryDelay * Double(attempt + 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                throw NetworkError.invalidResponse
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? NetworkError.invalidResponse
    }
}

// MARK: - NetworkError Extensions
extension NetworkError {
    
    /// Check if the error is recoverable (should retry)
    var isRecoverable: Bool {
        switch self {
        case .rateLimited, .invalidResponse:
            return true
        case .invalidURL, .decodingError, .noData, .coinNotFound:
            return false
        }
    }
    
    /// Get appropriate retry delay
    var retryDelay: TimeInterval {
        switch self {
        case .rateLimited:
            return 60.0 // Wait 1 minute for rate limiting
        case .invalidResponse:
            return 5.0  // Wait 5 seconds for server issues
        default:
            return 0.0  // No retry
        }
    }
}
