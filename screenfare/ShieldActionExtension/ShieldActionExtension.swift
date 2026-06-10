//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Created by Erik Song on 5/3/26.
//

import ManagedSettings
import ManagedSettingsUI
import FamilyControls
import UserNotifications
import Foundation

/// Handles actions when user taps buttons on the shield
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            markUnlockRequested(for: application)
            sendUnlockNotification()
            // Keep shield open - user must complete challenge in main app
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func markUnlockRequested(for application: ApplicationToken) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared") else {
            return
        }

        // Store that an unlock was requested
        sharedDefaults.set(true, forKey: "com.screenfare.unlockRequested")

        // Try to store the ApplicationToken data for matching
        // ApplicationToken conforms to Codable, so we can encode it
        if let data = try? JSONEncoder().encode(application) {
            sharedDefaults.set(data, forKey: "com.screenfare.requestedAppToken")
        }

        sharedDefaults.synchronize()
    }

    private func sendUnlockNotification() {
        // Use Darwin Notification to signal the main app
        let notificationName = "com.screenfare.unlockChallenge" as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(notificationName), nil, nil, true)

        // Also send UNNotification
        let unCenter = UNUserNotificationCenter.current()
        unCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted, error == nil else { return }

            let content = UNMutableNotificationContent()
            content.title = "App Unlock Requested"
            content.body = "Open ScreenFare to complete the challenge"
            content.sound = .default
            content.categoryIdentifier = "UNLOCK_CHALLENGE"
            content.userInfo = ["action": "unlock"]
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(
                identifier: "unlock-challenge",
                content: content,
                trigger: nil
            )

            unCenter.add(request) { _ in }
        }
    }
}
