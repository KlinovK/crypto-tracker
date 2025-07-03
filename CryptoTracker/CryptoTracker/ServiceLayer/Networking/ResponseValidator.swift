//
//  ResponseValidator.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import Foundation

final class ResponseValidator {
    func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299: return
        case 400: throw NetworkError.invalidResponse
        case 404: throw NetworkError.coinNotFound
        case 429: throw NetworkError.rateLimited
        default: throw NetworkError.invalidResponse
        }
    }
}
