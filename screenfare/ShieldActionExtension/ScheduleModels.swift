//
//  ScheduleModels.swift
//  Screen Fare
//
//  Shared schedule models and logic accessible to app and extensions
//

import Foundation

// MARK: - App Group Defaults

extension UserDefaults {
    /// The app group identifier shared between the app and all extensions
    public static let appGroupSuiteName = "group.esong.screenfare.shared"

    /// Shared UserDefaults instance for the app group
    /// Returns nil if the app group is not configured correctly
    public static var appGroup: UserDefaults? {
        UserDefaults(suiteName: appGroupSuiteName)
    }
}

// MARK: - Data Models

public enum ScheduleMode: String, Codable {
    case allday = "allday"
    case scheduled = "scheduled"
}

public struct BlockingWindow: Codable, Identifiable, Equatable {
    public let id: String
    public var start: Int  // minutes from midnight (0-1439)
    public var end: Int    // minutes from midnight (0-1439)
    public var days: [Int] // 0 = Sunday, 1 = Monday, etc.

    public init(id: String = UUID().uuidString, start: Int, end: Int, days: [Int]) {
        self.id = id
        self.start = start
        self.end = end
        self.days = days.sorted()
    }
}

public struct Schedule: Codable, Equatable {
    public var mode: ScheduleMode
    public var windows: [BlockingWindow]

    public init(mode: ScheduleMode, windows: [BlockingWindow]) {
        self.mode = mode
        self.windows = windows
    }

    public static let `default` = Schedule(
        mode: .allday,
        windows: [
            BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5]) // Default 9am-5pm weekdays
        ]
    )
}

// MARK: - Shared Schedule Logic

/// Check if blocking should be active based on schedule
/// Can be called from app or extensions
public func isWithinBlockingSchedule(schedule: Schedule, at date: Date = Date()) -> Bool {
    if schedule.mode == .allday {
        return true
    }

    let calendar = Calendar.current
    let currentDay = calendar.component(.weekday, from: date) - 1 // Convert to 0-6 (Sunday = 0)
    let currentMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

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

/// Load schedule from shared UserDefaults
/// Returns nil if no schedule is saved
public func loadScheduleFromSharedDefaults() -> Schedule? {
    guard let defaults = UserDefaults.appGroup,
          let data = defaults.data(forKey: "com.screenfare.schedule"),
          let schedule = try? JSONDecoder().decode(Schedule.self, from: data) else {
        return nil
    }
    return schedule
}

/// Check if blocking is currently active (convenience function for extensions)
public func isBlockingCurrentlyActive() -> Bool {
    guard let schedule = loadScheduleFromSharedDefaults() else {
        // No schedule found, default to all-day blocking
        return true
    }
    return isWithinBlockingSchedule(schedule: schedule)
}

// MARK: - Notification Names

extension Notification.Name {
    public static let scheduleDidChange = Notification.Name("com.screenfare.scheduleDidChange")
}

// MARK: - Date/Time Formatting Utilities

extension Date {
    /// Returns today's date as "yyyy-MM-dd" string
    /// Shared utility to avoid duplicate todayDateString() implementations
    public static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

extension TimeInterval {
    /// Formats time interval as a human-readable string
    /// Examples: "5 min", "1 hr", "1 hr 30 min"
    public func formatted() -> String {
        let minutes = Int(self / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }

    /// Formats time spent as a concise string
    /// Examples: "5s", "2m", "1h", "1h 5m"
    public func formattedTimeSpent() -> String {
        let seconds = Int(self)
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
}
