//
//  AppCoordinator.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {

    @Published var selectedCrypto: Cryptocurrency?
    @Published var showingDetail = false
    @Published var isAnimating = false

    private let navigationAnimation = Animation.easeInOut(duration: 0.3)

    // MARK: - Navigation
    
    func navigateToDetail(_ crypto: Cryptocurrency) {
        guard canNavigate() else { return }

        withAnimation(navigationAnimation) {
            selectedCrypto = crypto
            isAnimating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(self.navigationAnimation) {
                self.showingDetail = true
                self.isAnimating = false
            }
        }
    }

    func canNavigate() -> Bool {
        !isAnimating
    }
}

