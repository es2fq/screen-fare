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
        // Use bounded array instead of unbounded map to prevent memory explosion
        // Only track top 10 apps instead of storing all 100+ apps in memory
        var topApps: [(id: String, token: ApplicationToken?, app: Application, duration: TimeInterval)] = []
        let maxAppsToTrack = 10
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
                // Track date range for all segments
                if minDate == nil || segment.dateInterval.start < minDate! {
                    minDate = segment.dateInterval.start
                }
                if maxDate == nil || segment.dateInterval.end > maxDate! {
                    maxDate = segment.dateInterval.end
                }

                // Don't add to totalSeconds here - we'll calculate it later after determining if it's week view

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

                        // Bounded app tracking: only keep top N apps to prevent memory explosion
                        if let index = topApps.firstIndex(where: { $0.id == appId }) {
                            // App already in top list, update duration
                            topApps[index].duration += appDuration
                        } else if topApps.count < maxAppsToTrack {
                            // Haven't reached limit, add new app
                            topApps.append((id: appId, token: appToken, app: appObject, duration: appDuration))
                        } else {
                            // At capacity - only replace if this app has more usage than the minimum
                            if let minIndex = topApps.indices.min(by: { topApps[$0].duration < topApps[$1].duration }),
                               topApps[minIndex].duration < appDuration {
                                topApps[minIndex] = (id: appId, token: appToken, app: appObject, duration: appDuration)
                            }
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

        // NOW calculate totals based on view type by summing from daily maps
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        if isWeekView {
            // Sum last 7 days (today + previous 6 days)
            for dayOffset in 0...6 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
                let dayString = dayFormatter.string(from: date)
                totalSeconds += dailyUsageMap[dayString] ?? 0
            }
        } else {
            // Only today
            let todayString = dayFormatter.string(from: startOfToday)
            totalSeconds = dailyUsageMap[todayString] ?? 0
        }

        let totalMinutes = max(0, Int(totalSeconds / 60))
        let blockedMinutes = max(0, Int(blockedSeconds / 60))

        // Generate daily data for the week using REAL data from dailyUsageMap
        var dailyData: [DayData] = []
        var dailyDataWithFullNames: [(dayLabel: String, fullName: String, minutes: Int)] = []

        // Create DateFormatter once outside loop for better performance
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "E"

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            let isToday = dayOffset == 0

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

        // Convert bounded app array to sorted array (top 5 apps by duration)
        let topAppData = topApps
            .sorted(by: { $0.duration > $1.duration })
            .prefix(5)
            .compactMap { appData -> AppData? in
                let minutes = Int(appData.duration / 60)
                guard minutes > 0 else { return nil }
                return AppData(id: appData.id, token: appData.token, app: appData.app, minutes: minutes)
            }

        // Convert hourly usage map to array (all 24 hours)
        var hourlyData: [HourData] = []
        for hour in 0..<24 {
            let duration = hourlyUsageMap[hour] ?? 0
            let minutes = Int(duration / 60)
            hourlyData.append(HourData(id: hour, hour: hour, minutes: minutes))
        }

        // Calculate stats
        let opens = totalPickups
        let blockedOpensCount = blockedPickups
        let longestSessionMinutes = longestSessionDuration > 0 ? Int(longestSessionDuration / 60) : nil

        // Find busiest day with full name
        let busiestDay = dailyDataWithFullNames.max(by: { $0.minutes < $1.minutes })?.fullName ?? "Mon"

        let stats = ActivityStats(
            opens: opens,
            blockedOpens: blockedOpensCount,
            perDay: blockedOpensCount / 7,
            busiest: busiestDay,
            firstPickupTime: firstPickupTime,
            firstBlockedOpenTime: firstBlockedOpenTime,
            longestSessionMinutes: longestSessionMinutes
        )

        logger.info("Report complete: \(totalMinutes)m total, \(blockedMinutes)m blocked (\(topAppData.count) apps, \(opens) pickups)")

        return ActivityConfig(
            totalMinutes: totalMinutes,
            blockedMinutes: blockedMinutes,
            dailyData: dailyData,
            hourlyData: hourlyData,
            topApps: topAppData,
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
        var blockedSeconds: TimeInterval = 0

        // Data is pre-filtered to blocked apps/categories only
        // We need to iterate through individual apps because segment.totalActivityDuration
        // includes ALL apps, not just the filtered ones
        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        // Sum individual app durations (data is already filtered, so no token check needed)
                        blockedSeconds += app.totalActivityDuration
                    }
                }
            }
        }

        let blockedMinutes = max(0, Int(blockedSeconds / 60))

        print("[TodayStatsReport] Blocked minutes today: \(blockedMinutes)")

        return TodayStatsConfig(blockedMinutes: blockedMinutes)
    }
}
