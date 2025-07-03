//
//  NetworkMonitor.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation
import Network

/// Monitors the device's internet connectivity status in real-time.
final class NetworkMonitor: ObservableObject {
    
    /// Shared singleton instance.
    static let shared = NetworkMonitor()
    
    /// Indicates whether the device is currently connected to the internet.
    @Published private(set) var isConnected: Bool = true

    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    // MARK: - Initializer
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
