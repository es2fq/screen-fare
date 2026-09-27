//
//  DailyStats.swift
//  ScreenFareShared
//
//  Daily counters shared by the app and extensions via the App Group
//

import Foundation

public struct DailyStats: Codable {
    /// App Group key for today's stats
    public static let storageKey = "com.screenfare.dailyStats"

    public var date: String // "YYYY-MM-DD"
    public var blocksToday: Int
    public var faresPaid: Int // Challenges solved

    public init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.faresPaid = 0
    }
}
