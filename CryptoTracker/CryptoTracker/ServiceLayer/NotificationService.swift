//
//  NotificationService.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 03/07/25.
//

import Foundation
import NotificationCenter

protocol NotificationServiceProtocol {
    func send(title: String, body: String)
}

final class NotificationService: NotificationServiceProtocol {
    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
