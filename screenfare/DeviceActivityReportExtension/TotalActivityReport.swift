//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Report contexts and configurations for Screen Fare insights
//

import DeviceActivity
import ExtensionKit
import SwiftUI
import FamilyControls
import ManagedSettings
import os

extension DeviceActivityReport.Context {
    // Total activity context - shows total time on blocked apps
    static let totalActivity = Self("Total Activity")
    // Today blocked apps usage time - calculates today's blocked app time only
    static let todayBlockedAppsUsageTime = Self("Today Blocked Apps Usage Time")
}

// MARK: - Activity Data Configuration

struct ActivityConfig: Sendable {
    let totalMinutes: Int       // Total device time (ALL apps)
    let blockedMinutes: Int     // Time on blocked apps only
    let previousMinutes: Int    // For delta calculation (total)
    let previousBlockedMinutes: Int  // For blocked delta
    let dailyData: [DayData]    // For week bars (total time)
    let hourlyData: [HourData]  // For hour-by-hour chart
    let topApps: [AppData]      // ALL apps for per-app breakdown
    let stats: ActivityStats    // Opens, pickups, etc.
    let isWeekView: Bool        // Whether showing week or today
}

struct DayData: Sendable {
    let dayLabel: String  // M, T, W, etc.
    let minutes: Int
    let isToday: Bool
}

struct HourData: Identifiable, Sendable {
    let id: Int  // Hour (0-23)
    let hour: Int  // Hour (0-23)
    let minutes: Int
}

struct AppData: Identifiable, Sendable {
    let id: String
    let token: ApplicationToken?  // Optional token for Label (may be nil)
    let app: Application           // Application for localizedDisplayName fallback
    let minutes: Int
}

struct ActivityStats: Sendable {
    let opens: Int  // Total pickups (all apps)
    let blockedOpens: Int  // Pickups for blocked apps only
    let perDay: Int
    let busiest: String  // e.g., "Mon"
    let firstPickupTime: Date?  // Earliest activity timestamp (any app)
    let firstBlockedOpenTime: Date?  // Earliest blocked app activity timestamp
    let longestSessionMinutes: Int?  // Longest continuous session in minutes
}

