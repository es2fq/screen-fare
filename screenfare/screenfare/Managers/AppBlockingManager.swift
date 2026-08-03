//
//  AppBlockingManager.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications
import BackgroundTasks
import UIKit
import ScreenFareShared

@MainActor
class AppBlockingManager: ObservableObject {
    static let shared = AppBlockingManager()

    let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults.appGroup
    private let temporaryUnlocksKey = "com.screenfare.temporaryUnlocks"
    private let unlockDurationsKey = "com.screenfare.unlockDurations"
    private let blockedAppsKey = "com.screenfare.blockedApps"

    // Token cache manager for encoding/decoding operations
    private let tokenCache = TokenCacheManager()

    // Persistence manager for UserDefaults I/O
    private let persistence = BlockingPersistenceManager()

    // Scheduling manager for DeviceActivity monitors
    private let scheduling = DeviceActivitySchedulingManager()

    // Temporary unlock manager for unlock/relock operations
    private lazy var unlockManager: TemporaryUnlockManager = {
        TemporaryUnlockManager(tokenCache: tokenCache, scheduling: scheduling, persistence: persistence)
    }()

    @Published var isAuthorized = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var blockedApps: FamilyActivitySelection?

    // Re-export unlock state from TemporaryUnlockManager for UI binding
    var unlockExpiryTime: Date? { unlockManager.unlockExpiryTime }
    var temporaryUnlocks: [Data: Date] { unlockManager.temporaryUnlocks }
    var unlockDurations: [Data: TimeInterval] { unlockManager.unlockDurations }
    var unlockStartTimes: [Data: Date] { unlockManager.unlockStartTimes }
    var temporaryCategoryUnlocks: [Data: Date] { unlockManager.temporaryCategoryUnlocks }

    var isBlocking: Bool {
        blockedApps != nil
    }

    var currentlyBlockedApps: Set<ApplicationToken> {
        guard isBlocking else { return [] }

        // Start with all selected apps
        var blocked = Set(selectedApps.applicationTokens)

        // Remove apps with active temporary unlocks (from unlock manager)
        let now = Date()
        for (appTokenData, expiryTime) in unlockManager.temporaryUnlocks {
            if now < expiryTime {
                // Use token cache for decoding
                if let token = tokenCache.decodeAppToken(from: appTokenData) {
                    blocked.remove(token)
                }
            }
        }

        return blocked
    }

    var currentlyBlockedCategories: Set<ActivityCategoryToken> {
        guard isBlocking else { return [] }

        // Start with all selected categories
        var blocked = Set(selectedApps.categoryTokens)

        // Remove categories with active temporary unlocks (from unlock manager)
        let now = Date()
        for (categoryTokenData, expiryTime) in unlockManager.temporaryCategoryUnlocks {
            if now < expiryTime {
                // Use token cache for decoding
                if let token = tokenCache.decodeCategoryToken(from: categoryTokenData) {
                    blocked.remove(token)
                }
            }
        }

        return blocked
    }

    private var scheduleChangeObserver: NSObjectProtocol?
    private var memoryWarningObserver: NSObjectProtocol?
    private var hasLoadedData = false

    private init() {
        // Check authorization status on init (no I/O)
        checkAuthorizationStatus()

        // Defer data loading to async context
        Task {
            await loadDataAsync()
        }

        // Listen for schedule changes
        scheduleChangeObserver = NotificationCenter.default.addObserver(
            forName: .scheduleDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleScheduleChange()
            }
        }

