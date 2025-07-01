//
//  AppCoordinator.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

class AppCoordinator: ObservableObject {
    
    @Published var selectedCrypto: Cryptocurrency?
    @Published var showingDetail = false
    @Published var selectedTab = 0
    @Published var isAnimating = false
    
    let networkService: NetworkServiceProtocol
    let favoritesService: FavoritesService
    
    // Animation configurations
    private let navigationAnimation = Animation.easeInOut(duration: 0.3)
    private let tabSwitchAnimation = Animation.easeInOut(duration: 0.25)
    private let quickAnimation = Animation.easeInOut(duration: 0.2)
    
    init() {
        self.networkService = NetworkService()
        self.favoritesService = FavoritesService()
    }
    
    // MARK: - Navigation Methods
    
    func navigateToDetail(_ crypto: Cryptocurrency) {
        withAnimation(navigationAnimation) {
            selectedCrypto = crypto
            isAnimating = true
        }
        
        // Delay showing detail to allow for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(self.navigationAnimation) {
                self.showingDetail = true
                self.isAnimating = false
            }
        }
    }
    
    func popToRoot() {
        withAnimation(navigationAnimation) {
            isAnimating = true
            showingDetail = false
        }
        
        // Clear selected crypto after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedCrypto = nil
            self.isAnimating = false
        }
    }
    
    func switchTab(to index: Int) {
        guard index != selectedTab else { return }
        
        withAnimation(tabSwitchAnimation) {
            selectedTab = index
            
            // If switching tabs while detail is showing, pop to root
            if showingDetail {
                showingDetail = false
                selectedCrypto = nil
            }
        }
    }
    
    // MARK: - Animation Helpers
    
    func getTransitionAnimation() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    func getTabTransitionAnimation() -> AnyTransition {
        .opacity.combined(with: .scale(scale: 0.95))
    }
    
    func getDetailTransitionAnimation() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    // MARK: - Animation State Methods
    
    func canNavigate() -> Bool {
        return !isAnimating
    }
    
    func performWithAnimation<T>(_ animation: Animation, action: @escaping () -> T) -> T {
        withAnimation(animation) {
            return action()
        }
    }
    
    // MARK: - Convenience Methods
    
    func quickNavigateToDetail(_ crypto: Cryptocurrency) {
        guard canNavigate() else { return }
        
        withAnimation(quickAnimation) {
            selectedCrypto = crypto
            showingDetail = true
        }
    }
    
    func smoothPopToRoot() {
        guard canNavigate() else { return }
        
        withAnimation(navigationAnimation.delay(0.1)) {
            showingDetail = false
        }
        
        withAnimation(navigationAnimation.delay(0.2)) {
            selectedCrypto = nil
        }
    }
    
    // MARK: - Custom Animation Presets
    
    static let slideInFromRight = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let slideInFromBottom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )
    
    static let fadeAndScale = AnyTransition.opacity.combined(with: .scale(scale: 0.9))
    
    static let springAnimation = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0.1
    )
}

// MARK: - View Extension for Coordinator
extension View {
    func coordinatedTransition(_ coordinator: AppCoordinator) -> some View {
        self.transition(coordinator.getTransitionAnimation())
    }
    
    func coordinatedTabTransition(_ coordinator: AppCoordinator) -> some View {
        self.transition(coordinator.getTabTransitionAnimation())
    }
    
    func coordinatedDetailTransition(_ coordinator: AppCoordinator) -> some View {
        self.transition(coordinator.getDetailTransitionAnimation())
    }
}