// MARK: - Total Activity Report Scene

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityConfig) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityConfig {
        // Create logger for this extension
        let logger = Logger(subsystem: "esong.screenfare", category: "TotalActivityReport")

        // Parse real DeviceActivity data with hourly segments
        let calendar = Calendar.current
        var totalSeconds: TimeInterval = 0
        var blockedSeconds: TimeInterval = 0
        var appUsageMap: [String: (token: ApplicationToken?, app: Application, duration: TimeInterval)] = [:]  // Store token + app + duration
        var hourlyUsageMap: [Int: TimeInterval] = [:]  // Hour (0-23) -> duration
        var dailyUsageMap: [String: TimeInterval] = [:]  // Date string -> duration
        var totalPickups = 0
        var blockedPickups = 0
        var firstPickupTime: Date?
        var firstBlockedOpenTime: Date?
        var longestSessionDuration: TimeInterval = 0

        // Load selected apps/categories tokens from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")
        var selectedAppTokens = Set<ApplicationToken>()
        var selectedCategoryTokens = Set<ActivityCategoryToken>()

        // Load app tokens
        if let tokensData = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: tokensData) {
            selectedAppTokens = tokens
        }

        // Load category tokens
        if let tokensData = sharedDefaults?.data(forKey: "com.screenfare.selectedCategories"),
           let tokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: tokensData) {
            selectedCategoryTokens = tokens
        }

        // If we can't load tokens, we'll just track all apps as "total" and won't separate blocked
        let canSeparateBlocked = !selectedAppTokens.isEmpty || !selectedCategoryTokens.isEmpty

        // Date formatter for daily tracking
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"

        // Track min/max dates to determine if this is today or week
        var minDate: Date?
        var maxDate: Date?

        // Iterate through all device activity data
        var appIndex = 0
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                // Add segment total to overall total
                totalSeconds += segment.totalActivityDuration

                // Track date range
                if minDate == nil || segment.dateInterval.start < minDate! {
                    minDate = segment.dateInterval.start
                }
                if maxDate == nil || segment.dateInterval.end > maxDate! {
                    maxDate = segment.dateInterval.end
                }

                // Extract hour from segment for hourly chart
                let hour = calendar.component(.hour, from: segment.dateInterval.start)
                let currentHourUsage = hourlyUsageMap[hour] ?? 0
                hourlyUsageMap[hour] = currentHourUsage + segment.totalActivityDuration

                // Track per day for week chart
                let dayString = dayFormatter.string(from: segment.dateInterval.start)
                let currentDayUsage = dailyUsageMap[dayString] ?? 0
                dailyUsageMap[dayString] = currentDayUsage + segment.totalActivityDuration

                // Iterate through categories and apps
                for await category in segment.categories {
                    // Check if this category is in the blocked set by comparing tokens
                    // Note: category.category is an ActivityCategory, we need its token
                    let activityCategory = category.category
                    let categoryToken = activityCategory.token
                    let isCategoryBlocked = canSeparateBlocked && categoryToken != nil && selectedCategoryTokens.contains(categoryToken!)

                    for await app in category.applications {
                        let appDuration = app.totalActivityDuration
                        let appPickups = app.numberOfPickups

                        // Always count towards total
                        totalPickups += appPickups

                        // Track first pickup time (earliest segment with any activity)
                        if appPickups > 0 {
                            if firstPickupTime == nil || segment.dateInterval.start < firstPickupTime! {
                                firstPickupTime = segment.dateInterval.start
                            }
                        }

                        // Track longest session (segment duration)
                        if appDuration > longestSessionDuration {
                            longestSessionDuration = appDuration
                        }

                        // Track per-app usage for ALL apps - get token if available
                        let appObject = app.application
                        let appHash = appObject.hashValue  // Still use hash as unique ID for tracking

                        // Check if this app's token is in the blocked set
                        let appToken = appObject.token
                        let isAppBlocked = canSeparateBlocked && appToken != nil && selectedAppTokens.contains(appToken!)

                        // Add to blocked totals if app OR category is blocked
                        if isAppBlocked || isCategoryBlocked {
                            blockedSeconds += appDuration
                            blockedPickups += appPickups

                            // Track first blocked open time
                            if appPickups > 0 {
                                if firstBlockedOpenTime == nil || segment.dateInterval.start < firstBlockedOpenTime! {
                                    firstBlockedOpenTime = segment.dateInterval.start
                                }
                            }
                        }

                        let appId = String(appHash)  // Use hashValue as unique ID for tracking

                        if let existing = appUsageMap[appId] {
                            // App already tracked, add to duration
                            appUsageMap[appId] = (token: appToken, app: appObject, duration: existing.duration + appDuration)
                        } else {
                            // First time seeing this app
                            appUsageMap[appId] = (token: appToken, app: appObject, duration: appDuration)
                        }
                        appIndex += 1
                    }
                }
            }
        }

        // Determine if this is a week view (7 days) or today view (1 day)
        let isWeekView: Bool
        if let min = minDate, let max = maxDate {
            let daysDiff = calendar.dateComponents([.day], from: min, to: max).day ?? 0
            isWeekView = daysDiff >= 6  // 7 days = 6 day difference
        } else {
            isWeekView = false
        }

        let totalMinutes = max(0, Int(totalSeconds / 60))
        let blockedMinutes = max(0, Int(blockedSeconds / 60))

        // For previous day/week comparison, estimate based on current data
        let previousMinutes = totalMinutes > 0 ? Int(Double(totalMinutes) * 1.5) : (isWeekView ? 1820 : 270)
        let previousBlockedMinutes = blockedMinutes > 0 ? Int(Double(blockedMinutes) * 1.5) : (isWeekView ? 496 : 44)

        // Generate daily data for the week using REAL data from dailyUsageMap
        let today = Date()
        var dailyData: [DayData] = []
        var dailyDataWithFullNames: [(dayLabel: String, fullName: String, minutes: Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let isToday = dayOffset == 0

            let labelFormatter = DateFormatter()
            labelFormatter.dateFormat = "E"
            let fullDayName = labelFormatter.string(from: date) // e.g., "Mon", "Tue"
            let dayLabel = String(fullDayName.prefix(1))

            // Use REAL data from dailyUsageMap if available
            let dayString = dayFormatter.string(from: date)
            let duration = dailyUsageMap[dayString] ?? 0
            let minutes = Int(duration / 60)

            // For week view, highlight the last day; for today view, highlight today
            let shouldHighlight = isWeekView ? (dayOffset == 0) : isToday

            dailyData.append(DayData(dayLabel: dayLabel, minutes: minutes, isToday: shouldHighlight))
            dailyDataWithFullNames.append((dayLabel: dayLabel, fullName: fullDayName, minutes: minutes))
        }

        // Convert app usage map to sorted array (top 5 apps by duration)
        var topApps: [AppData] = []

        for (appId, appData) in appUsageMap.sorted(by: { $0.value.duration > $1.value.duration }).prefix(5) {
            let minutes = Int(appData.duration / 60)
            if minutes > 0 {
                // Store both token (if available) and Application object
                topApps.append(AppData(id: appId, token: appData.token, app: appData.app, minutes: minutes))
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
        let blockedOpensCount = max(1, blockedPickups)
        let longestSessionMinutes = longestSessionDuration > 0 ? Int(longestSessionDuration / 60) : nil

        // Find busiest day with full name
        let busiestDay = dailyDataWithFullNames.max(by: { $0.minutes < $1.minutes })?.fullName ?? "Mon"

        let stats = ActivityStats(
            opens: opens,
            blockedOpens: blockedOpensCount,
            perDay: max(1, blockedOpensCount / 7),
            busiest: busiestDay,
            firstPickupTime: firstPickupTime,
            firstBlockedOpenTime: firstBlockedOpenTime,
            longestSessionMinutes: longestSessionMinutes
        )

        logger.info("Report complete: \(totalMinutes)m total, \(blockedMinutes)m blocked (\(topApps.count) apps, \(opens) pickups)")

        return ActivityConfig(
            totalMinutes: totalMinutes,
            blockedMinutes: blockedMinutes,
            previousMinutes: previousMinutes,
            previousBlockedMinutes: previousBlockedMinutes,
            dailyData: dailyData,
            hourlyData: hourlyData,
            topApps: topApps,
            stats: stats,
            isWeekView: isWeekView
        )
    }
}

// MARK: - Today Stats Report (Lightweight - only calculates blocked time)

struct TodayStatsConfig: Sendable {
    let blockedMinutes: Int
}

struct TodayStatsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .todayBlockedAppsUsageTime
    let content: (TodayStatsConfig) -> TodayStatsView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TodayStatsConfig {
        let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")
        var blockedSeconds: TimeInterval = 0

        // Load selected apps/categories tokens
        var selectedAppTokens = Set<ApplicationToken>()
        var selectedCategoryTokens = Set<ActivityCategoryToken>()

        if let tokensData = sharedDefaults?.data(forKey: "com.screenfare.selectedApps"),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: tokensData) {
            selectedAppTokens = tokens
        }

        if let tokensData = sharedDefaults?.data(forKey: "com.screenfare.selectedCategories"),
           let tokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: tokensData) {
            selectedCategoryTokens = tokens
        }

        let canSeparateBlocked = !selectedAppTokens.isEmpty || !selectedCategoryTokens.isEmpty

        // Iterate through activity data (hourly segments for today)
        if canSeparateBlocked {
            for await deviceData in data {
                for await segment in deviceData.activitySegments {
                    for await category in segment.categories {
                        let categoryToken = category.category.token
                        let isCategoryBlocked = categoryToken != nil && selectedCategoryTokens.contains(categoryToken!)

                        for await app in category.applications {
                            let appToken = app.application.token
                            let isAppBlocked = appToken != nil && selectedAppTokens.contains(appToken!)

                            if isAppBlocked || isCategoryBlocked {
                                blockedSeconds += app.totalActivityDuration
                            }
                        }
                    }
                }
            }
        }

        let blockedMinutes = max(0, Int(blockedSeconds / 60))

        print("[TodayStatsReport] Blocked minutes today: \(blockedMinutes)")

        return TodayStatsConfig(blockedMinutes: blockedMinutes)
    }
}
