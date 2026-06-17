//
//  NotificationManager.swift
//  Screen Fare
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
            title: "Pay Your Fare",
            options: [.foreground]
        )

        let unlockCategory = UNNotificationCategory(
            identifier: "UNLOCK_CHALLENGE",
            actions: [unlockAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([unlockCategory])
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content

        // If it's an unlock challenge notification, trigger the challenge immediately
        if content.categoryIdentifier == "UNLOCK_CHALLENGE" {
            DispatchQueue.main.async {
                self.shouldShowChallenge = true
            }
            // Don't show the notification banner since we're opening the challenge directly
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }

    // Handle notification tap (or when app is not running)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content

        if content.categoryIdentifier == "UNLOCK_CHALLENGE" {
            DispatchQueue.main.async {
                self.shouldShowChallenge = true
            }
        }
        completionHandler()
    }
}
