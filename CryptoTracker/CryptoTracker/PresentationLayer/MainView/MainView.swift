//
//  ContentView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct MainView: View {
    
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var listViewModel: CryptocurrencyListViewModel
    @StateObject private var favoritesViewModel: FavoritesListViewModel
    
    init() {
        let coordinator = AppCoordinator()
        let listViewModel = CryptocurrencyListViewModel(
            networkService: coordinator.networkService,
            favoritesService: coordinator.favoritesService
        )
        let favoritesViewModel = FavoritesListViewModel(
            networkService: coordinator.networkService,
            favoritesService: coordinator.favoritesService
        )
        
        _coordinator = StateObject(wrappedValue: coordinator)
        _listViewModel = StateObject(wrappedValue: listViewModel)
        _favoritesViewModel = StateObject(wrappedValue: favoritesViewModel)
        
        configureTabBarAppearance()

    }
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            NavigationStack {
                CryptocurrencyListView(viewModel: listViewModel)
                    .environmentObject(coordinator)
                    .navigationDestination(isPresented: $coordinator.showingDetail) {
                        destinationView
                    }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("All Cryptos")
            }
            .tag(0)
            
            NavigationStack {
                FavoritesListView(viewModel: favoritesViewModel)
                    .environmentObject(coordinator)
                    .navigationDestination(isPresented: $coordinator.showingDetail) {
                        destinationView
                    }
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Favorites")
            }
            .tag(1)
        }
        
        .tint(.blue)

    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let selectedCrypto = coordinator.selectedCrypto {
            CryptocurrencyDetailView(
                viewModel: CryptocurrencyDetailViewModel(
                    cryptocurrency: selectedCrypto,
                    networkService: coordinator.networkService,
                    favoritesService: coordinator.favoritesService
                )
            )
        } else {
            EmptyView()
        }
    }
    
    private func configureTabBarAppearance() {
         let appearance = UITabBarAppearance()
         
         // Configure background
         appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.gray // Tab bar background color
         
         // Configure normal (unselected) tab items
         appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
         appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
             .foregroundColor: UIColor.white
         ]
         
         // Configure selected tab items
         appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemYellow
         appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
             .foregroundColor: UIColor.systemYellow
         ]
         
         // Apply to all tab bars
         UITabBar.appearance().standardAppearance = appearance
         UITabBar.appearance().scrollEdgeAppearance = appearance
     }
    
}

