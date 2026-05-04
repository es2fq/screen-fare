//
//  ShieldActionExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Erik Song on 5/3/26.
//

import ManagedSettings
import ManagedSettingsUI
import UserNotifications

// Override the functions below to customize the shield actions used in various situations.
// Make sure that your class name matches the NSExtensionPrincipalClass in the extension's Info.plist file.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed
        switch action {
        case .primaryButtonPressed:
            // Send a notification to open the main app
            sendUnlockNotification()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            // Handle secondary button if needed
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for applicationCategory: ApplicationCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed
        switch action {
        case .primaryButtonPressed:
            sendUnlockNotification()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed
        switch action {
        case .primaryButtonPressed:
            sendUnlockNotification()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func sendUnlockNotification() {
        let center = UNUserNotificationCenter.current()

        // Request authorization if needed
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Unlock Your Apps"
                content.body = "Tap to complete a challenge and unlock your apps"
                content.sound = .default
                content.categoryIdentifier = "UNLOCK_CHALLENGE"
                content.userInfo = ["action": "unlock"]

                let request = UNNotificationRequest(
                    identifier: "unlock-challenge",
                    content: content,
                    trigger: nil // Deliver immediately
                )

                center.add(request) { error in
                    if let error = error {
                        print("Error sending notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
