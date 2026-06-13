//
//  AppBlockingManager.swift
//  screenfare
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

@MainActor
class AppBlockingManager: ObservableObject {
    static let shared = AppBlockingManager()

    let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")
    private let temporaryUnlocksKey = "com.screenfare.temporaryUnlocks"
    private let unlockDurationsKey = "com.screenfare.unlockDurations"
    private let blockedAppsKey = "com.screenfare.blockedApps"
    private var activeMonitors: [Data: DeviceActivityName] = [:] // Track active device activity monitors
    private var activeScheduleMonitors: [DeviceActivityName] = [] // Track active schedule monitors

    @Published var isAuthorized = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var blockedApps: FamilyActivitySelection?
    @Published var unlockExpiryTime: Date?
    @Published var temporaryUnlocks: [Data: Date] = [:] // App/Category token data -> expiry time
    @Published var unlockDurations: [Data: TimeInterval] = [:] // App/Category token data -> original duration
    @Published var unlockStartTimes: [Data: Date] = [:] // App/Category token data -> when unlock started
    @Published var temporaryCategoryUnlocks: [Data: Date] = [:] // Category token data -> expiry time

    var isBlocking: Bool {
        blockedApps != nil
    }

    var currentlyBlockedApps: Set<ApplicationToken> {
        guard isBlocking else { return [] }

        // Start with all selected apps
        var blocked = Set(selectedApps.applicationTokens)

        // Remove apps with active temporary unlocks
        let now = Date()
        for (appTokenData, expiryTime) in temporaryUnlocks {
            if now < expiryTime,
               let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) {
                blocked.remove(appToken)
            }
        }

