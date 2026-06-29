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
    var timeSpentSeconds: Int // Actual time spent in unlocked apps

    init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.faresPaid = 0
        self.timeSpentSeconds = 0
    }
}

// Data structure for week chart display
struct DayChartData {
    let dayLabel: String  // M, T, W, etc.
    let minutes: Int
    let isToday: Bool
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
            print("[StatsManager] Loaded stats: blocks=\(decoded.blocksToday), fares=\(decoded.faresPaid), time=\(decoded.timeSpentSeconds)s")
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
        TimeInterval(todayStats.timeSpentSeconds).formattedTimeSpent()
    }

    // MARK: - Week Data

    var weekData: [DayChartData] {
        // Get last 7 days of data
        let calendar = Calendar.current
        let today = Date()
        var result: [DayChartData] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let isToday = dayOffset == 0

            // Get day label (M, T, W, etc.)
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayLabel = String(formatter.string(from: date).prefix(1))

            // Get minutes for this day
            let dateString = calendar.dateString(from: date)
            let minutes: Int

            if isToday {
                minutes = todayStats.timeSpentSeconds / 60
            } else {
                minutes = getHistoricalMinutes(for: dateString)
            }

            result.append(DayChartData(dayLabel: dayLabel, minutes: minutes, isToday: isToday))
        }

        return result
    }

    var yesterdaySeconds: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return 0
        }
        let yesterdayString = calendar.dateString(from: yesterday)
        return getHistoricalSeconds(for: yesterdayString)
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

    private func getHistoricalMinutes(for dateString: String) -> Int {
        let historical = loadHistoricalStats()
        return (historical[dateString]?.timeSpentSeconds ?? 0) / 60
    }

    private func getHistoricalSeconds(for dateString: String) -> Int {
        let historical = loadHistoricalStats()
        return historical[dateString]?.timeSpentSeconds ?? 0
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
