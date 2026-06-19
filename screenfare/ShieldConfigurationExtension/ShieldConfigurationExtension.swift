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
    // Cache for decoded unlocks to avoid repeated JSON decoding
    private var unlocksCache: (data: Data, unlocks: [Data: Date], timestamp: Date)?
    private var categoryUnlocksCache: (data: Data, unlocks: [Data: Date], timestamp: Date)?
    private let cacheExpirySeconds: TimeInterval = 1.0 // Cache for 1 second

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
        let sharedDefaults = UserDefaults.appGroup
        let unlockDuration = sharedDefaults?.double(forKey: "unlockDuration") ?? 1800 // Default 30 minutes

        let durationText = TimeInterval(unlockDuration).formatted()
        let subtitle = "Pay a fare to unlock for \(durationText)"

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
                text: "Pay fare",
                color: .white
            ),
            primaryButtonBackgroundColor: buttonColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: secondaryColor
            )
        )
    }

    private func isAppTemporarilyUnlocked(_ application: Application) -> Bool {
        guard let sharedDefaults = UserDefaults.appGroup,
              let data = sharedDefaults.data(forKey: "com.screenfare.temporaryUnlocks") else {
            return false
        }

        // Use cached unlocks if available and fresh
        let unlocks: [Data: Date]
        let now = Date()

        if let cache = unlocksCache,
           cache.data == data,
           now.timeIntervalSince(cache.timestamp) < cacheExpirySeconds {
            // Use cached data
            unlocks = cache.unlocks
        } else {
            // Decode fresh data and cache it
            guard let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) else {
                return false
            }
            unlocks = decoded
            unlocksCache = (data, decoded, now)
        }

        // Check if this specific app has an active unlock
        guard let appTokenData = try? JSONEncoder().encode(application.token),
              let expiryTime = unlocks[appTokenData] else {
            return false
        }

        return now < expiryTime
    }

    private func isCategoryTemporarilyUnlocked(_ category: ActivityCategory) -> Bool {
        guard let sharedDefaults = UserDefaults.appGroup,
              let data = sharedDefaults.data(forKey: "com.screenfare.temporaryCategoryUnlocks") else {
            return false
        }

        // Use cached unlocks if available and fresh
        let unlocks: [Data: Date]
        let now = Date()

        if let cache = categoryUnlocksCache,
           cache.data == data,
           now.timeIntervalSince(cache.timestamp) < cacheExpirySeconds {
            // Use cached data
            unlocks = cache.unlocks
        } else {
            // Decode fresh data and cache it
            guard let decoded = try? JSONDecoder().decode([Data: Date].self, from: data) else {
                return false
            }
            unlocks = decoded
            categoryUnlocksCache = (data, decoded, now)
        }

        // Check if this specific category has an active unlock
        guard let categoryTokenData = try? JSONEncoder().encode(category.token),
              let expiryTime = unlocks[categoryTokenData] else {
            return false
        }

        return now < expiryTime
    }
}
