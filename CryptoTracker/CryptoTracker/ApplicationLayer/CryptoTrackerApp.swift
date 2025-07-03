//
//  CryptoTrackerApp.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI
import UIKit

@main
struct CryptoTrackerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .environment(\.managedObjectContext, DataStorageService.shared.context)
                .environmentObject(AppCoordinator())
        }
    }
    
}
