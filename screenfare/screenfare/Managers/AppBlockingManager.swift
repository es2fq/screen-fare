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

@MainActor
class AppBlockingManager: ObservableObject {
    static let shared = AppBlockingManager()

    let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")
    private let temporaryUnlocksKey = "com.screenfare.temporaryUnlocks"
    private var activeMonitors: [Data: DeviceActivityName] = [:] // Track active device activity monitors

    @Published var isAuthorized = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var blockedApps: FamilyActivitySelection?
    @Published var unlockExpiryTime: Date?
    @Published var temporaryUnlocks: [Data: Date] = [:] // App token data -> expiry time

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

    private init() {
        // Check authorization status on init
        checkAuthorizationStatus()

        // Load persisted temporary unlocks
        loadTemporaryUnlocks()

        // Restart timers for any active unlocks
        restartExpiredTimers()
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

    private func saveTemporaryUnlocks() {
        guard let encoded = try? JSONEncoder().encode(temporaryUnlocks) else { return }
        sharedDefaults?.set(encoded, forKey: temporaryUnlocksKey)
        sharedDefaults?.synchronize()
    }

    func loadTemporaryUnlocks() {
        guard let data = sharedDefaults?.data(forKey: temporaryUnlocksKey),
              let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) else {
            return
        }
        temporaryUnlocks = decoded
    }

    func restartExpiredTimers() {
        let now = Date()
        var needsRecalculation = false

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

        // Move all heavy work to background to keep UI responsive
        let appsToEncode = selectedApps.applicationTokens
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Save selectedApps to shared storage (disk I/O on background thread)
            if let encoded = try? JSONEncoder().encode(appsToEncode) {
                await self.sharedDefaults?.set(encoded, forKey: "com.screenfare.selectedApps")
                await self.sharedDefaults?.synchronize()
            }

            // Apply shields on main actor
            await self.recalculateShields()
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

        // Apply shields to currently blocked apps (excluding temporary unlocks)
        // This removes unlocked apps from the shield store so they can be accessed
        store.shield.applications = currentlyBlockedApps
        store.shield.applicationCategories = .specific(selectedApps.categoryTokens)
        store.shield.webDomains = selectedApps.webDomainTokens
    }

    func cleanupExpiredUnlocks() {
        let now = Date()
        let originalCount = temporaryUnlocks.count
        temporaryUnlocks = temporaryUnlocks.filter { $0.value > now }

        if temporaryUnlocks.count != originalCount {
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

        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        unlockExpiryTime = nil
        blockedApps = nil

        // Clear all temporary unlocks (user manually turned off Focus)
        temporaryUnlocks.removeAll()
        saveTemporaryUnlocks()

        // selectedApps is preserved so when Focus turns back on, the list is intact
    }

    func temporaryUnlock(appToken: ApplicationToken?, duration: TimeInterval) {
        guard let appToken = appToken else { return }
        guard isBlocking else { return }
        guard let appTokenData = try? JSONEncoder().encode(appToken) else { return }

        // Calculate start and end times
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(duration)

        // Create unique activity name for this unlock
        let activityName = DeviceActivityName("unlock.\(UUID().uuidString)")

        // Store app token data in shared storage for the monitor extension
        sharedDefaults?.set(appTokenData, forKey: "deviceActivity.\(activityName.rawValue).appToken")
        sharedDefaults?.synchronize()

        // Track this monitor
        activeMonitors[appTokenData] = activityName

        // Update temporary unlocks for UI tracking and Shield extension
        let expiryTime = Date().addingTimeInterval(duration)
        temporaryUnlocks[appTokenData] = expiryTime
        saveTemporaryUnlocks()

        // Create schedule from now until expiry
        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: startTime),
                minute: calendar.component(.minute, from: startTime),
                second: calendar.component(.second, from: startTime)
            ),
            intervalEnd: DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: endTime),
                minute: calendar.component(.minute, from: endTime),
                second: calendar.component(.second, from: endTime)
            ),
            repeats: false
        )

        // Start monitoring - iOS will call intervalDidStart and intervalDidEnd
        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("[AppBlockingManager] Started DeviceActivity monitoring for \(activityName.rawValue)")
        } catch {
            print("[AppBlockingManager] Failed to start device activity monitoring: \(error)")
        }

        // IMMEDIATELY update shields to remove this app (don't wait for intervalDidStart)
        recalculateShields()

        // Keep Task timer as backup for when app is running (provides immediate feedback)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                self.removeTemporaryUnlock(appTokenData: appTokenData)
            }
        }
    }

    private func removeTemporaryUnlock(appTokenData: Data) {
        // Stop monitoring if active
        if let activityName = activeMonitors[appTokenData] {
            activityCenter.stopMonitoring([activityName])
            activeMonitors.removeValue(forKey: appTokenData)
        }

        temporaryUnlocks.removeValue(forKey: appTokenData)
        saveTemporaryUnlocks()
        recalculateShields()
    }

    func remainingUnlockTime(for appToken: ApplicationToken) -> TimeInterval? {
        guard let appTokenData = try? JSONEncoder().encode(appToken),
              let expiryTime = temporaryUnlocks[appTokenData],
              Date() < expiryTime else {
            return nil
        }
        return expiryTime.timeIntervalSince(Date())
    }
}
