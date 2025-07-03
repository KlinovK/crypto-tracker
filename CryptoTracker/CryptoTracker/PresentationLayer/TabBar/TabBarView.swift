//
//  TabBarView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct TabBarView: View {

    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel: TabBarViewModel

    // MARK: - Init

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        favoritesService: FavoritesServiceProtocol = FavoritesService()
    ) {
        _viewModel = StateObject(wrappedValue: TabBarViewModel(
            networkService: networkService,
            favoritesService: favoritesService
        ))
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            if viewModel.isLoading {
                LoadingView()
                    .tabItem {
                        Label("Loading", systemImage: "hourglass")
                    }
                    .tag(99)
            } else {
                NavigationStack {
                    CryptocurrencyListView(viewModel: viewModel.listViewModel)
                        .environmentObject(coordinator)
                        .navigationDestination(isPresented: $coordinator.showingDetail) {
                            destinationView
                        }
                }
                .tabItem {
                    Label("All Cryptos", systemImage: "list.bullet")
                }
                .tag(0)

                NavigationStack {
                    FavoritesListView(viewModel: viewModel.favoritesViewModel)
                        .environmentObject(coordinator)
                        .navigationDestination(isPresented: $coordinator.showingDetail) {
                            destinationView
                        }
                }
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(1)
            }
        }
        .tint(.blue)
        .onAppear {
            viewModel.startPreloading()
        }
        .overlay(alignment: .top) {
            if viewModel.showOfflineMessage {
                Text("No Internet Connection")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showOfflineMessage)
            }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if let selectedCrypto = coordinator.selectedCrypto {
            CryptocurrencyDetailView(
                viewModel: CryptocurrencyDetailViewModel(
                    cryptocurrency: selectedCrypto,
                    networkService: viewModel.listViewModel.networkService,
                    favoritesService: viewModel.listViewModel.favoritesService
                )
            )
        } else {
            EmptyView()
        }
    }
}
