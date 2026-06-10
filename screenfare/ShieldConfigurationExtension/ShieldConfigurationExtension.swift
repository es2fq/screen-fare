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
}
