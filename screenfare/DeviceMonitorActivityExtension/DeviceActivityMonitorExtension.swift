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
    let sharedDefaults = UserDefaults.appGroup

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("[DeviceMonitor] intervalDidStart: \(activity.rawValue)")

        // Handle schedule window start
        if activity.rawValue.starts(with: "schedule.") {
            print("[DeviceMonitor] 🟢 Schedule window started, enabling Focus")
            enableFocus()
            return
        }

        // intervalDidStart not used for unlock monitoring
        // Re-locking handled by intervalWillEndWarning (short timers) and intervalDidEnd (long timers)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("[DeviceMonitor] intervalDidEnd: \(activity.rawValue)")

        // Handle schedule window end
        if activity.rawValue.starts(with: "schedule.") {
            print("[DeviceMonitor] 🔴 Schedule window ended, disabling Focus")
            disableFocus()
            clearAllTemporaryUnlocks()
            return
        }

        // For LONG timers (≥15 min), intervalDidEnd fires at actual expiry

        // Check if this is a category unlock
        if activity.rawValue.contains("unlock.category.") {
            print("[DeviceMonitor] 🔒 Category long timer expired (interval ended), re-locking category")

            // Load the category token that was unlocked
            guard let categoryTokenData = sharedDefaults?.data(forKey: "deviceActivity.\(activity.rawValue).categoryToken") else {
                print("[DeviceMonitor] ⚠️ Could not load category token")
                return
            }

            // Remove from temporary category unlocks
            if var unlocks = loadTemporaryCategoryUnlocks() {
                unlocks.removeValue(forKey: categoryTokenData)
                saveTemporaryCategoryUnlocks(unlocks)
            }

            // RE-ADD to shield store
            reapplyShields()

            print("[DeviceMonitor] ✓ Category re-locked via intervalDidEnd")
            return
        }

        // Handle app unlock
        print("[DeviceMonitor] 🔒 App long timer expired (interval ended), re-locking app")

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
    }

    private func loadTemporaryCategoryUnlocks() -> [Data: Date]? {
        guard let data = sharedDefaults?.data(forKey: "com.screenfare.temporaryCategoryUnlocks"),
              let unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) else {
            return nil
        }
        return unlocks
    }

    private func saveTemporaryCategoryUnlocks(_ unlocks: [Data: Date]) {
        guard let encoded = try? JSONEncoder().encode(unlocks) else { return }
        sharedDefaults?.set(encoded, forKey: "com.screenfare.temporaryCategoryUnlocks")
    }

    private func reapplyShields() {
        // Load all selected apps
        guard let selectedAppsData = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
              let selectedAppTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) else {
            print("[DeviceMonitor] ⚠️ Could not load selected apps")
            return
        }

        // Load selected categories
        var selectedCategoryTokens: Set<ActivityCategoryToken> = []
        if let selectedCategoriesData = sharedDefaults?.data(forKey: "com.screenfare.selectedCategories"),
           let categoryTokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: selectedCategoriesData) {
            selectedCategoryTokens = categoryTokens
        }

        // Load current unlocks
        let unlocks = loadTemporaryUnlocks() ?? [:]
        let categoryUnlocks = loadTemporaryCategoryUnlocks() ?? [:]
        let now = Date()

        // Calculate which apps should be blocked (exclude active unlocks)
        var blockedApps = selectedAppTokens
        for (appTokenData, expiryTime) in unlocks {
            if now < expiryTime, let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) {
                blockedApps.remove(appToken)
            }
        }

        // Calculate which categories should be blocked (exclude active unlocks)
        var blockedCategories = selectedCategoryTokens
        for (categoryTokenData, expiryTime) in categoryUnlocks {
            if now < expiryTime, let categoryToken = try? JSONDecoder().decode(ActivityCategoryToken.self, from: categoryTokenData) {
                blockedCategories.remove(categoryToken)
            }
        }

        // Apply shields (this will forcibly close any unlocked apps whose time expired)
        // Note: Keep shields active even if blockedApps is empty (all apps temporarily unlocked)
        // Setting to nil would disable focus mode entirely
        store.shield.applications = blockedApps

        // Apply category shields
        if !blockedCategories.isEmpty {
            store.shield.applicationCategories = .specific(blockedCategories)
        } else {
            store.shield.applicationCategories = nil
        }

        print("[DeviceMonitor] Shield reapplied to \(blockedApps.count) apps, \(blockedCategories.count) categories")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("[DeviceMonitor] eventDidReachThreshold: \(event.rawValue) for activity: \(activity.rawValue)")
        // Usage tracking removed - now using DeviceActivity comprehensive reporting
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

        // Check if this is a category unlock
        if activity.rawValue.contains("unlock.category.") {
            print("[DeviceMonitor] 🔒 Category short timer expired (warning fired), re-locking category")

            // Load the category token that was unlocked
            guard let categoryTokenData = sharedDefaults?.data(forKey: "deviceActivity.\(activity.rawValue).categoryToken") else {
                print("[DeviceMonitor] ⚠️ Could not load category token")
                return
            }

            // Remove from temporary category unlocks
            if var unlocks = loadTemporaryCategoryUnlocks() {
                unlocks.removeValue(forKey: categoryTokenData)
                saveTemporaryCategoryUnlocks(unlocks)
            }

            // RE-ADD to shield store
            reapplyShields()

            print("[DeviceMonitor] ✓ Category re-locked via intervalWillEndWarning")
            return
        }

        // Handle app unlock
        print("[DeviceMonitor] 🔒 App short timer expired (warning fired), re-locking app")

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

        // RE-ADD apps to shield store - this will kick user out immediately
        reapplyShields()

        print("[DeviceMonitor] ✓ App re-locked via intervalWillEndWarning")
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    // MARK: - Schedule Management

    private func enableFocus() {
        // Load selected apps from shared storage
        guard let selectedAppsData = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
              let selectedAppTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) else {
            print("[DeviceMonitor] ⚠️ Could not load selected apps for Focus enable")
            return
        }

        // Load selected categories
        var selectedCategoryTokens: Set<ActivityCategoryToken> = []
        if let selectedCategoriesData = sharedDefaults?.data(forKey: "com.screenfare.selectedCategories"),
           let categoryTokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: selectedCategoriesData) {
            selectedCategoryTokens = categoryTokens
        }

        // Respect existing temporary unlocks
        let unlocks = loadTemporaryUnlocks() ?? [:]
        let now = Date()
        var blockedApps = selectedAppTokens

        // Remove apps with active temporary unlocks
        for (appTokenData, expiryTime) in unlocks {
            if now < expiryTime, let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) {
                blockedApps.remove(appToken)
            }
        }

        // Load temporary category unlocks
        var temporaryCategoryUnlocks: [Data: Date] = [:]
        if let data = sharedDefaults?.data(forKey: "com.screenfare.temporaryCategoryUnlocks"),
           let unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) {
            temporaryCategoryUnlocks = unlocks
        }

        var blockedCategories = selectedCategoryTokens

        // Remove categories with active temporary unlocks
        for (categoryTokenData, expiryTime) in temporaryCategoryUnlocks {
            if now < expiryTime, let categoryToken = try? JSONDecoder().decode(ActivityCategoryToken.self, from: categoryTokenData) {
                blockedCategories.remove(categoryToken)
            }
        }

        // Apply shields (respecting temporary unlocks)
        store.shield.applications = blockedApps
        if !blockedCategories.isEmpty {
            store.shield.applicationCategories = .specific(blockedCategories)
        }

        // Set Focus enabled flag
        sharedDefaults?.set(true, forKey: "com.screenfare.blockedApps")

        print("[DeviceMonitor] ✅ Focus enabled: \(blockedApps.count) apps, \(blockedCategories.count) categories (respecting \(unlocks.count) app unlocks, \(temporaryCategoryUnlocks.count) category unlocks)")
    }

    private func disableFocus() {
        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        // Set Focus disabled flag
        sharedDefaults?.set(false, forKey: "com.screenfare.blockedApps")

        print("[DeviceMonitor] ✅ Focus disabled")
    }

    private func clearAllTemporaryUnlocks() {
        // Clear all temporary app unlocks
        sharedDefaults?.set(try? JSONEncoder().encode([Data: Date]()), forKey: "com.screenfare.temporaryUnlocks")

        // Clear all temporary category unlocks
        sharedDefaults?.set(try? JSONEncoder().encode([Data: Date]()), forKey: "com.screenfare.temporaryCategoryUnlocks")

        // Clear unlock durations
        sharedDefaults?.set(try? JSONEncoder().encode([Data: TimeInterval]()), forKey: "com.screenfare.unlockDurations")

        print("[DeviceMonitor] 🧹 Cleared all temporary unlocks")
    }
}
