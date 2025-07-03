//
//  NetworkService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

/// Protocol defining the interface for fetching cryptocurrency data from the network.
protocol NetworkServiceProtocol {
    /// Fetches a paginated list of cryptocurrencies sorted by the given option.
    func fetchCryptocurrencies(page: Int, sortBy: SortOption) async throws -> [Cryptocurrency]
    
    /// Searches cryptocurrencies by their IDs or names.
    func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency]
    
    /// Fetches historical price data for a specific coin over a number of days.
    func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint]
    
    /// Fetches cryptocurrency data for specific coin IDs.
    func fetchCryptocurrenciesByIds(ids: [String]) async throws -> [Cryptocurrency]
}

// MARK: - NetworkService

/// A concrete implementation of `NetworkServiceProtocol` that communicates with the CoinGecko API.
class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    /// The `URLSession` used to make requests.
    private let session: URLSession
    
    /// Base URL for the CoinGecko API.
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    /// Decoder used for decoding JSON responses.
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Constants
    
    private enum Constants {
        static let perPage = 50
        static let currency = "usd"
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Initialization
    
    /// Initializes a new instance of `NetworkService`.
    /// - Parameters:
    ///   - session: Custom `URLSession` (defaults to `.shared`).
    ///   - jsonDecoder: Custom `JSONDecoder` (defaults to new instance).
    init(session: URLSession = .shared, jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
    
    // MARK: - Public Methods
    
    /// Fetches a paginated and sorted list of cryptocurrencies.
    /// - Parameters:
    ///   - page: Page number to fetch (default is 1).
    ///   - sortBy: Sorting criteria.
    /// - Returns: An array of `Cryptocurrency` objects.
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
    
    /// Searches for cryptocurrencies based on a query string.
    /// - Parameter query: Search keyword (usually the coin ID or name).
    /// - Returns: An array of matching `Cryptocurrency` objects.
    public func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency] {
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
        
        guard !cryptocurrencies.isEmpty else {
            throw NetworkError.coinNotFound
        }
        
        return cryptocurrencies
    }
    
    /// Fetches historical price data for a given coin ID.
    /// - Parameters:
    ///   - coinId: CoinGecko ID of the cryptocurrency.
    ///   - days: Number of days to look back (e.g. "1", "7", "30").
    /// - Returns: Array of `PricePoint` for charting.
    public func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint] {
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
    
    /// Fetches a list of cryptocurrencies using their CoinGecko IDs.
    /// - Parameter ids: Array of coin IDs.
    /// - Returns: Array of `Cryptocurrency` objects.
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

// MARK: - Private Helpers

private extension NetworkService {
    
    /// Builds a full URL with endpoint and query parameters.
    /// - Parameters:
    ///   - endpoint: API endpoint path.
    ///   - queryItems: Optional query parameters.
    /// - Returns: A constructed `URL` object.
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
    
    /// Performs a network request with validation and error handling.
    /// - Parameter url: The `URL` to request.
    /// - Returns: Raw response `Data`.
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
            throw NetworkError.invalidResponse
        }
    }
    
    /// Validates the HTTP response status code.
    /// - Parameter response: HTTP response to validate.
    func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299: break
        case 400: throw NetworkError.invalidResponse
        case 404: throw NetworkError.coinNotFound
        case 429: throw NetworkError.rateLimited
        case 500...599: throw NetworkError.invalidResponse
        default: throw NetworkError.invalidResponse
        }
    }
    
    /// Decodes JSON data into a specified type.
    /// - Parameters:
    ///   - type: The type conforming to `Decodable`.
    ///   - data: Raw `Data` to decode.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(type, from: data)
        } catch let decodingError as DecodingError {
            logDecodingError(decodingError)
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Parses historical price data from raw JSON.
    /// - Parameter data: Raw price history data.
    /// - Returns: Array of `PricePoint`.
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
                guard timestampMs > 0, price > 0, price.isFinite, !price.isNaN else {
                    return nil
                }
                let timestamp = Date(timeIntervalSince1970: timestampMs / 1000)
                return PricePoint(index: index, price: price, timestamp: timestamp)
            }
            
            guard !pricePoints.isEmpty else {
                throw NetworkError.noData
            }
            
            return pricePoints.sorted {
                ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Logs decoding errors for debugging purposes (only in DEBUG mode).
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

// MARK: - Retry Logic

extension NetworkService {
    
    /// Performs a network request with retry logic for recoverable errors.
    /// - Parameters:
    ///   - url: The `URL` to request.
    ///   - maxRetries: Maximum retry attempts.
    /// - Returns: Raw response `Data`.
    func performRequestWithRetry(url: URL, maxRetries: Int = Constants.maxRetries) async throws -> Data {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                return try await performRequest(url: url)
            } catch let error as NetworkError {
                lastError = error
                guard error.isRecoverable && attempt < maxRetries else {
                    throw error
                }
                let delay = min(error.retryDelay, Constants.retryDelay * Double(attempt + 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                throw NetworkError.invalidResponse
            }
        }
        throw lastError ?? NetworkError.invalidResponse
    }
}

// MARK: - NetworkError Helpers

extension NetworkError {
    
    /// Determines if the error can be retried.
    var isRecoverable: Bool {
        switch self {
        case .rateLimited, .invalidResponse: return true
        case .invalidURL, .decodingError, .noData, .coinNotFound: return false
        }
    }
    
    /// Suggested delay before retrying the request.
    var retryDelay: TimeInterval {
        switch self {
        case .rateLimited: return 60.0
        case .invalidResponse: return 5.0
        default: return 0.0
        }
    }
}
