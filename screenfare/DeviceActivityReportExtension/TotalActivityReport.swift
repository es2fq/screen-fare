//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Report contexts and configurations for Screen Fare insights
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    // Total activity context - shows total time on blocked apps
    static let totalActivity = Self("Total Activity")
}

// MARK: - Activity Data Configuration

struct ActivityConfig {
    let totalMinutes: Int
    let previousMinutes: Int  // For delta calculation
    let dailyData: [DayData]  // For week bars
    let hourlyData: [HourData]  // For hour-by-hour chart
    let topApps: [AppData]    // For per-app breakdown
    let stats: ActivityStats  // Opens, pickups, etc.
}

struct DayData {
    let dayLabel: String  // M, T, W, etc.
    let minutes: Int
    let isToday: Bool
}

struct HourData: Identifiable {
    let id: Int  // Hour (0-23)
    let hour: Int  // Hour (0-23)
    let minutes: Int
}

struct AppData: Identifiable {
    let id: String
    let name: String
    let minutes: Int
}

struct ActivityStats {
    let opens: Int
    let perDay: Int
    let busiest: String  // e.g., "Mon"
}

// MARK: - Total Activity Report Scene

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityConfig) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityConfig {
        // Parse real DeviceActivity data with hourly segments
        var totalSeconds: TimeInterval = 0
        var appUsageMap: [String: TimeInterval] = [:]
        var hourlyUsageMap: [Int: TimeInterval] = [:]  // Hour (0-23) -> duration
        var totalPickups = 0

        // Iterate through all device activity data
        var appIndex = 0
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                // Add segment total to overall total
                totalSeconds += segment.totalActivityDuration

                // Extract hour from segment (hourly segments!)
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: segment.dateInterval.start)
                let currentHourUsage = hourlyUsageMap[hour] ?? 0
                hourlyUsageMap[hour] = currentHourUsage + segment.totalActivityDuration

                // Iterate through categories and apps
                for await category in segment.categories {
                    for await app in category.applications {
                        totalPickups += app.numberOfPickups

                        // Use a unique identifier (hash or index)
                        // Since we can't access app names directly, use an index
                        let appId = "app_\(appIndex)"
                        let currentDuration = appUsageMap[appId] ?? 0
                        appUsageMap[appId] = currentDuration + app.totalActivityDuration
                        appIndex += 1
                    }
                }
            }
        }

        print("[TotalActivityReport] Processed \(hourlyUsageMap.count) hours of data")

        let totalMinutes = max(0, Int(totalSeconds / 60))

        // For previous day comparison, use mock data for now
        // (could be enhanced by storing yesterday's total)
        let previousMinutes = totalMinutes > 0 ? Int(Double(totalMinutes) * 1.5) : 44

        // Generate daily data for the week
        let calendar = Calendar.current
        let today = Date()
        var dailyData: [DayData] = []

        // For now, only today has real data; other days are estimated
        // (could be enhanced by running daily reports and storing history)
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let isToday = dayOffset == 0

            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayLabel = String(formatter.string(from: date).prefix(1))

            let minutes: Int
            if isToday {
                minutes = totalMinutes
            } else {
                // Mock historical data showing improvement trend
                let randomFactor = Double.random(in: 1.2...1.8)
                minutes = min(180, Int(Double(totalMinutes) * randomFactor))
            }

            dailyData.append(DayData(dayLabel: dayLabel, minutes: minutes, isToday: isToday))
        }

        // Convert app usage map to sorted array
        var topApps: [AppData] = []
        var displayIndex = 0

        for (appId, duration) in appUsageMap.sorted(by: { $0.value > $1.value }).prefix(5) {
            let minutes = Int(duration / 60)
            if minutes > 0 {
                // Extract a readable name from the token description if possible
                // Token descriptions are opaque, so we'll just use a generic name
                let appName = "App \(displayIndex + 1)"
                topApps.append(AppData(id: appId, name: appName, minutes: minutes))
                displayIndex += 1
            }
        }

        // Convert hourly usage map to array (all 24 hours)
        var hourlyData: [HourData] = []
        for hour in 0..<24 {
            let duration = hourlyUsageMap[hour] ?? 0
            let minutes = Int(duration / 60)
            hourlyData.append(HourData(id: hour, hour: hour, minutes: minutes))
        }

        // Calculate stats
        let opens = max(1, totalPickups)

        let stats = ActivityStats(
            opens: opens,
            perDay: max(1, opens / 7),
            busiest: dailyData.max { $0.minutes < $1.minutes }?.dayLabel ?? "Mon"
        )

        print("[TotalActivityReport] Processed \(totalMinutes) minutes across \(topApps.count) apps, \(opens) pickups, \(hourlyData.filter { $0.minutes > 0 }.count) active hours")

        return ActivityConfig(
            totalMinutes: totalMinutes,
            previousMinutes: previousMinutes,
            dailyData: dailyData,
            hourlyData: hourlyData,
            topApps: topApps,
            stats: stats
        )
    }
}
