//
//  HTTPClient.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import Foundation

protocol HTTPClient {
    func perform(url: URL) async throws -> Data
}
