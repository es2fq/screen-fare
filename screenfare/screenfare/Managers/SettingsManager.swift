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
        }
    }

    @Published var challengeDifficulty: ChallengeDifficulty {
        didSet {
            UserDefaults.standard.set(challengeDifficulty.rawValue, forKey: "challengeDifficulty")
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

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
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
