//
//  NetworkMonitor.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 02/07/25.
//

import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")

    private init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let connected = path.status == .satisfied
                self.isConnected = connected
            }
        }

        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
