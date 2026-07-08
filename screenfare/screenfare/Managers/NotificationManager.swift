//
//  NotificationManager.swift
//  Screen Fare
//
//  Manages user-visible notifications (alerts, banners, sounds)
//  via iOS UserNotifications framework (UNUserNotificationCenter)
//
//  ⚠️ NOTE: This is different from DarwinNotificationManager!
//
//  ## Purpose
//  - Handles user-facing notifications that appear in notification center
//  - Requests notification permissions from the user
//  - Configures notification actions (e.g., "Pay Your Fare" button)
//  - Responds to user interactions with notifications
//
//  ## Use Cases
//  - Unlock challenge notifications when app is in background
//  - Reminder notifications for schedule changes
//  - Any notification that needs user permission and appears in notification center
//
//  ## Related Managers
//  - **DarwinNotificationManager**: For cross-process communication (extension → app)
//    without user permission or visible UI
//
//  Created by Erik Song on 5/3/26.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI

/// Manages user-visible notifications through iOS UserNotifications framework
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    /// Triggers challenge view when user taps notification or when foreground notification arrives
    @Published var shouldShowChallenge = false

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        // Don't auto-request authorization - let onboarding handle it
    }

    /// Requests permission to show alerts, sounds, and badges
    /// Called during onboarding flow after user understands what they're for
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    /// Configures notification categories with custom actions
    /// Currently defines:
    /// - "UNLOCK_CHALLENGE" category with "Pay Your Fare" action button
    func setupNotificationCategories() {
        let unlockAction = UNNotificationAction(
            identifier: "UNLOCK_ACTION",
            title: "Pay Your Fare",
            options: [.foreground]  // Opens app when tapped
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

// MARK: - UNUserNotificationCenterDelegate

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
