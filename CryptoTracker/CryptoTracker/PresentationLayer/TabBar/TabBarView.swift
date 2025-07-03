//
//  TabBarView.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

/// The main view displaying tabbed content for all cryptocurrencies and user's favorites.
struct TabBarView: View {

    // MARK: - Properties

    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel: TabBarViewModel

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        favoritesService: FavoritesServiceProtocol = FavoritesService()
    ) {
        let listVM = CryptocurrencyListViewModel(
            networkService: networkService,
            favoritesService: favoritesService
        )

        let favoritesVM = FavoritesListViewModel(
            networkService: networkService, favoritesService: favoritesService
        )

        let notifier = NotificationService()
        let preloader = CryptocurrencyPreloader(networkService: networkService)
        let priceMonitor = PriceChangeMonitor(networkService: networkService, favoritesService: favoritesService, notifier: notifier)

        _viewModel = StateObject(wrappedValue: TabBarViewModel(
            listViewModel: listVM,
            favoritesViewModel: favoritesVM,
            preloader: preloader,
            priceMonitor: priceMonitor
        ))
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            if viewModel.isLoading {
                loadingTab
            } else {
                makeTab(
                    view: CryptocurrencyListView(viewModel: viewModel.listViewModel),
                    label: "All Cryptos",
                    icon: "list.bullet",
                    tag: 0
                )

                makeTab(
                    view: FavoritesListView(viewModel: viewModel.favoritesViewModel),
                    label: "Favorites",
                    icon: "heart.fill",
                    tag: 1
                )
            }
        }
        .tint(.blue)
        .overlay(alignment: .top) {
            if viewModel.showOfflineMessage {
                offlineBanner
            }
        }
    }

    // MARK: - Tabs

    private var loadingTab: some View {
        LoadingView()
            .tabItem {
                Label("Loading", systemImage: "hourglass")
            }
            .tag(99)
    }

    private func makeTab<V: View>(
        view: V,
        label: String,
        icon: String,
        tag: Int
    ) -> some View {
        NavigationStack {
            view
                .environmentObject(coordinator)
                .navigationDestination(isPresented: $coordinator.showingDetail) {
                    destinationView
                }
        }
        .tabItem {
            Label(label, systemImage: icon)
        }
        .tag(tag)
    }

    // MARK: - Navigation

    @ViewBuilder
    private var destinationView: some View {
        if let selected = coordinator.selectedCrypto {
            CryptocurrencyDetailView(
                viewModel: CryptocurrencyDetailViewModel(
                    cryptocurrency: selected,
                    networkService: viewModel.listViewModel.networkService,
                    favoritesService: viewModel.listViewModel.favoritesService
                )
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Offline UI

    private var offlineBanner: some View {
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
