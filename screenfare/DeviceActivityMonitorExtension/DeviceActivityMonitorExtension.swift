//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Monitors device activity schedules and applies/removes shields
//  Runs independently of the main app - iOS calls this at scheduled times
//

import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Called when unlock period starts - REMOVE shield from this specific app
        print("[DeviceActivity] intervalDidStart for \(activity.rawValue)")

        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let appTokenData = sharedDefaults.data(forKey: "deviceActivity.\(activity.rawValue).appToken"),
              let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
            print("[DeviceActivity] Failed to load app token for \(activity.rawValue)")
            return
        }

        // Load all selected apps and categories
        var selectedTokens = Set<ApplicationToken>()
        var selectedCategories = Set<ActivityCategoryToken>()

        if let selectedAppsData = sharedDefaults.data(forKey: "com.screenfare.selectedApps"),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) {
            selectedTokens = tokens
        }

        if let selectedCategoriesData = sharedDefaults.data(forKey: "com.screenfare.selectedCategories"),
           let categories = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: selectedCategoriesData) {
            selectedCategories = categories
        }

        // REMOVE the unlocked app from shields so it can be accessed
        selectedTokens.remove(appToken)
        store.shield.applications = selectedTokens

        // Reapply category shields (unchanged)
        if !selectedCategories.isEmpty {
            store.shield.applicationCategories = .specific(selectedCategories)
        }

        print("[DeviceActivity] Removed app from shields, \(selectedTokens.count) apps + \(selectedCategories.count) categories still shielded")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Called when unlock period ends - RE-ADD app to shields
        print("[DeviceActivity] intervalDidEnd for \(activity.rawValue)")

        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let appTokenData = sharedDefaults.data(forKey: "deviceActivity.\(activity.rawValue).appToken"),
              let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
            print("[DeviceActivity] Failed to load app token for \(activity.rawValue)")
            return
        }

        // Remove from temporaryUnlocks
        if let data = sharedDefaults.data(forKey: "com.screenfare.temporaryUnlocks"),
           var unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) {
            unlocks.removeValue(forKey: appTokenData)
            if let encoded = try? JSONEncoder().encode(unlocks) {
                sharedDefaults.set(encoded, forKey: "com.screenfare.temporaryUnlocks")
                sharedDefaults.synchronize()
            }
        }

        // Load all selected apps and categories
        var selectedTokens = Set<ApplicationToken>()
        var selectedCategories = Set<ActivityCategoryToken>()

        if let selectedAppsData = sharedDefaults.data(forKey: "com.screenfare.selectedApps"),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) {
            selectedTokens = tokens
        }

        if let selectedCategoriesData = sharedDefaults.data(forKey: "com.screenfare.selectedCategories"),
           let categories = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: selectedCategoriesData) {
            selectedCategories = categories
        }

        // Re-apply ALL shields (including the one that just expired)
        store.shield.applications = selectedTokens

        // Reapply category shields
        if !selectedCategories.isEmpty {
            store.shield.applicationCategories = .specific(selectedCategories)
        }

        // Clean up schedule data
        sharedDefaults.removeObject(forKey: "deviceActivity.\(activity.rawValue).appToken")
        sharedDefaults.synchronize()

        print("[DeviceActivity] Re-added app to shields, \(selectedTokens.count) apps + \(selectedCategories.count) categories now shielded")
    }
}
