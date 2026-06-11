//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Erik Song on 5/3/26.
//

import ManagedSettings
import ManagedSettingsUI
import FamilyControls
import UIKit

/// Defines the appearance of the shield shown when blocked apps are accessed
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        print("[ShieldConfig] configuration() called for app: \(application.bundleIdentifier ?? "unknown")")

        // Check if this app has an active temporary unlock
        if isAppTemporarilyUnlocked(application) {
            // App is unlocked, don't show shield
            print("[ShieldConfig] ✓ App is unlocked, returning empty config")
            return ShieldConfiguration()
        }

        print("[ShieldConfig] 🔒 App is locked, returning shield config")

        // Record block attempt for stats
        recordBlockAttempt()

        // Read unlock duration from App Group
        let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared")
        let unlockDuration = sharedDefaults?.double(forKey: "unlockDuration") ?? 1800 // Default 30 minutes

        let durationText = formatDuration(unlockDuration)
        let subtitle = "Complete a challenge to unlock for \(durationText)"

        // Light, airy color palette
        // Very light, transparent background to let light through
        let backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)

        // Rich, saturated purple for title - pops against light background
        let titleColor = UIColor(red: 0.40, green: 0.25, blue: 0.70, alpha: 1.0)

        // Medium purple-gray for subtitle
        let subtitleColor = UIColor(red: 0.45, green: 0.40, blue: 0.60, alpha: 1.0)

        // Vibrant purple button
        let buttonColor = UIColor(red: 0.50, green: 0.35, blue: 0.75, alpha: 1.0)

        // Muted for secondary button
        let secondaryColor = UIColor(red: 0.55, green: 0.50, blue: 0.60, alpha: 1.0)

        return ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: backgroundColor,
            icon: UIImage(systemName: "sparkles"),
            title: ShieldConfiguration.Label(
                text: "Take a Breath",
                color: titleColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: subtitleColor
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: buttonColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: secondaryColor
            )
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
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

    private func isAppTemporarilyUnlocked(_ application: Application) -> Bool {
        // Load temporary unlocks from shared storage
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let data = sharedDefaults.data(forKey: "com.screenfare.temporaryUnlocks"),
              let unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) else {
            print("[ShieldConfig] No temporary unlocks found")
            return false
        }

        // Check if this specific app has an active unlock
        guard let appTokenData = try? JSONEncoder().encode(application.token),
              let expiryTime = unlocks[appTokenData] else {
            print("[ShieldConfig] App not in unlock list")
            return false
        }

        let now = Date()
        let isUnlocked = now < expiryTime

        let remaining = expiryTime.timeIntervalSince(now)
        print("[ShieldConfig] Unlock check: isUnlocked=\(isUnlocked), remaining=\(Int(remaining))s")

        // THE KEY: iOS calls this method every few seconds while the app is running
        // When unlock expires, we simply return false
        // iOS then shows the shield, immediately kicking the user out!
        // This works for ANY duration, even 1 minute!

        if !isUnlocked {
            print("[ShieldConfig] 🔒 Unlock expired for app, showing shield")
        }

        return isUnlocked
    }

    private func recordBlockAttempt() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared") else {
            print("[ShieldConfig] Failed to access shared defaults")
            return
        }

        // Load current stats
        let storageKey = "com.screenfare.dailyStats"
        let today = todayDateString()

        var stats: DailyStats

        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DailyStats.self, from: data),
           decoded.date == today {
            stats = decoded
        } else {
            stats = DailyStats(date: today)
        }

        // Increment blocks counter
        stats.blocksToday += 1

        // Save back
        if let encoded = try? JSONEncoder().encode(stats) {
            sharedDefaults.set(encoded, forKey: storageKey)
            sharedDefaults.synchronize()
            print("[ShieldConfig] 📊 Block recorded: \(stats.blocksToday) blocks today")
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// Local copy of DailyStats for the extension
private struct DailyStats: Codable {
    var date: String
    var blocksToday: Int
    var challengesSolved: Int
    var timeSavedSeconds: Int

    init(date: String) {
        self.date = date
        self.blocksToday = 0
        self.challengesSolved = 0
        self.timeSavedSeconds = 0
    }
}
