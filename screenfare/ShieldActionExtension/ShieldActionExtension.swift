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
        recordBlockedEvent(for: application)


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

    private func recordBlockAttempt() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared") else {
            return
        }

        let storageKey = "com.screenfare.dailyStats"
        let today = todayDateString()
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
            sharedDefaults.synchronize()
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func recordBlockedEvent(for application: ApplicationToken) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let appTokenData = try? JSONEncoder().encode(application) else {
            return
        }

        let storageKey = "com.screenfare.pendingHistoryEvents"

        // Create new history event
        let event = HistoryEvent(
            id: UUID(),
            appTokenData: appTokenData,
            timestamp: Date(),
            eventType: .blocked,
            duration: 0
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
            sharedDefaults.synchronize()
        }
    }
}

// Local copy of HistoryEvent for the extension
private struct HistoryEvent: Codable, Identifiable {
    let id: UUID
    let appTokenData: Data
    let timestamp: Date
    let eventType: EventType
    let duration: TimeInterval

    enum EventType: String, Codable {
        case mathChallenge = "Unlocked · math solved"
        case dismissed = "Block dismissed"
        case blocked = "App blocked"
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
