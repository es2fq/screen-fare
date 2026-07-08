//
//  TemporaryUnlockManager.swift
//  Screen Fare
//
//  Manages temporary unlock state for apps and categories
//
//  ## Purpose
//  - Track temporary unlocks (apps and categories)
//  - Handle unlock/relock operations
//  - Manage unlock durations and start times
//  - Query remaining unlock time
//

import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class TemporaryUnlockManager: ObservableObject {
    // MARK: - Published State

    /// Active temporary unlocks: token data → expiry time
    @Published var temporaryUnlocks: [Data: Date] = [:]

    /// Active category unlocks: token data → expiry time
    @Published var temporaryCategoryUnlocks: [Data: Date] = [:]

    /// Original unlock durations: token data → duration
    @Published var unlockDurations: [Data: TimeInterval] = [:]

    /// Unlock start times: token data → start time
    @Published var unlockStartTimes: [Data: Date] = [:]

    /// Expiry time for UI countdown (legacy compatibility)
    @Published var unlockExpiryTime: Date?

    // MARK: - Dependencies

    private let sharedDefaults = UserDefaults.appGroup
    private let tokenCache: TokenCacheManager
    private let scheduling: DeviceActivitySchedulingManager
    private let persistence: BlockingPersistenceManager

    // MARK: - Initialization

    init(
        tokenCache: TokenCacheManager,
        scheduling: DeviceActivitySchedulingManager,
        persistence: BlockingPersistenceManager
    ) {
        self.tokenCache = tokenCache
        self.scheduling = scheduling
        self.persistence = persistence
    }

    // MARK: - App Unlock Operations

    /// Temporarily unlock an app for a specified duration
    func temporaryUnlock(appToken: ApplicationToken, duration: TimeInterval, isBlocking: Bool) {
        guard isBlocking else { return }
        guard let appTokenData = tokenCache.encodeAppToken(appToken) else { return }

        // Calculate start and end times
        let startTime = Date()
        let expiryTime = startTime.addingTimeInterval(duration)

        // Create unique activity name for this unlock
        let activityName = DeviceActivityName("unlock.\(UUID().uuidString)")

        // Store app token data in shared storage for the monitor extension
        sharedDefaults?.set(appTokenData, forKey: "deviceActivity.\(activityName.rawValue).appToken")

        // Store expiry timestamp and unlock flag for Shield Extension
        print("[TemporaryUnlockManager] 🔓 Creating unlock - start: \(startTime), expiry: \(expiryTime), duration: \(duration)s")
        sharedDefaults?.set(expiryTime.timeIntervalSince1970, forKey: "quotaEndTimestamp")
        sharedDefaults?.set(true, forKey: "isCurrentlyUnlocked")

        // Update temporary unlocks for UI tracking
        temporaryUnlocks[appTokenData] = expiryTime
        unlockDurations[appTokenData] = duration
        unlockStartTimes[appTokenData] = startTime

        print("[TemporaryUnlockManager] Saving unlock to UserDefaults")
        persistence.saveTemporaryUnlocks(
            appUnlocks: temporaryUnlocks,
            categoryUnlocks: temporaryCategoryUnlocks,
            unlockDurations: unlockDurations
        )

        // Schedule chaining for reliable re-locking
        scheduling.scheduleReblockChain(appTokenData: appTokenData, activityName: activityName, expiryTime: expiryTime)
    }

    /// Remove a temporary unlock (re-lock the app)
    func removeTemporaryUnlock(appTokenData: Data) {
        print("[TemporaryUnlockManager] 🔒 Removing unlock - had \(temporaryUnlocks.count) unlocks")

        // Stop monitoring if active
        scheduling.stopMonitoring(for: appTokenData)

        temporaryUnlocks.removeValue(forKey: appTokenData)
        unlockDurations.removeValue(forKey: appTokenData)
        unlockStartTimes.removeValue(forKey: appTokenData)

        print("[TemporaryUnlockManager] Now have \(temporaryUnlocks.count) unlocks, saving")
        persistence.saveTemporaryUnlocks(
            appUnlocks: temporaryUnlocks,
            categoryUnlocks: temporaryCategoryUnlocks,
            unlockDurations: unlockDurations
        )
    }

    /// Re-lock an app by immediately removing its temporary unlock
    func relockApp(appData: Data) {
        removeTemporaryUnlock(appTokenData: appData)
    }

    // MARK: - Category Unlock Operations

    /// Temporarily unlock a category for a specified duration
    func temporaryUnlockCategory(categoryToken: ActivityCategoryToken, duration: TimeInterval, isBlocking: Bool) {
        guard isBlocking else { return }
        guard let categoryTokenData = tokenCache.encodeCategoryToken(categoryToken) else { return }

        let startTime = Date()
        let expiryTime = startTime.addingTimeInterval(duration)

        // Create unique activity name for this category unlock
        let activityName = DeviceActivityName("unlock.category.\(UUID().uuidString)")

        // Store category token data in shared storage for the monitor extension
        sharedDefaults?.set(categoryTokenData, forKey: "deviceActivity.\(activityName.rawValue).categoryToken")

        // Update temporary category unlocks
        temporaryCategoryUnlocks[categoryTokenData] = expiryTime
        unlockDurations[categoryTokenData] = duration
        unlockStartTimes[categoryTokenData] = startTime
        persistence.saveTemporaryUnlocks(
            appUnlocks: temporaryUnlocks,
            categoryUnlocks: temporaryCategoryUnlocks,
            unlockDurations: unlockDurations
        )

        print("[TemporaryUnlockManager] 🔓 Category unlock started: expiry=\(expiryTime), remaining=\(Int(duration))s")

        // Schedule DeviceActivityMonitor for reliable re-locking
        scheduling.scheduleReblockChainForCategory(categoryTokenData: categoryTokenData, activityName: activityName, expiryTime: expiryTime)

        print("[TemporaryUnlockManager] ✓ Category temporarily unlocked for \(Int(duration / 60)) minutes")
    }

    /// Remove a temporary category unlock (re-lock the category)
    func removeTemporaryCategoryUnlock(categoryTokenData: Data) {
        // Stop monitoring if active
        scheduling.stopMonitoring(for: categoryTokenData)

        temporaryCategoryUnlocks.removeValue(forKey: categoryTokenData)
        unlockDurations.removeValue(forKey: categoryTokenData)
        unlockStartTimes.removeValue(forKey: categoryTokenData)
        persistence.saveTemporaryUnlocks(
            appUnlocks: temporaryUnlocks,
            categoryUnlocks: temporaryCategoryUnlocks,
            unlockDurations: unlockDurations
        )

        print("[TemporaryUnlockManager] 🔒 Category re-locked after temporary unlock expired")
    }

    /// Re-lock a category by immediately removing its temporary unlock
    func relockCategory(categoryData: Data) {
        removeTemporaryCategoryUnlock(categoryTokenData: categoryData)
    }

    // MARK: - Query Methods

    /// Get remaining time for an app unlock
    func remainingUnlockTime(for appToken: ApplicationToken) -> TimeInterval? {
        guard let appTokenData = tokenCache.encodeAppToken(appToken),
              let expiryTime = temporaryUnlocks[appTokenData],
              Date() < expiryTime else {
            return nil
        }
        return expiryTime.timeIntervalSince(Date())
    }

    // MARK: - Cleanup

    /// Remove expired unlocks and return true if state changed
    func cleanupExpiredUnlocks() -> Bool {
        let now = Date()
        let originalAppCount = temporaryUnlocks.count
        let originalCategoryCount = temporaryCategoryUnlocks.count

        print("[TemporaryUnlockManager] Starting cleanup at \(now)")
        print("[TemporaryUnlockManager] Current state: \(temporaryUnlocks.count) app unlocks, \(temporaryCategoryUnlocks.count) category unlocks")

        // Log each app unlock before filtering
        for (_, expiryTime) in temporaryUnlocks {
            let remaining = expiryTime.timeIntervalSince(now)
            let isExpired = expiryTime <= now
            print("[TemporaryUnlockManager]   App unlock: expires at \(expiryTime), remaining \(remaining)s, expired=\(isExpired)")
        }

        // Get expired app tokens
        let expiredTokens = temporaryUnlocks.filter { $0.value <= now }.map { $0.key }
        print("[TemporaryUnlockManager] Found \(expiredTokens.count) expired app unlocks")

        // Remove expired app unlocks
        temporaryUnlocks = temporaryUnlocks.filter { $0.value > now }

        // Also remove durations for expired unlocks
        for token in expiredTokens {
            unlockDurations.removeValue(forKey: token)
        }

        // Get expired category tokens
        let expiredCategoryTokens = temporaryCategoryUnlocks.filter { $0.value <= now }.map { $0.key }
        print("[TemporaryUnlockManager] Found \(expiredCategoryTokens.count) expired category unlocks")

        // Remove expired category unlocks
        temporaryCategoryUnlocks = temporaryCategoryUnlocks.filter { $0.value > now }

        // Also remove durations for expired category unlocks
        for token in expiredCategoryTokens {
            unlockDurations.removeValue(forKey: token)
        }

        let stateChanged = temporaryUnlocks.count != originalAppCount || temporaryCategoryUnlocks.count != originalCategoryCount

        if stateChanged {
            print("[TemporaryUnlockManager] State changed: \(originalAppCount) -> \(temporaryUnlocks.count) apps, \(originalCategoryCount) -> \(temporaryCategoryUnlocks.count) categories")
            persistence.saveTemporaryUnlocks(
                appUnlocks: temporaryUnlocks,
                categoryUnlocks: temporaryCategoryUnlocks,
                unlockDurations: unlockDurations
            )
        } else {
            print("[TemporaryUnlockManager] No changes needed")
        }

        return stateChanged
    }

    /// Clear all temporary unlocks (e.g., when blocking is turned off)
    func clearAllUnlocks() {
        temporaryUnlocks.removeAll()
        temporaryCategoryUnlocks.removeAll()
        unlockDurations.removeAll()
        unlockStartTimes.removeAll()
        persistence.saveTemporaryUnlocks(
            appUnlocks: [:],
            categoryUnlocks: [:],
            unlockDurations: [:]
        )
    }

    /// Load persisted unlock state
    func loadUnlocks() {
        print("[TemporaryUnlockManager] Starting load - current in-memory: \(temporaryUnlocks.count) apps, \(temporaryCategoryUnlocks.count) categories")

        let (appUnlocks, categoryUnlocks, durations) = persistence.loadTemporaryUnlocks()

        // Update in-memory state
        temporaryUnlocks = appUnlocks
        temporaryCategoryUnlocks = categoryUnlocks
        unlockDurations = durations
    }
}
