//
//  DateExtensions.swift
//  Screen Fare
//
//  Date formatting utilities for history view
//

import Foundation

extension Date {
    /// Returns a user-friendly day label: "Today", "Yesterday", or weekday name
    func dayLabel() -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full weekday name (e.g., "Monday")
            return formatter.string(from: self)
        }
    }

    /// Returns short date format: "Jun 20"
    func shortDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Returns true if this date is on the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Returns the start of day for this date
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

extension Calendar {
    /// Converts a date to a "YYYY-MM-DD" string
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = self
        return formatter.string(from: date)
    }
}
