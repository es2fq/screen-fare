//
//  CompactActivityReport.swift
//  DeviceActivityReportExtension
//
//  Compact report for the Today screen widget
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    // Compact activity context - for Today screen widget
    static let compactActivity = Self("Compact Activity")
}

// MARK: - Compact Activity Report Scene

struct CompactActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .compactActivity
    let content: (CompactActivityConfig) -> CompactActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> CompactActivityConfig {
        print("[CompactActivityReport] makeConfiguration called")

        // Parse real DeviceActivity data with daily segments (last 7 days)
        var dailyUsageMap: [String: TimeInterval] = [:]  // Date string -> duration

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Iterate through all device activity data with daily segments
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                // Track per day
                let dayString = formatter.string(from: segment.dateInterval.start)
                let currentDayUsage = dailyUsageMap[dayString] ?? 0
                dailyUsageMap[dayString] = currentDayUsage + segment.totalActivityDuration
            }
        }

        // Get today's total (not the sum of all 7 days!)
        let todayString = formatter.string(from: Date())
        let todaySeconds = dailyUsageMap[todayString] ?? 0
        let totalMinutes = max(0, Int(todaySeconds / 60))

        print("[CompactActivityReport] Total minutes today: \(totalMinutes), Days with data: \(dailyUsageMap.count)")

        // Build week data array (last 7 days in order)
        let today = Date()
        var weekData: [Int] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                weekData.append(0)
                continue
            }

            let dayString = formatter.string(from: date)
            let duration = dailyUsageMap[dayString] ?? 0
            let minutes = Int(duration / 60)
            weekData.append(minutes)

            if dayOffset == 0 {
                print("[CompactActivityReport] Today (\(dayString)): \(minutes)m")
            }
        }

        return CompactActivityConfig(
            totalMinutes: totalMinutes,
            weekMinutes: weekData
        )
    }
}

// MARK: - Compact Activity Config

struct CompactActivityConfig {
    let totalMinutes: Int
    let weekMinutes: [Int]  // Last 7 days
}
