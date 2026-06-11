//
//  StatsManager.swift
//  screenfare
//
//  Tracks daily statistics: blocks, challenges solved, and time saved
//

import Foundation
import SwiftUI
import Combine

struct DailyStats: Codable {
    var date: String // "YYYY-MM-DD"
    var blocksToday: Int
    var faresPaid: Int // Challenges solved
    var timeSpentSeconds: Int // Actual time spent in unlocked apps

    init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.faresPaid = 0
        self.timeSpentSeconds = 0
    }
}

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published private(set) var todayStats: DailyStats

    private let storageKey = "com.screenfare.dailyStats"
    private let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")

    private init() {
        // Load or create today's stats
        let today = Self.todayDateString()

        if let data = sharedDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            // Found today's stats
            todayStats = decoded
            print("[StatsManager] Loaded stats: blocks=\(decoded.blocksToday), fares=\(decoded.faresPaid), time=\(decoded.timeSpentSeconds)s")
        } else {
            // Create fresh stats for today
            todayStats = DailyStats(date: today)
            saveStats()
            print("[StatsManager] Created fresh stats for \(today)")
        }

        // Start a timer to periodically reload stats from shared storage
        // (Extensions write to shared UserDefaults, we need to poll for changes)
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                self.reloadStats()
            }
        }
    }

    /// Reload stats from shared storage (called when extensions update them)
    func reloadStats() {
        let today = Self.todayDateString()

        if let data = sharedDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            // Only update if stats changed
            if decoded.blocksToday != todayStats.blocksToday ||
               decoded.faresPaid != todayStats.faresPaid ||
               decoded.timeSpentSeconds != todayStats.timeSpentSeconds {
                todayStats = decoded
                print("[StatsManager] 📊 Stats updated: blocks=\(decoded.blocksToday), fares=\(decoded.faresPaid), time=\(decoded.timeSpentSeconds)s")
            }
        }
    }

    // MARK: - Public API

    /// Record a block attempt (when user hits shield screen)
    func recordBlockAttempt() {
        checkAndResetIfNewDay()
        todayStats.blocksToday += 1
        saveStats()
        print("[StatsManager] 📊 Block recorded: \(todayStats.blocksToday) blocks today")
    }

    /// Record a solved challenge (fare paid)
    func recordChallengeSolved() {
        checkAndResetIfNewDay()
        todayStats.faresPaid += 1
        saveStats()
    }

    /// Record actual time spent in unlocked apps
    func recordTimeSpent(seconds: TimeInterval) {
        checkAndResetIfNewDay()
        todayStats.timeSpentSeconds += Int(seconds)
        saveStats()
    }

    // MARK: - Formatted Stats

    var blocksToday: String {
        "\(todayStats.blocksToday)"
    }

    var faresPaid: String {
        "\(todayStats.faresPaid)"
    }

    var timeSpent: String {
        formatTime(todayStats.timeSpentSeconds)
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }

    // MARK: - Persistence

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(todayStats) {
            sharedDefaults?.set(encoded, forKey: storageKey)
            sharedDefaults?.synchronize()
        }
    }

    private func checkAndResetIfNewDay() {
        let today = Self.todayDateString()
        if todayStats.date != today {
            // New day! Reset stats
            todayStats = DailyStats(date: today)
            saveStats()
        }
    }

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
