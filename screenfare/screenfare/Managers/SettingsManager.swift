//
//  SettingsManager.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import Foundation
import Combine
import UserNotifications
import FamilyControls

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var unlockDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(unlockDuration, forKey: "unlockDuration")
            // Also save to App Group for shield extensions
            UserDefaults.appGroup?.set(unlockDuration, forKey: "unlockDuration")
        }
    }

    @Published var challengeDifficulty: ChallengeDifficulty {
        didSet {
            UserDefaults.standard.set(challengeDifficulty.rawValue, forKey: "challengeDifficulty")
        }
    }

    @Published var typingDifficulty: TypingDifficulty {
        didSet {
            UserDefaults.standard.set(typingDifficulty.rawValue, forKey: "typingDifficulty")
        }
    }

    @Published var memoryGridSize: Int {
        didSet {
            UserDefaults.standard.set(memoryGridSize, forKey: "memoryGridSize")
        }
    }

    @Published var memoryTilesToMatch: Int {
        didSet {
            UserDefaults.standard.set(memoryTilesToMatch, forKey: "memoryTilesToMatch")
        }
    }

    @Published var challengeType: ChallengeType {
        didSet {
            UserDefaults.standard.set(challengeType.rawValue, forKey: "challengeType")
            // Also save to App Group for shield extensions
            UserDefaults.appGroup?.set(challengeType.rawValue, forKey: "challengeType")
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var strictModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(strictModeEnabled, forKey: "strictModeEnabled")
        }
    }

    // MARK: - Account Settings
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

    @Published var userEmail: String {
        didSet {
            UserDefaults.standard.set(userEmail, forKey: "userEmail")
        }
    }

    @Published var iCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
        }
    }

    // MARK: - Strict Mode Protection Settings
    @Published var strictProtectOff: Bool {
        didSet {
            UserDefaults.standard.set(strictProtectOff, forKey: "strictProtectOff")
        }
    }

    @Published var strictProtectRemove: Bool {
        didSet {
            UserDefaults.standard.set(strictProtectRemove, forKey: "strictProtectRemove")
        }
    }

    @Published var strictProtectShorten: Bool {
        didSet {
            UserDefaults.standard.set(strictProtectShorten, forKey: "strictProtectShorten")
        }
    }

    // MARK: - Permissions
    @Published var screenTimePermission: PermissionStatus {
        didSet {
            UserDefaults.standard.set(screenTimePermission.rawValue, forKey: "screenTimePermission")
        }
    }

    // TODO: Re-enable once we have a step challenge
    // @Published var healthPermission: PermissionStatus {
    //     didSet {
    //         UserDefaults.standard.set(healthPermission.rawValue, forKey: "healthPermission")
    //     }
    // }

    @Published var notificationPermission: PermissionStatus {
        didSet {
            UserDefaults.standard.set(notificationPermission.rawValue, forKey: "notificationPermission")
        }
    }

    private init() {
        // Load saved settings or use defaults
        let savedDuration = UserDefaults.standard.double(forKey: "unlockDuration")
        self.unlockDuration = savedDuration > 0 ? savedDuration : 1800 // Default 30 minutes

        if let savedDifficulty = UserDefaults.standard.string(forKey: "challengeDifficulty"),
           let difficulty = ChallengeDifficulty(rawValue: savedDifficulty) {
            self.challengeDifficulty = difficulty
        } else {
            self.challengeDifficulty = .medium
        }

        if let savedTypingDifficulty = UserDefaults.standard.string(forKey: "typingDifficulty"),
           let difficulty = TypingDifficulty(rawValue: savedTypingDifficulty) {
            self.typingDifficulty = difficulty
        } else {
            self.typingDifficulty = .medium
        }

        let savedGridSize = UserDefaults.standard.integer(forKey: "memoryGridSize")
        self.memoryGridSize = savedGridSize > 0 ? savedGridSize : 3 // Default 3x3

        let savedTilesToMatch = UserDefaults.standard.integer(forKey: "memoryTilesToMatch")
        self.memoryTilesToMatch = savedTilesToMatch > 0 ? savedTilesToMatch : 4 // Default 4 tiles

        if let savedType = UserDefaults.standard.string(forKey: "challengeType"),
           let type = ChallengeType(rawValue: savedType) {
            self.challengeType = type
        } else {
            self.challengeType = .math
        }

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        self.strictModeEnabled = UserDefaults.standard.bool(forKey: "strictModeEnabled")

        // Account settings
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Screen Fare User"
        self.userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "user@example.com"
        self.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

        // Strict mode protections (default to true when strict mode enabled)
        self.strictProtectOff = UserDefaults.standard.object(forKey: "strictProtectOff") as? Bool ?? true
        self.strictProtectRemove = UserDefaults.standard.object(forKey: "strictProtectRemove") as? Bool ?? true
        self.strictProtectShorten = UserDefaults.standard.object(forKey: "strictProtectShorten") as? Bool ?? true

        // Permissions
        if let savedScreenTime = UserDefaults.standard.string(forKey: "screenTimePermission"),
           let permission = PermissionStatus(rawValue: savedScreenTime) {
            self.screenTimePermission = permission
        } else {
            self.screenTimePermission = .granted
        }

        // TODO: Re-enable once we have a step challenge
        // if let savedHealth = UserDefaults.standard.string(forKey: "healthPermission"),
        //    let permission = PermissionStatus(rawValue: savedHealth) {
        //     self.healthPermission = permission
        // } else {
        //     self.healthPermission = .notDetermined
        // }

        if let savedNotification = UserDefaults.standard.string(forKey: "notificationPermission"),
           let permission = PermissionStatus(rawValue: savedNotification) {
            self.notificationPermission = permission
        } else {
            self.notificationPermission = .notDetermined
        }

        // Initial sync to App Group
        UserDefaults.appGroup?.set(unlockDuration, forKey: "unlockDuration")
        UserDefaults.appGroup?.set(challengeType.rawValue, forKey: "challengeType")
    }

    var unlockDurationText: String {
        unlockDuration.formatted()
    }

    // MARK: - Permission Status Checking

    /// Updates notification permission status based on actual system authorization
    func updateNotificationPermission() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .authorized:
                self.notificationPermission = .granted
            case .denied:
                self.notificationPermission = .denied
            case .notDetermined, .provisional, .ephemeral:
                self.notificationPermission = .notDetermined
            @unknown default:
                self.notificationPermission = .notDetermined
            }
        }
    }

    /// Updates screen time permission status based on actual system authorization
    func updateScreenTimePermission() {
        let center = AuthorizationCenter.shared
        switch center.authorizationStatus {
        case .approved, .approvedWithDataAccess:
            self.screenTimePermission = .granted
        case .denied:
            self.screenTimePermission = .denied
        case .notDetermined:
            self.screenTimePermission = .notDetermined
        @unknown default:
            self.screenTimePermission = .notDetermined
        }
    }

    /// Updates all permission statuses
    func updateAllPermissions() {
        updateNotificationPermission()
        updateScreenTimePermission()
        // TODO: Re-enable once we have a step challenge
        // Health permission would go here if HealthKit is added
    }
}

enum UnlockDurationOption: CaseIterable, Identifiable {
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour

    var id: TimeInterval { duration }

    var duration: TimeInterval {
        switch self {
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        }
    }

    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        }
    }

    var description: String {
        switch self {
        case .fiveMinutes: return "Quick check"
        case .fifteenMinutes: return "Short session"
        case .thirtyMinutes: return "Medium session"
        case .oneHour: return "Extended session"
        }
    }
}

enum PermissionStatus: String, CaseIterable {
    case granted = "granted"
    case notDetermined = "notDetermined"
    case denied = "denied"

    var displayText: String {
        switch self {
        case .granted: return "Granted"
        case .notDetermined: return "Allow"
        case .denied: return "Enable"
        }
    }
}