        // Listen for memory warnings to clear caches
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleMemoryWarning()
            }
        }
    }

    private func loadDataAsync() async {
        // Perform I/O operations on background thread
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Load persisted data
            await MainActor.run {
                self.loadSelectedApps()
                self.loadBlockedApps()
                self.loadTemporaryUnlocks()
                self.hasLoadedData = true
            }
        }.value
    }

    deinit {
        // Clean up NotificationCenter observers to prevent memory leaks
        if let observer = scheduleChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // Note: Token cache cleanup is handled by TokenCacheManager
    }

    func checkAuthorizationStatus() {
        let status = center.authorizationStatus

        switch status {
        case .approved:
            isAuthorized = true
        case .denied:
            isAuthorized = false
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            // Handle new authorization statuses (like "Approved with Data Access")
            // Treat any unknown status as authorized if it's not explicitly denied or notDetermined
            isAuthorized = true
        }
    }

    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
            throw error
        }
    }

    // MARK: - Persistence (Delegated to BlockingPersistenceManager)

    private func loadSelectedApps() {
        let selection = persistence.loadSelectedApps()

        // Only update if we loaded something (preserve original behavior)
        if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
            selectedApps = selection
        }
    }

    private func saveBlockedApps() {
        // Save a simple boolean flag for whether focus is on/off
        persistence.saveBlockingState(isBlocking: blockedApps != nil)
    }

    private func loadBlockedApps() {
        // Check if focus mode was active
        let focusWasOn = persistence.loadBlockingState()

        if focusWasOn && !selectedApps.applicationTokens.isEmpty {
            // Focus was on and we have selected apps - restore the blocking state
            blockedApps = selectedApps
        } else {
            // Focus was off
            blockedApps = nil
        }
    }

    func loadTemporaryUnlocks() {
        unlockManager.loadUnlocks()
    }


    // MARK: - Blocking Management

    func applyBlocking() {
        guard !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty else {
            return
        }

        // Store the blocked apps (triggers UI update immediately)
        blockedApps = selectedApps

        // Save blockedApps state to persist focus mode
        saveBlockedApps()

        // Setup schedule monitors for auto-enable/disable
        setupScheduleMonitoring()

        // Setup insights monitoring for screen time tracking
        setupInsightsMonitoring()

        // Save selected apps to shared storage (async on background thread)
        persistence.saveSelectedApps(selectedApps)

        // Apply shields on background thread, then switch to main actor
        Task.detached(priority: .userInitiated) {
            // Apply shields on main actor (only if within schedule)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if ScheduleManager.shared.isBlockingActive() {
                    self.recalculateShields()
                } else {
                    print("[AppBlockingManager] Outside schedule, shields will apply at next window start")
                }
            }
        }
    }

    private func recalculateShields() {
        print("[recalculateShields] 🛡️ Called - current unlocks: \(unlockManager.temporaryUnlocks.count) apps, \(unlockManager.temporaryCategoryUnlocks.count) categories")

        guard isBlocking else {
            // If blocking is off, clear all shields
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            return
        }

        // Clean up expired unlocks first
        cleanupExpiredUnlocks()

        // Calculate blocked apps/categories - this is done via computed properties
        // which already use caching, so they're relatively fast
        let blockedApps = currentlyBlockedApps
        let blockedCategories = currentlyBlockedCategories
        let webDomains = selectedApps.webDomainTokens

        // Apply shields - these must be on main thread as they touch ManagedSettings
        // But we've already done the heavy lifting (filtering/decoding) above
        store.shield.applications = blockedApps

        // Apply category shields, removing temporarily unlocked categories
        if !blockedCategories.isEmpty {
            store.shield.applicationCategories = .specific(blockedCategories)
        } else {
            store.shield.applicationCategories = nil
        }

        store.shield.webDomains = webDomains

        print("[AppBlockingManager] Shields applied to \(blockedApps.count) apps, \(blockedCategories.count) categories (\(temporaryUnlocks.count) apps + \(temporaryCategoryUnlocks.count) categories unlocked)")
    }

    func cleanupExpiredUnlocks() {
        // Delegate to unlock manager - it returns true if state changed
        let stateChanged = unlockManager.cleanupExpiredUnlocks()

        // Only recalculate shields if something changed
        if stateChanged {
            recalculateShields()
        }
    }

    func removeBlocking() {
        // Clear token caches
        tokenCache.clearTokenCaches()

        // Stop all unlock timers (delegated to scheduling manager)
        scheduling.stopAllUnlockTimers()

        // Stop schedule monitors (delegated to scheduling manager)
        stopScheduleMonitoring()

        // Stop insights monitoring (delegated to scheduling manager)
        stopInsightsMonitoring()

        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        blockedApps = nil

        // Save that focus is now off
        saveBlockedApps()

        // Clear all temporary unlocks (delegated to unlock manager)
        unlockManager.clearAllUnlocks()

        // selectedApps is preserved so when Focus turns back on, the list is intact
    }

    // MARK: - Cache Management (Delegated to TokenCacheManager)
    // Token encoding/decoding is now handled by TokenCacheManager

    func temporaryUnlock(appToken: ApplicationToken?, duration: TimeInterval) {
        guard let appToken = appToken else { return }

        // Delegate to unlock manager
        unlockManager.temporaryUnlock(appToken: appToken, duration: duration, isBlocking: isBlocking)

        // IMMEDIATELY update shields to remove this app
        recalculateShields()
    }

    private func removeTemporaryUnlock(appTokenData: Data) {
        // Delegate to unlock manager
        unlockManager.removeTemporaryUnlock(appTokenData: appTokenData)

        // Recalculate shields after removal
        recalculateShields()
    }

    /// Re-lock an app by immediately removing its temporary unlock
    func relockApp(appData: Data) {
        unlockManager.relockApp(appData: appData)
        recalculateShields()
    }

    /// Re-lock a category by immediately removing its temporary unlock
    func relockCategory(categoryData: Data) {
        unlockManager.relockCategory(categoryData: categoryData)
        recalculateShields()
    }

    // MARK: - Category Unlock

    func temporaryUnlockCategory(categoryToken: ActivityCategoryToken?, duration: TimeInterval) {
        guard let categoryToken = categoryToken else { return }

        // Delegate to unlock manager
        unlockManager.temporaryUnlockCategory(categoryToken: categoryToken, duration: duration, isBlocking: isBlocking)

        // IMMEDIATELY update shields to remove this category
        recalculateShields()
    }

    private func removeTemporaryCategoryUnlock(categoryTokenData: Data) {
        // Delegate to unlock manager
        unlockManager.removeTemporaryCategoryUnlock(categoryTokenData: categoryTokenData)

        // Recalculate shields after removal
        recalculateShields()
    }

    // MARK: - Unlock Time Query

    func remainingUnlockTime(for appToken: ApplicationToken) -> TimeInterval? {
        return unlockManager.remainingUnlockTime(for: appToken)
    }

    // MARK: - Schedule Monitoring (Delegated to DeviceActivitySchedulingManager)

    func setupScheduleMonitoring() {
        let schedule = ScheduleManager.shared.schedule
        scheduling.setupScheduleMonitoring(schedule: schedule)
    }

    func stopScheduleMonitoring() {
        scheduling.stopScheduleMonitoring()
    }

    // MARK: - Insights Monitoring (Delegated to DeviceActivitySchedulingManager)

    func setupInsightsMonitoring() {
        scheduling.setupInsightsMonitoring()
    }

    func stopInsightsMonitoring() {
        scheduling.stopInsightsMonitoring()
    }

    // MARK: - Schedule Change Handler

    private func handleScheduleChange() {
        // Only handle schedule changes if we have apps selected to block
        guard !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty else {
            return
        }

        print("[AppBlockingManager] Schedule changed, recreating monitors")

        // Stop old monitors first to avoid duplicates
        stopScheduleMonitoring()

        // Create new monitors with updated schedule
        setupScheduleMonitoring()

        // If currently outside schedule window, clear shields
        if !ScheduleManager.shared.isBlockingActive() {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("[AppBlockingManager] Outside schedule, cleared shields")
        } else {
            // Within schedule, ensure shields are applied
            // First set blockedApps to enable blocking
            blockedApps = selectedApps
            saveBlockedApps()

            // Save app/category tokens to shared storage so extensions can access them
            let appsToEncode = selectedApps.applicationTokens
            let categoriesToEncode = selectedApps.categoryTokens
            let defaults = sharedDefaults
            Task.detached(priority: .userInitiated) {
                // Save selectedApps to shared storage
                if let encoded = try? JSONEncoder().encode(appsToEncode) {
                    defaults?.set(encoded, forKey: "com.screenfare.selectedApps")
                }

                // Save selectedCategories to shared storage
                if let encoded = try? JSONEncoder().encode(categoriesToEncode) {
                    defaults?.set(encoded, forKey: "com.screenfare.selectedCategories")
                }

                // Apply shields on main actor after data is saved
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.recalculateShields()
                    print("[AppBlockingManager] Inside schedule, applied shields")
                }
            }
        }
    }

    // MARK: - Memory Management

    private func handleMemoryWarning() {
        print("[AppBlockingManager] ⚠️ Memory warning received, clearing caches")
        tokenCache.clearTokenCaches()
        print("[AppBlockingManager] ✓ Caches cleared to free memory")
    }
}
