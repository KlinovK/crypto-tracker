//
//  AppCoordinator.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

/// A coordinator responsible for managing navigation and animations within the app.
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// The currently selected cryptocurrency, if any.
    @Published var selectedCrypto: Cryptocurrency?

    /// Indicates whether the detail view should be shown.
    @Published var showingDetail = false

    /// A flag to prevent multiple animations from triggering simultaneously.
    @Published var isAnimating = false

    // MARK: - Private Properties

    /// The animation used for transitioning between views.
    private let animation = Animation.easeInOut(duration: 0.3)

    /// The duration of the animation (used to reset `isAnimating` after transition).
    private let animationDuration: TimeInterval = 0.3

    // MARK: - Navigation

    /// Initiates navigation to the detail view for a selected cryptocurrency.
    ///
    /// This method checks if an animation is currently in progress. If not, it updates
    /// the selected crypto and triggers a smooth animation to display the detail view.
    ///
    /// - Parameter crypto: The `Cryptocurrency` to navigate to.
    func navigateToDetail(_ crypto: Cryptocurrency) {
        guard !isAnimating else { return }

        selectedCrypto = crypto
        isAnimating = true

        withAnimation(animation) {
            showingDetail = true
        }

        // Reset animation flag after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.isAnimating = false
        }
    }

    /// Determines if navigation is currently allowed (i.e., not mid-animation).
    ///
    /// - Returns: `true` if navigation is permitted, otherwise `false`.
    func canNavigate() -> Bool {
        !isAnimating
    }
}