        return blocked
    }

    var currentlyBlockedCategories: Set<ActivityCategoryToken> {
        guard isBlocking else { return [] }

        // Start with all selected categories
        var blocked = Set(selectedApps.categoryTokens)

        // Remove categories with active temporary unlocks
        let now = Date()
        for (categoryTokenData, expiryTime) in temporaryCategoryUnlocks {
            if now < expiryTime,
               let categoryToken = try? JSONDecoder().decode(ActivityCategoryToken.self, from: categoryTokenData) {
                blocked.remove(categoryToken)
            }
        }

        return blocked
    }

    private init() {
        // Check authorization status on init
        checkAuthorizationStatus()

        // Load persisted selected apps first
        loadSelectedApps()

        // Load persisted blocked apps state
        loadBlockedApps()

        // Load persisted temporary unlocks
        loadTemporaryUnlocks()

        // Restart timers for any active unlocks
        restartExpiredTimers()

        // Listen for schedule changes
        NotificationCenter.default.addObserver(
            forName: .scheduleDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScheduleChange()
            }
        }
    }

    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        default:
            isAuthorized = false
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

    // MARK: - Persistence

    private func loadSelectedApps() {
        // Load the persisted selected apps
        var selection = FamilyActivitySelection()

        // Load app tokens
        if let data = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
           let appTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data),
           !appTokens.isEmpty {
            selection.applicationTokens = appTokens
        }

        // Load category tokens
        if let data = sharedDefaults?.data(forKey: "com.screenfare.selectedCategories"),
           let categoryTokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: data),
           !categoryTokens.isEmpty {
            selection.categoryTokens = categoryTokens
        }

        // Only update if we loaded something
        if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
            selectedApps = selection
        }
    }

    private func saveBlockedApps() {
        // Save a simple boolean flag for whether focus is on/off
        if blockedApps != nil {
            sharedDefaults?.set(true, forKey: blockedAppsKey)
        } else {
            sharedDefaults?.set(false, forKey: blockedAppsKey)
        }
        sharedDefaults?.synchronize()
    }

    private func loadBlockedApps() {
        // Check if focus mode was active
        let focusWasOn = sharedDefaults?.bool(forKey: blockedAppsKey) ?? false

        if focusWasOn && !selectedApps.applicationTokens.isEmpty {
            // Focus was on and we have selected apps - restore the blocking state
            blockedApps = selectedApps
        } else {
            // Focus was off
            blockedApps = nil
        }
    }

    private func saveTemporaryUnlocks() {
        // Save app unlocks
        guard let encoded = try? JSONEncoder().encode(temporaryUnlocks) else { return }
        sharedDefaults?.set(encoded, forKey: temporaryUnlocksKey)

        // Save category unlocks
        guard let encodedCategories = try? JSONEncoder().encode(temporaryCategoryUnlocks) else { return }
        sharedDefaults?.set(encodedCategories, forKey: "com.screenfare.temporaryCategoryUnlocks")

        // Save durations
        guard let encodedDurations = try? JSONEncoder().encode(unlockDurations) else { return }
        sharedDefaults?.set(encodedDurations, forKey: unlockDurationsKey)

        sharedDefaults?.synchronize()
    }

    func loadTemporaryUnlocks() {
        // Load app unlocks
        if let data = sharedDefaults?.data(forKey: temporaryUnlocksKey),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            temporaryUnlocks = decoded
        }

        // Load category unlocks
        if let data = sharedDefaults?.data(forKey: "com.screenfare.temporaryCategoryUnlocks"),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            temporaryCategoryUnlocks = decoded
        }

        // Load durations
        if let durationsData = sharedDefaults?.data(forKey: unlockDurationsKey),
           let decodedDurations = try? JSONDecoder().decode([Data: TimeInterval].self, from: durationsData) {
            unlockDurations = decodedDurations
        }
    }

    func restartExpiredTimers() {
        let now = Date()
        var needsRecalculation = false

        // Restart app unlock timers
        for (appTokenData, expiryTime) in temporaryUnlocks {
            let remaining = expiryTime.timeIntervalSince(now)

            if remaining > 0 {
                // Unlock is still active, restart timer
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                    await MainActor.run {
                        self.removeTemporaryUnlock(appTokenData: appTokenData)
                    }
                }
            } else {
                // Already expired, remove immediately
                temporaryUnlocks.removeValue(forKey: appTokenData)
                needsRecalculation = true
            }
        }

        // Restart category unlock timers
        for (categoryTokenData, expiryTime) in temporaryCategoryUnlocks {
            let remaining = expiryTime.timeIntervalSince(now)

            if remaining > 0 {
                // Unlock is still active, restart timer
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                    await MainActor.run {
                        self.removeTemporaryCategoryUnlock(categoryTokenData: categoryTokenData)
                    }
                }
            } else {
                // Already expired, remove immediately
                temporaryCategoryUnlocks.removeValue(forKey: categoryTokenData)
                needsRecalculation = true
            }
        }

        if needsRecalculation {
            saveTemporaryUnlocks()
            recalculateShields()
        }
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

        // Move all heavy work to background to keep UI responsive
        let appsToEncode = selectedApps.applicationTokens
        let categoriesToEncode = selectedApps.categoryTokens
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Save selectedApps to shared storage (disk I/O on background thread)
            if let encoded = try? JSONEncoder().encode(appsToEncode) {
                await self.sharedDefaults?.set(encoded, forKey: "com.screenfare.selectedApps")
            }

            // Save selectedCategories to shared storage
            if let encoded = try? JSONEncoder().encode(categoriesToEncode) {
                await self.sharedDefaults?.set(encoded, forKey: "com.screenfare.selectedCategories")
            }

            await self.sharedDefaults?.synchronize()

            // Apply shields on main actor (only if within schedule)
            await MainActor.run {
                if ScheduleManager.shared.isBlockingActive() {
                    self.recalculateShields()
                } else {
                    print("[AppBlockingManager] Outside schedule, shields will apply at next window start")
                }
            }
        }
    }

    private func recalculateShields() {
        guard isBlocking else {
            // If blocking is off, clear all shields
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            return
        }

        // Clean up expired unlocks first
        cleanupExpiredUnlocks()

        // REMOVE unlocked apps from shield store (genuine unblock)
        // When timer expires, DeviceActivity Monitor will re-add them
        store.shield.applications = currentlyBlockedApps

        // Apply category shields, removing temporarily unlocked categories
        if !currentlyBlockedCategories.isEmpty {
            store.shield.applicationCategories = .specific(currentlyBlockedCategories)
        } else {
            store.shield.applicationCategories = nil
        }

        store.shield.webDomains = selectedApps.webDomainTokens

        print("[AppBlockingManager] Shields applied to \(currentlyBlockedApps.count) apps, \(currentlyBlockedCategories.count) categories (\(temporaryUnlocks.count) apps + \(temporaryCategoryUnlocks.count) categories unlocked)")
    }

    func cleanupExpiredUnlocks() {
        let now = Date()
        let originalAppCount = temporaryUnlocks.count
        let originalCategoryCount = temporaryCategoryUnlocks.count

        // Get expired app tokens
        let expiredTokens = temporaryUnlocks.filter { $0.value <= now }.map { $0.key }

        // Remove expired app unlocks
        temporaryUnlocks = temporaryUnlocks.filter { $0.value > now }

        // Also remove durations for expired unlocks
        for token in expiredTokens {
            unlockDurations.removeValue(forKey: token)
        }

        // Get expired category tokens
        let expiredCategoryTokens = temporaryCategoryUnlocks.filter { $0.value <= now }.map { $0.key }

        // Remove expired category unlocks
        temporaryCategoryUnlocks = temporaryCategoryUnlocks.filter { $0.value > now }

        // Also remove durations for expired category unlocks
        for token in expiredCategoryTokens {
            unlockDurations.removeValue(forKey: token)
        }

        if temporaryUnlocks.count != originalAppCount || temporaryCategoryUnlocks.count != originalCategoryCount {
            saveTemporaryUnlocks()
            recalculateShields()
        }
    }

    func removeBlocking() {
        // Stop all active device activity monitors
        for (_, activityName) in activeMonitors {
            activityCenter.stopMonitoring([activityName])
        }
        activeMonitors.removeAll()

        // Stop schedule monitors
        stopScheduleMonitoring()

        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        unlockExpiryTime = nil
        blockedApps = nil

        // Save that focus is now off
        saveBlockedApps()

        // Clear all temporary unlocks (user manually turned off Focus)
        temporaryUnlocks.removeAll()
        temporaryCategoryUnlocks.removeAll()
        unlockDurations.removeAll()
        saveTemporaryUnlocks()

        // selectedApps is preserved so when Focus turns back on, the list is intact
    }

    func temporaryUnlock(appToken: ApplicationToken?, duration: TimeInterval) {
        guard let appToken = appToken else { return }
        guard isBlocking else { return }
        guard let appTokenData = try? JSONEncoder().encode(appToken) else { return }

        // Calculate start and end times
        let startTime = Date()
        let _ = startTime.addingTimeInterval(duration) // endTime unused

        // Create unique activity name for this unlock
        let activityName = DeviceActivityName("unlock.\(UUID().uuidString)")

        // Store app token data in shared storage for the monitor extension
        sharedDefaults?.set(appTokenData, forKey: "deviceActivity.\(activityName.rawValue).appToken")

        // Store expiry timestamp and unlock flag for Shield Extension
        let expiryTime = Date().addingTimeInterval(duration)
        sharedDefaults?.set(expiryTime.timeIntervalSince1970, forKey: "quotaEndTimestamp")
        sharedDefaults?.set(true, forKey: "isCurrentlyUnlocked")

        // Store usage tracking info
        let usageEventName = DeviceActivityEvent.Name("usage.\(activityName.rawValue)")
        sharedDefaults?.set(usageEventName.rawValue, forKey: "deviceActivity.\(activityName.rawValue).usageEvent")
        sharedDefaults?.synchronize()

        // Track this monitor
        activeMonitors[appTokenData] = activityName

        // Update temporary unlocks for UI tracking
        temporaryUnlocks[appTokenData] = expiryTime
        unlockDurations[appTokenData] = duration
        unlockStartTimes[appTokenData] = startTime // Track when unlock started
        saveTemporaryUnlocks()

        // Schedule chaining for reliable re-locking (especially for short timers)
        scheduleReblockChain(appTokenData: appTokenData, activityName: activityName, expiryTime: expiryTime)

        // IMMEDIATELY update shields to remove this app
        recalculateShields()
    }

    private func removeTemporaryUnlock(appTokenData: Data) {
        // Note: Time tracking is now handled by DeviceActivityMonitor.eventDidReachThreshold()
        // which fires every minute the app is actually used

        // Stop monitoring if active
        if let activityName = activeMonitors[appTokenData] {
            activityCenter.stopMonitoring([activityName])
            activeMonitors.removeValue(forKey: appTokenData)
        }

        temporaryUnlocks.removeValue(forKey: appTokenData)
        unlockDurations.removeValue(forKey: appTokenData)
        unlockStartTimes.removeValue(forKey: appTokenData)
        saveTemporaryUnlocks()
        recalculateShields()
    }

    /// Re-lock an app by immediately removing its temporary unlock
    func relockApp(appData: Data) {
        removeTemporaryUnlock(appTokenData: appData)
    }

    /// Re-lock a category by immediately removing its temporary unlock
    func relockCategory(categoryData: Data) {
        removeTemporaryCategoryUnlock(categoryTokenData: categoryData)
    }

    // MARK: - Category Unlock

    func temporaryUnlockCategory(categoryToken: ActivityCategoryToken?, duration: TimeInterval) {
        guard let categoryToken = categoryToken else { return }
        guard isBlocking else { return }
        guard let categoryTokenData = try? JSONEncoder().encode(categoryToken) else { return }

        let startTime = Date()
        let expiryTime = startTime.addingTimeInterval(duration)

        // Update temporary category unlocks (matching app unlock behavior)
        temporaryCategoryUnlocks[categoryTokenData] = expiryTime
        unlockDurations[categoryTokenData] = duration
        unlockStartTimes[categoryTokenData] = startTime
        saveTemporaryUnlocks()

        print("[AppBlockingManager] 🔓 Category unlock started: expiry=\(expiryTime), remaining=\(Int(duration))s")

        // Schedule timer to remove unlock when it expires
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                self.removeTemporaryCategoryUnlock(categoryTokenData: categoryTokenData)
            }
        }

        // IMMEDIATELY update shields to remove this category
        recalculateShields()

        print("[AppBlockingManager] ✓ Category temporarily unlocked for \(Int(duration / 60)) minutes")
    }

    private func removeTemporaryCategoryUnlock(categoryTokenData: Data) {
        temporaryCategoryUnlocks.removeValue(forKey: categoryTokenData)
        unlockDurations.removeValue(forKey: categoryTokenData)
        unlockStartTimes.removeValue(forKey: categoryTokenData)
        saveTemporaryUnlocks()
        recalculateShields()

        print("[AppBlockingManager] 🔒 Category re-locked after temporary unlock expired")
    }

    /// Schedule DeviceActivity monitor to re-lock at expiry time
    /// For short timers (<15 min), uses warningTime trick
    /// For long timers (≥15 min), uses direct intervalDidEnd
    private func scheduleReblockChain(appTokenData: Data, activityName: DeviceActivityName, expiryTime: Date) {
        let duration = expiryTime.timeIntervalSinceNow

        guard duration > 0 else {
            print("[AppBlockingManager] ⚠️ Expiry time already passed")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // THE TRICK: For short unlocks, set interval to 15 min but use warningTime
        // to fire at the actual expiry time
        if duration < 15 * 60 {
            // Short timer: Use warningTime trick (like Opal/Jomo)
            let intervalEnd = now.addingTimeInterval(15 * 60) // Always 15 min (minimum)
            let warningMinutes = Int((15 * 60 - duration) / 60) // Fire warning at actual expiry

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false,
                warningTime: DateComponents(minute: warningMinutes) // Fires at actual expiry
            )

            // Create usage tracking event (fires every 1 minute of actual app use)
            guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
                return
            }

            let usageEventName = DeviceActivityEvent.Name("usage.\(activityName.rawValue)")
            let usageEvent = DeviceActivityEvent(
                applications: [appToken],
                threshold: DateComponents(minute: 1) // Track every 1 minute of usage
            )

            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
                usageEventName: usageEvent
            ]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Short timer with usage tracking: interval=15min, warningTime=\(warningMinutes)min (fires in \(Int(duration))s)")
            } catch {
                print("[AppBlockingManager] ⚠️ Failed to schedule: \(error)")
            }
        } else {
            // Long timer: Use direct intervalDidEnd
            let intervalEnd = expiryTime

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false
            )

            // Create usage tracking event (fires every 1 minute of actual app use)
            guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
                return
            }

            let usageEventName = DeviceActivityEvent.Name("usage.\(activityName.rawValue)")
            let usageEvent = DeviceActivityEvent(
                applications: [appToken],
                threshold: DateComponents(minute: 1) // Track every 1 minute of usage
            )

            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
                usageEventName: usageEvent
            ]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Long timer with usage tracking: interval ends in \(Int(duration))s")
            } catch {
                print("[AppBlockingManager] ⚠️ Failed to schedule: \(error)")
            }
        }
    }

    func remainingUnlockTime(for appToken: ApplicationToken) -> TimeInterval? {
        guard let appTokenData = try? JSONEncoder().encode(appToken),
              let expiryTime = temporaryUnlocks[appTokenData],
              Date() < expiryTime else {
            return nil
        }
        return expiryTime.timeIntervalSince(Date())
    }

    // MARK: - Schedule Monitoring

    func setupScheduleMonitoring() {
        let schedule = ScheduleManager.shared.schedule

        // Only setup monitors if in scheduled mode
        guard schedule.mode == .scheduled else {
            print("[AppBlockingManager] Schedule mode is 'all day', no monitors needed")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        for window in schedule.windows {
            // Convert minutes to hour/minute components
            let startHour = window.start / 60
            let startMinute = window.start % 60
            let endHour = window.end / 60
            let endMinute = window.end % 60

            // Check if this is an overnight window (e.g., 10 PM - 2 AM)
            if window.end < window.start {
                // Split into two monitors:
                // 1. Same-day portion: start time - 11:59 PM
                // 2. Next-day portion: 12:00 AM - end time

                // Monitor 1: start - 23:59
                let activityName1 = DeviceActivityName("schedule.\(window.id).part1")
                let start1 = DateComponents(hour: startHour, minute: startMinute)
                let end1 = DateComponents(hour: 23, minute: 59)

                let deviceSchedule1 = DeviceActivitySchedule(
                    intervalStart: start1,
                    intervalEnd: end1,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName1, during: deviceSchedule1)
                    activeScheduleMonitors.append(activityName1)
                    print("[AppBlockingManager] ✅ Schedule monitor created (part 1): \(window.id) (\(startHour):\(String(format: "%02d", startMinute)) - 23:59)")
                } catch {
                    print("[AppBlockingManager] ⚠️ Failed to create schedule monitor part 1: \(error)")
                }

                // Monitor 2: 00:00 - end time
                let activityName2 = DeviceActivityName("schedule.\(window.id).part2")
                let start2 = DateComponents(hour: 0, minute: 0)
                let end2 = DateComponents(hour: endHour, minute: endMinute)

                let deviceSchedule2 = DeviceActivitySchedule(
                    intervalStart: start2,
                    intervalEnd: end2,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName2, during: deviceSchedule2)
                    activeScheduleMonitors.append(activityName2)
                    print("[AppBlockingManager] ✅ Schedule monitor created (part 2): \(window.id) (00:00 - \(endHour):\(String(format: "%02d", endMinute)))")
                } catch {
                    print("[AppBlockingManager] ⚠️ Failed to create schedule monitor part 2: \(error)")
                }
            } else {
                // Normal same-day window
                let activityName = DeviceActivityName("schedule.\(window.id)")
                let start = DateComponents(hour: startHour, minute: startMinute)
                let end = DateComponents(hour: endHour, minute: endMinute)

                let deviceSchedule = DeviceActivitySchedule(
                    intervalStart: start,
                    intervalEnd: end,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName, during: deviceSchedule)
                    activeScheduleMonitors.append(activityName)
                    print("[AppBlockingManager] ✅ Schedule monitor created: \(window.id) (\(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute)))")
                } catch {
                    print("[AppBlockingManager] ⚠️ Failed to create schedule monitor: \(error)")
                }
            }
        }
    }

    func stopScheduleMonitoring() {
        // Stop all tracked schedule monitors (handles deleted/changed windows)
        if !activeScheduleMonitors.isEmpty {
            activityCenter.stopMonitoring(activeScheduleMonitors)
            print("[AppBlockingManager] 🛑 Stopped \(activeScheduleMonitors.count) schedule monitors")
            activeScheduleMonitors.removeAll()
        }
    }

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
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self = self else { return }

                // Save selectedApps to shared storage
                if let encoded = try? JSONEncoder().encode(appsToEncode) {
                    await self.sharedDefaults?.set(encoded, forKey: "com.screenfare.selectedApps")
                }

                // Save selectedCategories to shared storage
                if let encoded = try? JSONEncoder().encode(categoriesToEncode) {
                    await self.sharedDefaults?.set(encoded, forKey: "com.screenfare.selectedCategories")
                }

                await self.sharedDefaults?.synchronize()

                // Apply shields on main actor after data is saved
                await MainActor.run {
                    self.recalculateShields()
                    print("[AppBlockingManager] Inside schedule, applied shields")
                }
            }
        }
    }
}
