//
//  DeviceActivityMonitorExtension.swift
//  DeviceMonitorActivityExtension
//
//  Created by Erik Song on 6/10/26.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// This extension runs with system privileges and can forcibly lock apps
// even when the user is actively using them
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("[DeviceMonitor] intervalDidStart: \(activity.rawValue)")
        // intervalDidStart not used in current implementation
        // Re-locking handled by intervalWillEndWarning (short timers) and intervalDidEnd (long timers)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("[DeviceMonitor] intervalDidEnd: \(activity.rawValue)")

        // For LONG timers (≥15 min), intervalDidEnd fires at actual expiry
        print("[DeviceMonitor] 🔒 Long timer expired (interval ended), re-locking app")

        guard sharedDefaults?.bool(forKey: "isCurrentlyUnlocked") == true else {
            print("[DeviceMonitor] Already locked, skipping")
            return
        }

        // Load the app token that was unlocked
        guard let appTokenData = sharedDefaults?.data(forKey: "deviceActivity.\(activity.rawValue).appToken") else {
            print("[DeviceMonitor] ⚠️ Could not load app token")
            return
        }

        // Remove from temporary unlocks
        if var unlocks = loadTemporaryUnlocks() {
            unlocks.removeValue(forKey: appTokenData)
            saveTemporaryUnlocks(unlocks)
        }

        // Clear unlock flag
        sharedDefaults?.set(false, forKey: "isCurrentlyUnlocked")
        sharedDefaults?.synchronize()

        // RE-ADD apps to shield store - this will kick user out immediately
        reapplyShields()

        print("[DeviceMonitor] ✓ App re-locked via intervalDidEnd")
    }

    private func loadTemporaryUnlocks() -> [Data: Date]? {
        guard let data = sharedDefaults?.data(forKey: "com.screenfare.temporaryUnlocks"),
              let unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) else {
            return nil
        }
        return unlocks
    }

    private func saveTemporaryUnlocks(_ unlocks: [Data: Date]) {
        guard let encoded = try? JSONEncoder().encode(unlocks) else { return }
        sharedDefaults?.set(encoded, forKey: "com.screenfare.temporaryUnlocks")
        sharedDefaults?.synchronize()
    }

    private func reapplyShields() {
        // Load all selected apps
        guard let selectedAppsData = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
              let selectedAppTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) else {
            print("[DeviceMonitor] ⚠️ Could not load selected apps")
            return
        }

        // Load current unlocks
        let unlocks = loadTemporaryUnlocks() ?? [:]
        let now = Date()

        // Calculate which apps should be blocked (exclude active unlocks)
        var blockedApps = selectedAppTokens
        for (appTokenData, expiryTime) in unlocks {
            if now < expiryTime, let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) {
                blockedApps.remove(appToken)
            }
        }

        // Apply shields (this will forcibly close any unlocked apps whose time expired)
        store.shield.applications = blockedApps.isEmpty ? nil : blockedApps

        print("[DeviceMonitor] Shield reapplied to \(blockedApps.count) apps")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("[DeviceMonitor] eventDidReachThreshold: \(event.rawValue) for activity: \(activity.rawValue)")

        // Check if this is a usage tracking event
        if event.rawValue.starts(with: "usage.") {
            // User spent 1 minute using the app - record it
            recordTimeSpent(seconds: 60)
            print("[DeviceMonitor] ⏱️ Recorded 1 minute of app usage")
        }
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("[DeviceMonitor] ⏰ intervalWillEndWarning: \(activity.rawValue)")

        // Skip background monitoring
        if activity.rawValue == "background.expiry.monitor" {
            return
        }

        // THE KEY: For short timers, this fires at the actual expiry time
        // (warningTime trick - interval is 15min but warning fires at desired time)
        print("[DeviceMonitor] 🔒 Short timer expired (warning fired), re-locking app")

        guard sharedDefaults?.bool(forKey: "isCurrentlyUnlocked") == true else {
            print("[DeviceMonitor] Already locked, skipping")
            return
        }

        // Load the app token that was unlocked
        guard let appTokenData = sharedDefaults?.data(forKey: "deviceActivity.\(activity.rawValue).appToken") else {
            print("[DeviceMonitor] ⚠️ Could not load app token")
            return
        }

        // Remove from temporary unlocks
        if var unlocks = loadTemporaryUnlocks() {
            unlocks.removeValue(forKey: appTokenData)
            saveTemporaryUnlocks(unlocks)
        }

        // Clear unlock flag
        sharedDefaults?.set(false, forKey: "isCurrentlyUnlocked")
        sharedDefaults?.synchronize()

        // RE-ADD apps to shield store - this will kick user out immediately
        reapplyShields()

        print("[DeviceMonitor] ✓ App re-locked via intervalWillEndWarning")
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    private func recordTimeSpent(seconds: TimeInterval) {
        let storageKey = "com.screenfare.dailyStats"
        let today = todayDateString()

        var stats: DailyStats

        // Read existing stats
        if let data = sharedDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            stats = decoded
        } else {
            stats = DailyStats(date: today)
        }

        // Add time spent
        stats.timeSpentSeconds += Int(seconds)

        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(stats) {
            sharedDefaults?.set(encoded, forKey: storageKey)
            sharedDefaults?.synchronize()
            print("[DeviceMonitor] 📊 Time spent recorded: \(stats.timeSpentSeconds)s total")
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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
