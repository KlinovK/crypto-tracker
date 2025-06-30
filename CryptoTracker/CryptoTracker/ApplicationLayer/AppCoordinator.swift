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
    
    let networkService: NetworkServiceProtocol
    let favoritesService: FavoritesService
    
    init() {
        self.networkService = NetworkService()
        self.favoritesService = FavoritesService()
    }
    
    func navigateToDetail(_ crypto: Cryptocurrency) {
        selectedCrypto = crypto
        showingDetail = true
    }
    
    func popToRoot() {
        showingDetail = false
        selectedCrypto = nil
    }
    
}
