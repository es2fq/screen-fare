//
//  ScheduleManager.swift
//  screenfare
//
//  Manages blocking schedules: when blocks are active.
//  Users can choose "all day" or define custom time windows with specific days.
//

import Foundation
import Combine

// MARK: - Data Models

enum ScheduleMode: String, Codable {
    case allday = "allday"
    case scheduled = "scheduled"
}

struct BlockingWindow: Codable, Identifiable, Equatable {
    let id: String
    var start: Int  // minutes from midnight (0-1439)
    var end: Int    // minutes from midnight (0-1439)
    var days: [Int] // 0 = Sunday, 1 = Monday, etc.

    init(id: String = UUID().uuidString, start: Int, end: Int, days: [Int]) {
        self.id = id
        self.start = start
        self.end = end
        self.days = days.sorted()
    }
}

struct Schedule: Codable, Equatable {
    var mode: ScheduleMode
    var windows: [BlockingWindow]

    static let `default` = Schedule(
        mode: .allday,
        windows: [
            BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5]) // Default 9am-5pm weekdays
        ]
    )

    static let exampleScheduled = Schedule(
        mode: .scheduled,
        windows: [
            BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5]), // Weekdays 9am-5pm
            BlockingWindow(start: 20 * 60, end: 23 * 60 + 30, days: [0, 1, 2, 3, 4, 5, 6]) // Every day 8pm-11:30pm
        ]
    )
}

// MARK: - Schedule Manager

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published var schedule: Schedule {
        didSet {
            saveSchedule()
        }
    }

    private let scheduleKey = "com.screenfare.schedule"
    private let defaults = UserDefaults(suiteName: "group.com.screenfare.app")

    init() {
        // Load from UserDefaults or use default
        if let data = defaults?.data(forKey: scheduleKey),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            self.schedule = decoded
        } else {
            self.schedule = .default
        }
    }

    private func saveSchedule() {
        if let encoded = try? JSONEncoder().encode(schedule) {
            defaults?.set(encoded, forKey: scheduleKey)
            print("[ScheduleManager] 💾 Saved schedule: \(schedule.mode)")
        }
    }

    // MARK: - Helpers

    /// Check if blocking is currently active based on schedule
    func isBlockingActive() -> Bool {
        if schedule.mode == .allday {
            return true
        }

        let now = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.weekday, from: now) - 1 // Convert to 0-6 (Sunday = 0)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        // Check if current time falls within any window
        for window in schedule.windows {
            guard window.days.contains(currentDay) else { continue }

            // Handle overnight windows
            if window.end < window.start {
                // Window spans midnight
                if currentMinutes >= window.start || currentMinutes < window.end {
                    return true
                }
            } else {
                // Normal same-day window
                if currentMinutes >= window.start && currentMinutes < window.end {
                    return true
                }
            }
        }

        return false
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
            return "\(minToCompact(w.start))–\(minToCompact(w.end)) · \(formatDays(w.days))"
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
            return "\(minToCompact(w.start))–\(minToCompact(w.end))"
        }

        return "\(schedule.windows.count) windows"
    }
}

// MARK: - Time Formatting Helpers

func minToLabel(_ m: Int) -> String {
    let normalized = ((m % 1440) + 1440) % 1440
    let h = normalized / 60
    let min = normalized % 60
    let ap = h < 12 ? "AM" : "PM"
    var h12 = h % 12
    if h12 == 0 { h12 = 12 }
    return String(format: "%d:%02d %@", h12, min, ap)
}

func minToCompact(_ m: Int) -> String {
    let normalized = ((m % 1440) + 1440) % 1440
    let h = normalized / 60
    let min = normalized % 60
    let ap = h < 12 ? "a" : "p"
    var h12 = h % 12
    if h12 == 0 { h12 = 12 }
    return min == 0 ? "\(h12)\(ap)" : String(format: "%d:%02d%@", h12, min, ap)
}

func formatDays(_ days: [Int]) -> String {
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

    let dayShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return [1, 2, 3, 4, 5, 6, 0]
        .filter { set.contains($0) }
        .map { dayShort[$0] }
        .joined(separator: ", ")
}

let dayPills: [(String, Int)] = [("M", 1), ("T", 2), ("W", 3), ("T", 4), ("F", 5), ("S", 6), ("S", 0)]
let dayShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
