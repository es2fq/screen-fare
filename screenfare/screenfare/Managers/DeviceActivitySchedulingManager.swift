//
//  DeviceActivitySchedulingManager.swift
//  Screen Fare
//
//  Manages all DeviceActivity monitor scheduling
//
//  ## Purpose
//  - Schedule reblock chains for temporary unlocks (both apps and categories)
//  - Setup schedule-based monitoring (enable/disable blocking by time windows)
//  - Setup 24/7 insights monitoring for screen time tracking
//  - Track active monitors to enable cleanup
//

import Foundation
import DeviceActivity
import ScreenFareShared

@MainActor
class DeviceActivitySchedulingManager {
    // MARK: - Properties

    private let activityCenter = DeviceActivityCenter()

    // Track active monitors for cleanup
    var activeMonitors: [Data: DeviceActivityName] = [:] // Unlock monitors
    var activeScheduleMonitors: [DeviceActivityName] = [] // Schedule window monitors

    // MARK: - Reblock Chain Scheduling

    /// Schedule DeviceActivity monitor to re-lock app at expiry time
    /// Uses warningTime trick for short timers (<15min), intervalDidEnd for long timers
    func scheduleReblockChain(appTokenData: Data, activityName: DeviceActivityName, expiryTime: Date) {
        let duration = expiryTime.timeIntervalSinceNow

        guard duration > 0 else {
            print("[DeviceActivitySchedulingManager] ⚠️ Expiry time already passed")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // THE TRICK: For short unlocks, set interval to 15 min but use warningTime
        // to fire at the actual expiry time
        if duration < 15 * 60 {
            // Short timer: Use warningTime trick (like Opal/Jomo)
            let intervalEnd = now.addingTimeInterval(15 * 60) // Always 15 min (minimum)
            let warningMinutes = Int((15 * 60 - duration) / 60) // Fire warning at actual expiry

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false,
                warningTime: DateComponents(minute: warningMinutes) // Fires at actual expiry
            )

            do {
                try activityCenter.startMonitoring(activityName, during: schedule)
                print("[DeviceActivitySchedulingManager] ✓ Short timer: interval=15min, warningTime=\(warningMinutes)min")
            } catch {
                print("[DeviceActivitySchedulingManager] ⚠️ Failed to schedule: \(error)")
            }
        } else {
            // Long timer: Use direct intervalDidEnd
            let intervalEnd = expiryTime

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false
            )

            do {
                try activityCenter.startMonitoring(activityName, during: schedule)
                print("[DeviceActivitySchedulingManager] ✓ Long timer: interval ends in \(Int(duration))s")
            } catch {
                print("[DeviceActivitySchedulingManager] ⚠️ Failed to schedule: \(error)")
            }
        }

