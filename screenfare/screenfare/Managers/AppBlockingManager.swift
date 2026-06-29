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

    // Cache for decoded tokens to avoid repeated JSON decoding
    private var decodedAppTokenCache: [Data: ApplicationToken] = [:]
    private var decodedCategoryTokenCache: [Data: ActivityCategoryToken] = [:]

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
            if now < expiryTime {
                // Use cached token if available, otherwise decode and cache
                let appToken: ApplicationToken?
                if let cached = decodedAppTokenCache[appTokenData] {
                    appToken = cached
                } else if let decoded = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) {
                    decodedAppTokenCache[appTokenData] = decoded
                    appToken = decoded
                } else {
                    appToken = nil
                }

                if let token = appToken {
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

        // Remove categories with active temporary unlocks
        let now = Date()
        for (categoryTokenData, expiryTime) in temporaryCategoryUnlocks {
            if now < expiryTime {
                // Use cached token if available, otherwise decode and cache
                let categoryToken: ActivityCategoryToken?
                if let cached = decodedCategoryTokenCache[categoryTokenData] {
                    categoryToken = cached
                } else if let decoded = try? JSONDecoder().decode(ActivityCategoryToken.self, from: categoryTokenData) {
                    decodedCategoryTokenCache[categoryTokenData] = decoded
                    categoryToken = decoded
                } else {
                    categoryToken = nil
                }

                if let token = categoryToken {
                    blocked.remove(token)
                }
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

        // Note: Re-locking is handled by DeviceActivityMonitor (no need to restart timers)

        // Listen for schedule changes
        NotificationCenter.default.addObserver(
            forName: .scheduleDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleScheduleChange()
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
    }

    func loadTemporaryUnlocks() {
        print("[loadTemporaryUnlocks] Starting load - current in-memory: \(temporaryUnlocks.count) apps, \(temporaryCategoryUnlocks.count) categories")

        // Load app unlocks
        if let data = sharedDefaults?.data(forKey: temporaryUnlocksKey),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            print("[loadTemporaryUnlocks] Loaded \(decoded.count) app unlocks from disk")
            for (_, expiryTime) in decoded {
                let remaining = expiryTime.timeIntervalSince(Date())
                print("[loadTemporaryUnlocks]   - Unlock expires in \(remaining)s (at \(expiryTime))")
            }
            temporaryUnlocks = decoded
        } else {
            print("[loadTemporaryUnlocks] No app unlocks found in UserDefaults")
        }

        // Load category unlocks
        if let data = sharedDefaults?.data(forKey: "com.screenfare.temporaryCategoryUnlocks"),
           let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) {
            print("[loadTemporaryUnlocks] Loaded \(decoded.count) category unlocks from disk")
            temporaryCategoryUnlocks = decoded
        }

        // Load durations
        if let durationsData = sharedDefaults?.data(forKey: unlockDurationsKey),
           let decodedDurations = try? JSONDecoder().decode([Data: TimeInterval].self, from: durationsData) {
            print("[loadTemporaryUnlocks] Loaded \(decodedDurations.count) unlock durations")
            unlockDurations = decodedDurations
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

        // Setup insights monitoring for screen time tracking
        setupInsightsMonitoring()

        // Move all heavy work to background to keep UI responsive
        let appsToEncode = selectedApps.applicationTokens
        let categoriesToEncode = selectedApps.categoryTokens
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
        print("[recalculateShields] 🛡️ Called - current unlocks: \(temporaryUnlocks.count) apps, \(temporaryCategoryUnlocks.count) categories")

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

        print("[cleanupExpiredUnlocks] Starting cleanup at \(now)")
        print("[cleanupExpiredUnlocks] Current state: \(temporaryUnlocks.count) app unlocks, \(temporaryCategoryUnlocks.count) category unlocks")

        // Log each app unlock before filtering
        for (_, expiryTime) in temporaryUnlocks {
            let remaining = expiryTime.timeIntervalSince(now)
            let isExpired = expiryTime <= now
            print("[cleanupExpiredUnlocks]   App unlock: expires at \(expiryTime), remaining \(remaining)s, expired=\(isExpired)")
        }

        // Get expired app tokens
        let expiredTokens = temporaryUnlocks.filter { $0.value <= now }.map { $0.key }
        print("[cleanupExpiredUnlocks] Found \(expiredTokens.count) expired app unlocks")

        // Remove expired app unlocks
        temporaryUnlocks = temporaryUnlocks.filter { $0.value > now }

        // Also remove durations for expired unlocks
        for token in expiredTokens {
            unlockDurations.removeValue(forKey: token)
        }

        // Get expired category tokens
        let expiredCategoryTokens = temporaryCategoryUnlocks.filter { $0.value <= now }.map { $0.key }
        print("[cleanupExpiredUnlocks] Found \(expiredCategoryTokens.count) expired category unlocks")

        // Remove expired category unlocks
        temporaryCategoryUnlocks = temporaryCategoryUnlocks.filter { $0.value > now }

        // Also remove durations for expired category unlocks
        for token in expiredCategoryTokens {
            unlockDurations.removeValue(forKey: token)
        }

        if temporaryUnlocks.count != originalAppCount || temporaryCategoryUnlocks.count != originalCategoryCount {
            print("[cleanupExpiredUnlocks] State changed: \(originalAppCount) -> \(temporaryUnlocks.count) apps, \(originalCategoryCount) -> \(temporaryCategoryUnlocks.count) categories")
            saveTemporaryUnlocks()
            recalculateShields()
        } else {
            print("[cleanupExpiredUnlocks] No changes needed")
        }
    }

    func removeBlocking() {
        // Clear token caches
        decodedAppTokenCache.removeAll()
        decodedCategoryTokenCache.removeAll()

        // Stop all active device activity monitors
        for (_, activityName) in activeMonitors {
            activityCenter.stopMonitoring([activityName])
        }
        activeMonitors.removeAll()

        // Stop schedule monitors
        stopScheduleMonitoring()

        // Stop insights monitoring
        stopInsightsMonitoring()

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
        print("[temporaryUnlock] 🔓 Creating unlock - start: \(startTime), expiry: \(expiryTime), duration: \(duration)s")
        sharedDefaults?.set(expiryTime.timeIntervalSince1970, forKey: "quotaEndTimestamp")
        sharedDefaults?.set(true, forKey: "isCurrentlyUnlocked")

        // Store usage tracking info
        let usageEventName = DeviceActivityEvent.Name("usage.\(activityName.rawValue)")
        sharedDefaults?.set(usageEventName.rawValue, forKey: "deviceActivity.\(activityName.rawValue).usageEvent")

        // Track this monitor
        activeMonitors[appTokenData] = activityName

        // Update temporary unlocks for UI tracking
        temporaryUnlocks[appTokenData] = expiryTime
        unlockDurations[appTokenData] = duration
        unlockStartTimes[appTokenData] = startTime // Track when unlock started
        print("[temporaryUnlock] Saving unlock to UserDefaults")
        saveTemporaryUnlocks()

        // Schedule chaining for reliable re-locking (especially for short timers)
        scheduleReblockChain(appTokenData: appTokenData, activityName: activityName, expiryTime: expiryTime)

        // IMMEDIATELY update shields to remove this app
        recalculateShields()
    }

    private func removeTemporaryUnlock(appTokenData: Data) {
        // Note: Time tracking is now handled by DeviceActivityMonitor.eventDidReachThreshold()
        // which fires every minute the app is actually used

        print("[removeTemporaryUnlock] 🔒 Removing unlock - had \(temporaryUnlocks.count) unlocks")

        // Clear cached decoded token
        decodedAppTokenCache.removeValue(forKey: appTokenData)

        // Stop monitoring if active
        if let activityName = activeMonitors[appTokenData] {
            print("[removeTemporaryUnlock] Stopping monitor: \(activityName.rawValue)")
            activityCenter.stopMonitoring([activityName])
            activeMonitors.removeValue(forKey: appTokenData)
        }

        temporaryUnlocks.removeValue(forKey: appTokenData)
        unlockDurations.removeValue(forKey: appTokenData)
        unlockStartTimes.removeValue(forKey: appTokenData)
        print("[removeTemporaryUnlock] Now have \(temporaryUnlocks.count) unlocks, saving and recalculating")
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

        // Create unique activity name for this category unlock
        let activityName = DeviceActivityName("unlock.category.\(UUID().uuidString)")

        // Store category token data in shared storage for the monitor extension
        sharedDefaults?.set(categoryTokenData, forKey: "deviceActivity.\(activityName.rawValue).categoryToken")

        // Update temporary category unlocks
        temporaryCategoryUnlocks[categoryTokenData] = expiryTime
        unlockDurations[categoryTokenData] = duration
        unlockStartTimes[categoryTokenData] = startTime
        saveTemporaryUnlocks()

        print("[AppBlockingManager] 🔓 Category unlock started: expiry=\(expiryTime), remaining=\(Int(duration))s")

        // Track this monitor
        activeMonitors[categoryTokenData] = activityName

        // Schedule DeviceActivityMonitor for reliable re-locking
        scheduleReblockChainForCategory(categoryTokenData: categoryTokenData, activityName: activityName, expiryTime: expiryTime)

        // IMMEDIATELY update shields to remove this category
        recalculateShields()

        print("[AppBlockingManager] ✓ Category temporarily unlocked for \(Int(duration / 60)) minutes")
    }

    private func removeTemporaryCategoryUnlock(categoryTokenData: Data) {
        // Clear cached decoded token
        decodedCategoryTokenCache.removeValue(forKey: categoryTokenData)

        // Stop monitoring if active
        if let activityName = activeMonitors[categoryTokenData] {
            activityCenter.stopMonitoring([activityName])
            activeMonitors.removeValue(forKey: categoryTokenData)
        }

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

            // Create usage tracking events (fires at 1min, 2min, 3min... of actual app use)
            guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
                return
            }

            // Generate threshold events based on unlock duration (1 per minute, max 60)
            let maxMinutes = min(Int(duration / 60) + 1, 60)
            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            for minute in 1...maxMinutes {
                let eventName = DeviceActivityEvent.Name("usage.\(minute)min")
                let event = DeviceActivityEvent(
                    applications: [appToken],
                    threshold: DateComponents(minute: minute)
                )
                events[eventName] = event
            }

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Short timer with usage tracking: interval=15min, warningTime=\(warningMinutes)min, \(maxMinutes) threshold events")
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

            // Create usage tracking events (fires at 1min, 2min, 3min... of actual app use)
            guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: appTokenData) else {
                return
            }

            // Generate threshold events based on unlock duration (1 per minute, max 60)
            let maxMinutes = min(Int(duration / 60) + 1, 60)
            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            for minute in 1...maxMinutes {
                let eventName = DeviceActivityEvent.Name("usage.\(minute)min")
                let event = DeviceActivityEvent(
                    applications: [appToken],
                    threshold: DateComponents(minute: minute)
                )
                events[eventName] = event
            }

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Long timer with usage tracking: interval ends in \(Int(duration))s, \(maxMinutes) threshold events")
            } catch {
                print("[AppBlockingManager] ⚠️ Failed to schedule: \(error)")
            }
        }
    }

    /// Schedule DeviceActivity monitor to re-lock category at expiry time
    /// Similar to scheduleReblockChain but for categories (no usage tracking events)
    private func scheduleReblockChainForCategory(categoryTokenData: Data, activityName: DeviceActivityName, expiryTime: Date) {
        let duration = expiryTime.timeIntervalSinceNow

        guard duration > 0 else {
            print("[AppBlockingManager] ⚠️ Category expiry time already passed")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Use same approach as apps: warningTime trick for short timers, intervalDidEnd for long
        if duration < 15 * 60 {
            // Short timer: Use warningTime trick
            let intervalEnd = now.addingTimeInterval(15 * 60)
            let warningMinutes = Int((15 * 60 - duration) / 60)

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
                warningTime: DateComponents(minute: warningMinutes)
            )

            // No usage tracking events for categories (empty dict)
            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Category short timer: interval=15min, warningTime=\(warningMinutes)min (fires in \(Int(duration))s)")
            } catch {
                print("[AppBlockingManager] ⚠️ Failed to schedule category timer: \(error)")
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

            // No usage tracking events for categories (empty dict)
            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[AppBlockingManager] ✓ Category long timer: interval ends in \(Int(duration))s")
            } catch {
                print("[AppBlockingManager] ⚠️ Failed to schedule category timer: \(error)")
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

        _ = Calendar.current
        _ = Date()

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

    // MARK: - Insights Monitoring

    func setupInsightsMonitoring() {
        // Set up DeviceActivity monitoring for screen time insights
        // This runs 24/7 to track usage of ALL apps for reporting

        let activityName = DeviceActivityName("insights.daily")

        // Create a daily schedule that resets at midnight
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            // Monitor all apps (no filter = all apps)
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("[AppBlockingManager] ✅ Insights monitoring started for all apps")
        } catch {
            print("[AppBlockingManager] ⚠️ Failed to start insights monitoring: \(error)")
        }
    }

    func stopInsightsMonitoring() {
        let activityName = DeviceActivityName("insights.daily")
        activityCenter.stopMonitoring([activityName])
        print("[AppBlockingManager] 🛑 Stopped insights monitoring")
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
}
