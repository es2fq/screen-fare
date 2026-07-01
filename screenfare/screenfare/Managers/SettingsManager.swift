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

    @Published var breathingCycles: Int {
        didSet {
            UserDefaults.standard.set(breathingCycles, forKey: "breathingCycles")
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

    @Published var strictProtectChallenge: Bool {
        didSet {
            UserDefaults.standard.set(strictProtectChallenge, forKey: "strictProtectChallenge")
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

    // MARK: - Subscription Status
    @Published var isProSubscriber: Bool = false
    private var subscriptionCancellable: AnyCancellable?
    private var hasLoadedSettings = false

    private init() {
        // Initialize with defaults (no I/O for most, except critical UI state)
        self.unlockDuration = 1800 // Default 30 minutes
        self.challengeDifficulty = .medium
        self.typingDifficulty = .medium
        self.memoryGridSize = 3 // Default 3x3
        self.memoryTilesToMatch = 4 // Default 4 tiles
        self.breathingCycles = 3 // Default 3 cycles
        self.challengeType = .math

        // Load synchronously - needed immediately for ContentView onAppear animation logic
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        self.strictModeEnabled = false
        self.userName = "Screen Fare User"
        self.userEmail = "user@example.com"
        self.iCloudSyncEnabled = false
        self.strictProtectOff = true
        self.strictProtectRemove = false
        self.strictProtectShorten = false
        self.strictProtectChallenge = false
        self.screenTimePermission = .granted
        self.notificationPermission = .notDetermined

        // Load settings asynchronously
        Task {
            await loadSettingsAsync()
        }

        // Subscribe to subscription manager changes
        subscriptionCancellable = SubscriptionManager.shared.$isProSubscriber
            .sink { [weak self] isProSubscriber in
                self?.isProSubscriber = isProSubscriber
            }
    }

    private func loadSettingsAsync() async {
        // Perform I/O operations on background thread
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Read all settings from UserDefaults on background thread
            // Note: hasCompletedOnboarding is loaded synchronously in init() for immediate UI needs
            let savedDuration = UserDefaults.standard.double(forKey: "unlockDuration")
            let savedDifficultyStr = UserDefaults.standard.string(forKey: "challengeDifficulty")
            let savedTypingDifficultyStr = UserDefaults.standard.string(forKey: "typingDifficulty")
            let savedGridSize = UserDefaults.standard.integer(forKey: "memoryGridSize")
            let savedTilesToMatch = UserDefaults.standard.integer(forKey: "memoryTilesToMatch")
            let savedBreathingCycles = UserDefaults.standard.integer(forKey: "breathingCycles")
            let savedTypeStr = UserDefaults.standard.string(forKey: "challengeType")
            let savedStrictMode = UserDefaults.standard.bool(forKey: "strictModeEnabled")
            let savedUserName = UserDefaults.standard.string(forKey: "userName")
            let savedUserEmail = UserDefaults.standard.string(forKey: "userEmail")
            let savedICloudSync = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
            let savedProtectOff = UserDefaults.standard.object(forKey: "strictProtectOff") as? Bool
            let savedProtectRemove = UserDefaults.standard.object(forKey: "strictProtectRemove") as? Bool
            let savedProtectShorten = UserDefaults.standard.object(forKey: "strictProtectShorten") as? Bool
            let savedProtectChallenge = UserDefaults.standard.object(forKey: "strictProtectChallenge") as? Bool
            let savedScreenTimeStr = UserDefaults.standard.string(forKey: "screenTimePermission")
            let savedNotificationStr = UserDefaults.standard.string(forKey: "notificationPermission")

            // Update properties on main thread
            await MainActor.run {
                if savedDuration > 0 {
                    self.unlockDuration = savedDuration
                }

                if let diffStr = savedDifficultyStr,
                   let difficulty = ChallengeDifficulty(rawValue: diffStr) {
                    self.challengeDifficulty = difficulty
                }

                if let typingDiffStr = savedTypingDifficultyStr,
                   let difficulty = TypingDifficulty(rawValue: typingDiffStr) {
                    self.typingDifficulty = difficulty
                }

                if savedGridSize > 0 {
                    self.memoryGridSize = savedGridSize
                }

                if savedTilesToMatch > 0 {
                    self.memoryTilesToMatch = savedTilesToMatch
                }

                if savedBreathingCycles > 0 {
                    self.breathingCycles = savedBreathingCycles
                }

                if let typeStr = savedTypeStr,
                   let type = ChallengeType(rawValue: typeStr) {
                    self.challengeType = type
                }

                // hasCompletedOnboarding already loaded synchronously in init()
                self.strictModeEnabled = savedStrictMode

                if let userName = savedUserName {
                    self.userName = userName
                }

                if let userEmail = savedUserEmail {
                    self.userEmail = userEmail
                }

                self.iCloudSyncEnabled = savedICloudSync

                if let protectOff = savedProtectOff {
                    self.strictProtectOff = protectOff
                }
                if let protectRemove = savedProtectRemove {
                    self.strictProtectRemove = protectRemove
                }
                if let protectShorten = savedProtectShorten {
                    self.strictProtectShorten = protectShorten
                }
                if let protectChallenge = savedProtectChallenge {
                    self.strictProtectChallenge = protectChallenge
                }

                if let screenTimeStr = savedScreenTimeStr,
                   let permission = PermissionStatus(rawValue: screenTimeStr) {
                    self.screenTimePermission = permission
                }

                if let notificationStr = savedNotificationStr,
                   let permission = PermissionStatus(rawValue: notificationStr) {
                    self.notificationPermission = permission
                }

                // Initial sync to App Group
                UserDefaults.appGroup?.set(self.unlockDuration, forKey: "unlockDuration")
                UserDefaults.appGroup?.set(self.challengeType.rawValue, forKey: "challengeType")

                self.hasLoadedSettings = true
            }
        }.value
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