        // Track this monitor
        activeMonitors[appTokenData] = activityName
    }

    /// Schedule DeviceActivity monitor to re-lock category at expiry time
    /// Similar to scheduleReblockChain but for categories (no usage tracking events)
    func scheduleReblockChainForCategory(categoryTokenData: Data, activityName: DeviceActivityName, expiryTime: Date) {
        let duration = expiryTime.timeIntervalSinceNow

        guard duration > 0 else {
            print("[DeviceActivitySchedulingManager] ⚠️ Category expiry time already passed")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Use same approach as apps: warningTime trick for short timers, intervalDidEnd for long
        if duration < 15 * 60 {
            // Short timer: Use warningTime trick
            let intervalEnd = now.addingTimeInterval(15 * 60)
            let warningMinutes = Int((15 * 60 - duration) / 60)

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false,
                warningTime: DateComponents(minute: warningMinutes)
            )

            // No usage tracking events for categories (empty dict)
            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[DeviceActivitySchedulingManager] ✓ Category short timer: interval=15min, warningTime=\(warningMinutes)min (fires in \(Int(duration))s)")
            } catch {
                print("[DeviceActivitySchedulingManager] ⚠️ Failed to schedule category timer: \(error)")
            }
        } else {
            // Long timer: Use direct intervalDidEnd
            let intervalEnd = expiryTime

            let start = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now)
            )

            let end = DateComponents(
                calendar: calendar,
                hour: calendar.component(.hour, from: intervalEnd),
                minute: calendar.component(.minute, from: intervalEnd),
                second: calendar.component(.second, from: intervalEnd)
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: false
            )

            // No usage tracking events for categories (empty dict)
            let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            do {
                try activityCenter.startMonitoring(activityName, during: schedule, events: events)
                print("[DeviceActivitySchedulingManager] ✓ Category long timer: interval ends in \(Int(duration))s")
            } catch {
                print("[DeviceActivitySchedulingManager] ⚠️ Failed to schedule category timer: \(error)")
            }
        }

        // Track this monitor
        activeMonitors[categoryTokenData] = activityName
    }

    /// Stop monitoring a specific unlock timer
    func stopMonitoring(for tokenData: Data) {
        if let activityName = activeMonitors[tokenData] {
            activityCenter.stopMonitoring([activityName])
            activeMonitors.removeValue(forKey: tokenData)
        }
    }

    // MARK: - Schedule Monitoring

    /// Setup DeviceActivity monitors for scheduled blocking windows
    /// Creates monitors that enable/disable shields at specific times
    func setupScheduleMonitoring(schedule: Schedule) {
        // Only setup monitors if in scheduled mode
        guard schedule.mode == .scheduled else {
            print("[DeviceActivitySchedulingManager] Schedule mode is 'all day', no monitors needed")
            return
        }

        for window in schedule.windows {
            // Convert minutes to hour/minute components
            let startHour = window.start / 60
            let startMinute = window.start % 60
            let endHour = window.end / 60
            let endMinute = window.end % 60

            // Check if this is an overnight window (e.g., 10 PM - 2 AM)
            if window.end < window.start {
                // Split into two monitors:
                // 1. Same-day portion: start time - 11:59 PM
                // 2. Next-day portion: 12:00 AM - end time

                // Monitor 1: start - 23:59
                let activityName1 = DeviceActivityName("schedule.\(window.id).part1")
                let start1 = DateComponents(hour: startHour, minute: startMinute)
                let end1 = DateComponents(hour: 23, minute: 59)

                let deviceSchedule1 = DeviceActivitySchedule(
                    intervalStart: start1,
                    intervalEnd: end1,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName1, during: deviceSchedule1)
                    activeScheduleMonitors.append(activityName1)
                    print("[DeviceActivitySchedulingManager] ✅ Schedule monitor created (part 1): \(window.id) (\(startHour):\(String(format: "%02d", startMinute)) - 23:59)")
                } catch {
                    print("[DeviceActivitySchedulingManager] ⚠️ Failed to create schedule monitor part 1: \(error)")
                }

                // Monitor 2: 00:00 - end time
                let activityName2 = DeviceActivityName("schedule.\(window.id).part2")
                let start2 = DateComponents(hour: 0, minute: 0)
                let end2 = DateComponents(hour: endHour, minute: endMinute)

                let deviceSchedule2 = DeviceActivitySchedule(
                    intervalStart: start2,
                    intervalEnd: end2,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName2, during: deviceSchedule2)
                    activeScheduleMonitors.append(activityName2)
                    print("[DeviceActivitySchedulingManager] ✅ Schedule monitor created (part 2): \(window.id) (00:00 - \(endHour):\(String(format: "%02d", endMinute)))")
                } catch {
                    print("[DeviceActivitySchedulingManager] ⚠️ Failed to create schedule monitor part 2: \(error)")
                }
            } else {
                // Normal same-day window
                let activityName = DeviceActivityName("schedule.\(window.id)")
                let start = DateComponents(hour: startHour, minute: startMinute)
                let end = DateComponents(hour: endHour, minute: endMinute)

                let deviceSchedule = DeviceActivitySchedule(
                    intervalStart: start,
                    intervalEnd: end,
                    repeats: true
                )

                do {
                    try activityCenter.startMonitoring(activityName, during: deviceSchedule)
                    activeScheduleMonitors.append(activityName)
                    print("[DeviceActivitySchedulingManager] ✅ Schedule monitor created: \(window.id) (\(startHour):\(String(format: "%02d", startMinute)) - \(endHour):\(String(format: "%02d", endMinute)))")
                } catch {
                    print("[DeviceActivitySchedulingManager] ⚠️ Failed to create schedule monitor: \(error)")
                }
            }
        }
    }

    /// Stop all schedule monitoring
    func stopScheduleMonitoring() {
        // Stop all tracked schedule monitors (handles deleted/changed windows)
        if !activeScheduleMonitors.isEmpty {
            activityCenter.stopMonitoring(activeScheduleMonitors)
            print("[DeviceActivitySchedulingManager] 🛑 Stopped \(activeScheduleMonitors.count) schedule monitors")
            activeScheduleMonitors.removeAll()
        }
    }

    // MARK: - Insights Monitoring

    /// Setup 24/7 monitoring for screen time insights
    func setupInsightsMonitoring() {
        // Set up DeviceActivity monitoring for screen time insights
        // This runs 24/7 to track usage of ALL apps for reporting

        let activityName = DeviceActivityName("insights.daily")

        // Create a daily schedule that resets at midnight
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            // Monitor all apps (no filter = all apps)
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("[DeviceActivitySchedulingManager] ✅ Insights monitoring started for all apps")
        } catch {
            print("[DeviceActivitySchedulingManager] ⚠️ Failed to start insights monitoring: \(error)")
        }
    }

    /// Stop insights monitoring
    func stopInsightsMonitoring() {
        let activityName = DeviceActivityName("insights.daily")
        activityCenter.stopMonitoring([activityName])
        print("[DeviceActivitySchedulingManager] 🛑 Stopped insights monitoring")
    }

    /// Stop all unlock timers (for cleanup when removing blocking)
    func stopAllUnlockTimers() {
        for (_, activityName) in activeMonitors {
            activityCenter.stopMonitoring([activityName])
        }
        activeMonitors.removeAll()
    }
}
