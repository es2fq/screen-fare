//
//  BlockingPersistenceManager.swift
//  Screen Fare
//
//  Manages all UserDefaults persistence for blocking state
//
//  ## Purpose
//  - Save and load selected apps/categories
//  - Save and load blocking on/off state
//  - Save and load temporary unlock data
//  - Centralize all UserDefaults I/O operations
//

import Foundation
import FamilyControls
import ManagedSettings

@MainActor
class BlockingPersistenceManager {
    // MARK: - Properties

    private let sharedDefaults = UserDefaults.appGroup

    // Storage keys
    private let blockedAppsKey = "com.screenfare.blockedApps"
    private let temporaryUnlocksKey = "com.screenfare.temporaryUnlocks"
    private let unlockDurationsKey = "com.screenfare.unlockDurations"
    private let selectedAppsKey = "com.screenfare.selectedApps"
    private let selectedCategoriesKey = "com.screenfare.selectedCategories"
    private let temporaryCategoryUnlocksKey = "com.screenfare.temporaryCategoryUnlocks"

    // MARK: - Selected Apps Persistence

    /// Load persisted selected apps and categories
    func loadSelectedApps() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()

        // Load app tokens
        if let data = sharedDefaults?.data(forKey: selectedAppsKey),
           let appTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data),
           !appTokens.isEmpty {
            selection.applicationTokens = appTokens
        }

        // Load category tokens
        if let data = sharedDefaults?.data(forKey: selectedCategoriesKey),
           let categoryTokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: data),
           !categoryTokens.isEmpty {
            selection.categoryTokens = categoryTokens
        }

        return selection
    }

    /// Save selected apps and categories to shared storage
    /// Performs disk I/O on background thread for performance
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        let appsToEncode = selection.applicationTokens
        let categoriesToEncode = selection.categoryTokens
        let defaults = sharedDefaults

        Task.detached(priority: .userInitiated) {
            // Save selectedApps to shared storage (disk I/O on background thread)
            if let encoded = try? JSONEncoder().encode(appsToEncode) {
                defaults?.set(encoded, forKey: "com.screenfare.selectedApps")
            }

            // Save selectedCategories to shared storage
            if let encoded = try? JSONEncoder().encode(categoriesToEncode) {
                defaults?.set(encoded, forKey: "com.screenfare.selectedCategories")
            }
        }
    }

    // MARK: - Blocking State Persistence

    /// Load whether blocking was active
    func loadBlockingState() -> Bool {
        return sharedDefaults?.bool(forKey: blockedAppsKey) ?? false
    }

    /// Save blocking on/off state
    func saveBlockingState(isBlocking: Bool) {
        sharedDefaults?.set(isBlocking, forKey: blockedAppsKey)
    }

    // MARK: - Temporary Unlock Persistence

    /// Save temporary unlock state to UserDefaults
    func saveTemporaryUnlocks(
        appUnlocks: [Data: Date],
        categoryUnlocks: [Data: Date],
        unlockDurations: [Data: TimeInterval]
    ) {
        // Save app unlocks
        if let encoded = try? JSONEncoder().encode(appUnlocks) {
            sharedDefaults?.set(encoded, forKey: temporaryUnlocksKey)
        }

        // Save category unlocks
        if let encodedCategories = try? JSONEncoder().encode(categoryUnlocks) {
            sharedDefaults?.set(encodedCategories, forKey: temporaryCategoryUnlocksKey)
        }

        // Save durations
        if let encodedDurations = try? JSONEncoder().encode(unlockDurations) {
            sharedDefaults?.set(encodedDurations, forKey: unlockDurationsKey)
        }
    }

    /// Load temporary unlock state from UserDefaults
    func loadTemporaryUnlocks() -> (
        appUnlocks: [Data: Date],
        categoryUnlocks: [Data: Date],
        unlockDurations: [Data: TimeInterval]
    ) {
        var appUnlocks: [Data: Date] = [:]
        var categoryUnlocks: [Data: Date] = [:]
        var unlockDurations: [Data: TimeInterval] = [:]

        print("[BlockingPersistenceManager] Loading temporary unlocks")

        // Load app unlocks
        if let data = sharedDefaults?.data(forKey: temporaryUnlocksKey),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            print("[BlockingPersistenceManager] Loaded \(decoded.count) app unlocks from disk")
            for (_, expiryTime) in decoded {
                let remaining = expiryTime.timeIntervalSince(Date())
                print("[BlockingPersistenceManager]   - Unlock expires in \(remaining)s (at \(expiryTime))")
            }
            appUnlocks = decoded
        } else {
            print("[BlockingPersistenceManager] No app unlocks found in UserDefaults")
        }

        // Load category unlocks
        if let data = sharedDefaults?.data(forKey: temporaryCategoryUnlocksKey),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            print("[BlockingPersistenceManager] Loaded \(decoded.count) category unlocks from disk")
            categoryUnlocks = decoded
        }

        // Load durations
        if let durationsData = sharedDefaults?.data(forKey: unlockDurationsKey),
           let decodedDurations = try? JSONDecoder().decode([Data: TimeInterval].self, from: durationsData) {
            print("[BlockingPersistenceManager] Loaded \(decodedDurations.count) unlock durations")
            unlockDurations = decodedDurations
        }

        return (appUnlocks, categoryUnlocks, unlockDurations)
    }
}
