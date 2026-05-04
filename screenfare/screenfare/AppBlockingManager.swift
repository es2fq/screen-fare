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

@MainActor
class AppBlockingManager: ObservableObject {
    static let shared = AppBlockingManager()

    let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()

    @Published var isAuthorized = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var blockedApps: FamilyActivitySelection?
    @Published var unlockExpiryTime: Date?

    private init() {
        // Check authorization status on init
        checkAuthorizationStatus()
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

    func applyBlocking() {
        guard !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty else {
            return
        }

        // Store the blocked apps
        blockedApps = selectedApps

        // Apply shields to selected apps
        store.shield.applications = selectedApps.applicationTokens
        store.shield.applicationCategories = .specific(selectedApps.categoryTokens)
        store.shield.webDomains = selectedApps.webDomainTokens
    }

    func removeBlocking() {
        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        unlockExpiryTime = nil
    }

    func temporaryUnlock(duration: TimeInterval) {
        // Remove shields temporarily
        removeBlocking()

        // Set expiry time
        unlockExpiryTime = Date().addingTimeInterval(duration)

        // Schedule relock
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                relock()
            }
        }
    }

    func relock() {
        // Reapply blocking if we had blocked apps
        if blockedApps != nil {
            selectedApps = blockedApps!
            applyBlocking()
        }
    }

    func isCurrentlyUnlocked() -> Bool {
        if let expiryTime = unlockExpiryTime {
            return Date() < expiryTime
        }
        return false
    }

    func remainingUnlockTime() -> TimeInterval? {
        if let expiryTime = unlockExpiryTime, Date() < expiryTime {
            return expiryTime.timeIntervalSince(Date())
        }
        return nil
    }
}
