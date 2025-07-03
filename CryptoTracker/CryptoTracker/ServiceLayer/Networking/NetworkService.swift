//
//  NetworkService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

// MARK: - Protocols

protocol NetworkServiceProtocol {
    func fetchCryptocurrencies(page: Int, sortBy: SortOption) async throws -> [Cryptocurrency]
    func fetchCryptocurrenciesByIds(ids: [String]) async throws -> [Cryptocurrency]
    func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency]
    func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint]
}

// MARK: - NetworkService

final class NetworkService: NetworkServiceProtocol {
    private let httpClient: HTTPClient
    private let urlBuilder: URLBuilder
    private let jsonDecoder: JSONDecoder
    private let baseURL = "https://api.coingecko.com/api/v3"

    private enum Constants {
        static let perPage = 50
        static let currency = "usd"
    }

    init(
        httpClient: HTTPClient,
        urlBuilder: URLBuilder = URLBuilder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.httpClient = httpClient
        self.urlBuilder = urlBuilder
        self.jsonDecoder = jsonDecoder
    }

    func fetchCryptocurrencies(page: Int = 1, sortBy: SortOption = .marketCap) async throws -> [Cryptocurrency] {
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "order", value: sortBy.rawValue),
            URLQueryItem(name: "per_page", value: "\(Constants.perPage)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        let url = try urlBuilder.build(baseURL: baseURL, endpoint: "/coins/markets", queryItems: queryItems)
        let data = try await httpClient.perform(url: url)
        return try jsonDecoder.decode([Cryptocurrency].self, from: data)
    }

    func searchCryptocurrencies(query: String) async throws -> [Cryptocurrency] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidURL
        }

        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "ids", value: encodedQuery)
        ]

        let url = try urlBuilder.build(baseURL: baseURL, endpoint: "/coins/markets", queryItems: queryItems)
        let data = try await httpClient.perform(url: url)
        let results = try jsonDecoder.decode([Cryptocurrency].self, from: data)

        guard !results.isEmpty else {
            throw NetworkError.coinNotFound
        }

        return results
    }

    func fetchPriceHistory(coinId: String, days: String) async throws -> [PricePoint] {
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "days", value: days)
        ]

        let url = try urlBuilder.build(baseURL: baseURL, endpoint: "/coins/\(coinId)/market_chart", queryItems: queryItems)
        let data = try await httpClient.perform(url: url)
        return try parsePriceHistory(from: data)
    }

    func fetchCryptocurrenciesByIds(ids: [String]) async throws -> [Cryptocurrency] {
        guard !ids.isEmpty else { return [] }
        let joined = ids.joined(separator: ",")
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: Constants.currency),
            URLQueryItem(name: "ids", value: joined)
        ]

        let url = try urlBuilder.build(baseURL: baseURL, endpoint: "/coins/markets", queryItems: queryItems)
        let data = try await httpClient.perform(url: url)
        return try jsonDecoder.decode([Cryptocurrency].self, from: data)
    }

    private func parsePriceHistory(from data: Data) throws -> [PricePoint] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pricesArray = json["prices"] as? [[Double]] else {
            throw NetworkError.decodingError
        }

        let points = pricesArray.enumerated().compactMap { (index, item) -> PricePoint? in
            guard item.count >= 2 else { return nil }
            let timestamp = Date(timeIntervalSince1970: item[0] / 1000)
            return PricePoint(index: index, price: item[1], timestamp: timestamp)
        }

        guard !points.isEmpty else {
            throw NetworkError.noData
        }

        return points
    }
}
