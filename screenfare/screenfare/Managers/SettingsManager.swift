//
//  SettingsManager.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var unlockDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(unlockDuration, forKey: "unlockDuration")
            // Also save to App Group for shield extensions
            if let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared") {
                sharedDefaults.set(unlockDuration, forKey: "unlockDuration")
                sharedDefaults.synchronize()
            }
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
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
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

        // Initial sync to App Group
        if let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared") {
            sharedDefaults.set(unlockDuration, forKey: "unlockDuration")
            sharedDefaults.synchronize()
        }
    }

    var unlockDurationText: String {
        let minutes = Int(unlockDuration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hr"
        }
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
