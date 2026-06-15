//
//  ScheduleManager.swift
//  screenfare
//
//  Manages blocking schedules: when blocks are active.
//  Users can choose "all day" or define custom time windows with specific days.
//

import Foundation
import Combine

// MARK: - Schedule Manager

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published var schedule: Schedule {
        didSet {
            saveSchedule()
            // Notify that schedule changed so AppBlockingManager can update monitors
            NotificationCenter.default.post(name: .scheduleDidChange, object: nil)
        }
    }

    private let scheduleKey = "com.screenfare.schedule"
    private let sharedDefaults = UserDefaults.appGroup

    init() {
        // Load from shared UserDefaults or use default
        if let data = sharedDefaults?.data(forKey: scheduleKey),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            self.schedule = decoded
        } else {
            self.schedule = .default
            // Save default to shared storage
            saveSchedule()
        }
    }

    private func saveSchedule() {
        if let encoded = try? JSONEncoder().encode(schedule) {
            sharedDefaults?.set(encoded, forKey: scheduleKey)
            print("[ScheduleManager] 💾 Saved schedule to shared storage: \(schedule.mode)")
        }
    }

    // MARK: - Helpers

    /// Check if blocking is currently active based on schedule
    func isBlockingActive() -> Bool {
        return isWithinBlockingSchedule(schedule: schedule)
    }

    /// Get a one-line summary of the schedule
    func scheduleSummary() -> String {
        if schedule.mode == .allday {
            return "All day · Every day"
        }

        if schedule.windows.isEmpty {
            return "No windows"
        }

        if schedule.windows.count == 1 {
            let w = schedule.windows[0]
            return "\(Self.minToCompact(w.start))–\(Self.minToCompact(w.end)) · \(Self.formatDays(w.days))"
        }

        return "\(schedule.windows.count) windows"
    }

    func scheduleSummaryShort() -> String {
        if schedule.mode == .allday {
            return "All day"
        }

        if schedule.windows.isEmpty {
            return "Off"
        }

        if schedule.windows.count == 1 {
            let w = schedule.windows[0]
            return "\(Self.minToCompact(w.start))–\(Self.minToCompact(w.end))"
        }

        return "\(schedule.windows.count) windows"
    }

    // MARK: - Time Formatting Helpers

    static func minToLabel(_ m: Int) -> String {
        let normalized = ((m % 1440) + 1440) % 1440
        let h = normalized / 60
        let min = normalized % 60
        let ap = h < 12 ? "AM" : "PM"
        var h12 = h % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d %@", h12, min, ap)
    }

    static func minToCompact(_ m: Int) -> String {
        let normalized = ((m % 1440) + 1440) % 1440
        let h = normalized / 60
        let min = normalized % 60
        let ap = h < 12 ? "a" : "p"
        var h12 = h % 12
        if h12 == 0 { h12 = 12 }
        return min == 0 ? "\(h12)\(ap)" : String(format: "%d:%02d%@", h12, min, ap)
    }

    static func formatDays(_ days: [Int]) -> String {
        let set = Set(days)
        if set.count == 7 {
            return "Every day"
        }
        if set.count == 0 {
            return "No days"
        }
        if set.count == 5 && [1, 2, 3, 4, 5].allSatisfy(set.contains) {
            return "Weekdays"
        }
        if set.count == 2 && set.contains(0) && set.contains(6) {
            return "Weekends"
        }

        return [1, 2, 3, 4, 5, 6, 0]
            .filter { set.contains($0) }
            .map { Self.dayNames[$0] }
            .joined(separator: ", ")
    }

    // MARK: - Constants

    static let dayPills: [(String, Int)] = [("M", 1), ("T", 2), ("W", 3), ("T", 4), ("F", 5), ("S", 6), ("S", 0)]
    static let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}
