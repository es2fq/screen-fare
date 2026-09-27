//
//  SurgePricing.swift
//  ScreenFareShared
//
//  Surge pricing: each fare paid today makes the next one harder.
//  Shared so the shield can warn about a surge before the challenge opens.
//

import Foundation

public enum SurgePricing {
    /// Setting key, mirrored to the App Group so extensions can read it
    public static let enabledKey = "surgePricingEnabled"

    /// Fares per day charged at the normal price before surge kicks in
    public static let baseFaresPerDay = 2

    /// Highest surge level; fares stop getting harder past this
    public static let maxLevel = 3

    /// Surge level for the next fare: 0 is the normal price, 1...maxLevel is surged
    public static func level(faresPaidToday: Int) -> Int {
        min(max(faresPaidToday - baseFaresPerDay + 1, 0), maxLevel)
    }

    /// Whether surge pricing is on (defaults to on)
    public static var isEnabled: Bool {
        UserDefaults.appGroup?.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Fares paid since midnight, read from the App Group
    public static func faresPaidToday() -> Int {
        guard let data = UserDefaults.appGroup?.data(forKey: DailyStats.storageKey),
              let stats = try? JSONDecoder().decode(DailyStats.self, from: data),
              stats.date == Date.todayDateString() else {
            return 0
        }
        return stats.faresPaid
    }

    /// Surge level the next fare will be charged at, or 0 if surge pricing is off
    public static func currentLevel() -> Int {
        isEnabled ? level(faresPaidToday: faresPaidToday()) : 0
    }
}
