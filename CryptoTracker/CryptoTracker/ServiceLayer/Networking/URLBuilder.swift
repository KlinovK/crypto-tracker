//
//  URLBuilder.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import Foundation

final class URLBuilder {
    func build(baseURL: String, endpoint: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
}
