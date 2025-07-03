//
//  CryptoTrackerApp.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI
import UIKit

/// The main entry point of the CryptoTracker application.
@main
struct CryptoTrackerApp: App {

    /// Registers the custom `AppDelegate` to handle application-level events and configuration.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// The main scene of the application, containing the tab-based interface and injected dependencies.
    var body: some Scene {
        WindowGroup {
            TabBarView()
                // Injects the Core Data context used for persistent storage throughout the app.
                .environment(\.managedObjectContext, DataStorageService.shared.context)
                // Injects the shared app coordinator to manage navigation and shared app state.
                .environmentObject(AppCoordinator())
        }
    }
}
