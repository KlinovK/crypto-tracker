//
//  URLSessionClient.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import Foundation

final class URLSessionClient: HTTPClient {
    private let session: URLSession
    private let validator = ResponseValidator()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func perform(url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        try validator.validate(httpResponse)
        guard !data.isEmpty else { throw NetworkError.noData }
        return data
    }
}
