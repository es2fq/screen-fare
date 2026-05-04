//
//  NotificationManager.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var shouldShowChallenge = false

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        // Don't auto-request authorization - let onboarding handle it
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    func setupNotificationCategories() {
        let unlockAction = UNNotificationAction(
            identifier: "UNLOCK_ACTION",
            title: "Complete Challenge",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "UNLOCK_CHALLENGE",
            actions: [unlockAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.categoryIdentifier == "UNLOCK_CHALLENGE" {
            DispatchQueue.main.async {
                self.shouldShowChallenge = true
            }
        }
        completionHandler()
    }
}
