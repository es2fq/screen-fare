//
//  StatsManager.swift
//  Screen Fare
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

    init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.faresPaid = 0
    }
}

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published private(set) var todayStats: DailyStats

    private let storageKey = "com.screenfare.dailyStats"
    private let historicalKey = "com.screenfare.historicalStats"  // Last 7 days
    private let sharedDefaults = UserDefaults.appGroup

    private init() {
        // Load or create today's stats
        let today = Date.todayDateString()

        if let data = sharedDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            // Found today's stats
            todayStats = decoded
            print("[StatsManager] Loaded stats: blocks=\(decoded.blocksToday), fares=\(decoded.faresPaid)")
        } else {
            // Create fresh stats for today
            todayStats = DailyStats(date: today)
            saveStats()
            print("[StatsManager] Created fresh stats for \(today)")
        }

        // Listen for Darwin notifications from extensions instead of polling
        // This is much more efficient than the previous 2-second polling loop
        DarwinNotificationManager.shared.onStatsUpdated = { [weak self] in
            Task { @MainActor in
                self?.reloadStats()
            }
        }
    }

    /// Reload stats from shared storage (called when extensions update them)
    func reloadStats() {
        let today = Date.todayDateString()

        if let data = sharedDefaults?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            // Only update if stats changed
            if decoded.blocksToday != todayStats.blocksToday ||
               decoded.faresPaid != todayStats.faresPaid {
                todayStats = decoded
                print("[StatsManager] 📊 Stats updated: blocks=\(decoded.blocksToday), fares=\(decoded.faresPaid)")
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

    // MARK: - Formatted Stats

    var blocksToday: String {
        "\(todayStats.blocksToday)"
    }

    var faresPaid: String {
        "\(todayStats.faresPaid)"
    }

    // MARK: - Persistence

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(todayStats) {
            sharedDefaults?.set(encoded, forKey: storageKey)
        }

        // Also save to historical data
        saveToHistorical(todayStats)
    }

    private func saveToHistorical(_ stats: DailyStats) {
        // Load existing historical data
        var historical = loadHistoricalStats()
        historical[stats.date] = stats

        // Keep only last 30 days
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let cutoffString = calendar.dateString(from: cutoffDate)

        historical = historical.filter { $0.key >= cutoffString }

        // Save back
        if let encoded = try? JSONEncoder().encode(historical) {
            sharedDefaults?.set(encoded, forKey: historicalKey)
        }
    }

    private func loadHistoricalStats() -> [String: DailyStats] {
        guard let data = sharedDefaults?.data(forKey: historicalKey),
              let stats = try? JSONDecoder().decode([String: DailyStats].self, from: data) else {
            return [:]
        }
        return stats
    }

    private func checkAndResetIfNewDay() {
        let today = Date.todayDateString()
        if todayStats.date != today {
            // New day! Reset stats
            todayStats = DailyStats(date: today)
            saveStats()
        }
    }
}
