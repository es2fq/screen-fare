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

        // Load all selected apps
        guard let selectedAppsData = sharedDefaults.data(forKey: "com.screenfare.selectedApps"),
              var selectedTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) else {
            print("[DeviceActivity] Failed to load selected apps")
            return
        }

        // REMOVE the unlocked app from shields so it can be accessed
        selectedTokens.remove(appToken)
        store.shield.applications = selectedTokens

        print("[DeviceActivity] Removed app from shields, \(selectedTokens.count) apps still shielded")
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

        // Load all selected apps and RE-ADD the app that was temporarily unlocked
        guard let selectedAppsData = sharedDefaults.data(forKey: "com.screenfare.selectedApps"),
              let selectedTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: selectedAppsData) else {
            print("[DeviceActivity] Failed to load selected apps")
            return
        }

        // Re-apply ALL shields (including the one that just expired)
        store.shield.applications = selectedTokens

        // Clean up schedule data
        sharedDefaults.removeObject(forKey: "deviceActivity.\(activity.rawValue).appToken")
        sharedDefaults.synchronize()

        print("[DeviceActivity] Re-added app to shields, \(selectedTokens.count) apps now shielded")
    }
}
