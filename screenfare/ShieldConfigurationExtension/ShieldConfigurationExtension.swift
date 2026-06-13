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
        // 1. Check schedule FIRST - if outside blocking window, no shield
        if !isBlockingCurrentlyActive() {
            return ShieldConfiguration()
        }

        // 2. Check if this app has an active temporary unlock
        if isAppTemporarilyUnlocked(application) {
            // App is unlocked, don't show shield
            return ShieldConfiguration()
        }

        return createCustomShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // 1. Check schedule FIRST - if outside blocking window, no shield
        if !isBlockingCurrentlyActive() {
            return ShieldConfiguration()
        }

        // 2. Apps blocked via category shield - check if the category itself is temporarily unlocked
        if isCategoryTemporarilyUnlocked(category) {
            return ShieldConfiguration()
        }

        // 3. Check if this specific app has an active temporary unlock
        if isAppTemporarilyUnlocked(application) {
            return ShieldConfiguration()
        }

        return createCustomShieldConfiguration()
    }

    private func createCustomShieldConfiguration() -> ShieldConfiguration {
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
            return false
        }

        // Check if this specific app has an active unlock
        guard let appTokenData = try? JSONEncoder().encode(application.token),
              let expiryTime = unlocks[appTokenData] else {
            return false
        }

        let now = Date()
        return now < expiryTime
    }

    private func isCategoryTemporarilyUnlocked(_ category: ActivityCategory) -> Bool {
        // Load temporary category unlocks from shared storage
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let data = sharedDefaults.data(forKey: "com.screenfare.temporaryCategoryUnlocks"),
              let unlocks = try? JSONDecoder().decode([Data: Date].self, from: data) else {
            return false
        }

        // Check if this specific category has an active unlock
        guard let categoryTokenData = try? JSONEncoder().encode(category.token),
              let expiryTime = unlocks[categoryTokenData] else {
            return false
        }

        let now = Date()
        return now < expiryTime
    }
}
