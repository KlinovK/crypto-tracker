//
//  NetworkErrorDataModel.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import Foundation

// MARK: - NetworkError

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case rateLimited
    case coinNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response data"
        case .rateLimited:
            return "Rate limited - too many requests"
        case .coinNotFound:
            return "Cryptocurrency not found"
        }
    }
}
