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
        // Record block attempt (user saw the shield)
        recordBlockAttempt()

        switch action {
        case .primaryButtonPressed:
            // User clicked "Start Challenge" - don't record event yet, wait for ChallengeView to appear
            markUnlockRequested(for: application)
            sendUnlockNotification()
            // Keep shield open - user must complete challenge in main app
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // User clicked "Not Now" - record walked away event
            recordWalkedAwayEvent(for: application)
            completionHandler(.close)

        case .firstSecondarySubmenuItemPressed,
             .secondSecondarySubmenuItemPressed,
             .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Record block attempt (user saw the shield)
        recordBlockAttempt()

        switch action {
        case .primaryButtonPressed:
            // User clicked "Start Challenge" on a category-blocked app
            // Note: We don't have the specific ApplicationToken here, only the category
            // Store the category token so the main app knows which category to unlock
            markCategoryUnlockRequested(for: category)
            sendUnlockNotification()
            // Keep shield open - user must complete challenge in main app
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // User clicked "Not Now" - record walked away event
            recordWalkedAwayForCategory(for: category)
            completionHandler(.close)

        case .firstSecondarySubmenuItemPressed,
             .secondSecondarySubmenuItemPressed,
             .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func markUnlockRequested(for application: ApplicationToken) {
        guard let sharedDefaults = UserDefaults.appGroup else {
            return
        }

        // Store that an unlock was requested
        sharedDefaults.set(true, forKey: "com.screenfare.unlockRequested")

        // Try to store the ApplicationToken data for matching
        // ApplicationToken conforms to Codable, so we can encode it
        if let data = try? JSONEncoder().encode(application) {
            sharedDefaults.set(data, forKey: "com.screenfare.requestedAppToken")
        }

        // Clear any category request since this is an app-specific request
        sharedDefaults.removeObject(forKey: "com.screenfare.requestedCategoryToken")
    }

    private func markCategoryUnlockRequested(for category: ActivityCategoryToken) {
        guard let sharedDefaults = UserDefaults.appGroup else {
            return
        }

        // Store that an unlock was requested
        sharedDefaults.set(true, forKey: "com.screenfare.unlockRequested")

        // Store the CategoryToken data
        if let data = try? JSONEncoder().encode(category) {
            sharedDefaults.set(data, forKey: "com.screenfare.requestedCategoryToken")
        }

        // Clear any app request since this is a category request
        sharedDefaults.removeObject(forKey: "com.screenfare.requestedAppToken")
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
            content.body = "Tap to pay your fare"
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

    private func recordBlockAttempt() {
        guard let sharedDefaults = UserDefaults.appGroup else {
            return
        }

        let storageKey = "com.screenfare.dailyStats"
        let today = Date.todayDateString()
        var stats: DailyStats

        // Read existing stats
        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            stats = decoded
        } else {
            stats = DailyStats(date: today)
        }

        // Increment blocks counter
        stats.blocksToday += 1

        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(stats) {
            sharedDefaults.set(encoded, forKey: storageKey)
        }

        // Notify main app that stats were updated (replaces polling)
        let notificationName = "com.screenfare.statsUpdated" as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(notificationName), nil, nil, true)
    }

    private func recordWalkedAwayEvent(for application: ApplicationToken) {
        guard let sharedDefaults = UserDefaults.appGroup,
              let appTokenData = try? JSONEncoder().encode(application) else {
            return
        }

        let storageKey = "com.screenfare.pendingHistoryEvents"

        // Read challenge type from settings
        let challengeTypeRaw = sharedDefaults.string(forKey: "challengeType") ?? "math"
        let challengeTypeName: String = {
            switch challengeTypeRaw {
            case "math": return "Math"
            case "typing": return "Typing"
            case "memory": return "Memory"
            default: return "Math"
            }
        }()

        // Create new history event
        let event = HistoryEvent(
            id: UUID(),
            appTokenData: appTokenData,
            timestamp: Date(),
            eventType: .walkedAway,
            duration: 0,
            challengeType: challengeTypeName
        )

        // Load existing pending events
        var pendingEvents: [HistoryEvent] = []
        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HistoryEvent].self, from: data) {
            pendingEvents = decoded
        }

        // Add new event
        pendingEvents.append(event)

        // Save back to shared storage
        if let encoded = try? JSONEncoder().encode(pendingEvents) {
            sharedDefaults.set(encoded, forKey: storageKey)
        }
    }

    private func recordWalkedAwayForCategory(for category: ActivityCategoryToken) {
        // For category blocks, we don't have the specific app token
        // Just increment the walked away counter without recording to history
        // (since we can't show which specific app in the category was accessed)
        guard UserDefaults.appGroup != nil else {
            return
        }

        // Could track category-level stats here if needed in the future
        print("[ShieldAction] User walked away from category-blocked app")
    }
}

// Local copy of HistoryEvent for the extension
private struct HistoryEvent: Codable, Identifiable {
    let id: UUID
    let appTokenData: Data
    let timestamp: Date
    let eventType: EventType
    let duration: TimeInterval
    let challengeType: String?

    enum EventType: String, Codable {
        case farePaid = "Fare paid"
        case walkedAway = "Walked away"
        case challengeStarted = "Challenge started"
    }
}

// Local copy of DailyStats for the extension
private struct DailyStats: Codable {
    var date: String
    var blocksToday: Int
    var faresPaid: Int
    var timeSpentSeconds: Int

    init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.faresPaid = 0
        self.timeSpentSeconds = 0
    }
}
