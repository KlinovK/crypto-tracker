//
//  AppDelegate.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import UIKit
import UserNotifications

/// The application's delegate, responsible for global setup like UI appearance and notification permissions.
final class AppDelegate: NSObject, UIApplicationDelegate {

    /// Called when the application has finished launching. Performs initial configuration tasks.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureTabBarAppearance()
        requestNotificationPermissions()
        return true
    }
}

// MARK: - Private Configuration

private extension AppDelegate {

    /// Configures the global appearance of the UITabBar to use custom background and item colors.
    ///
    /// This setup affects all `UITabBar` instances across the app, including their behavior in iOS 15+.
    func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .gray

        let normalColor: UIColor = .gray
        let selectedColor: UIColor = .blue

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    /// Requests permission from the user to send local notifications (alerts, sounds, badges).
    ///
    /// Prints the result to the console for debugging purposes.
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
