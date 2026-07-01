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

    // Cache for brand icon to avoid repeated Bundle I/O
    private static var cachedBrandIcon: UIImage?
    private static var iconLoadAttempted = false

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

        return createCustomShieldConfiguration(for: application)
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

        return createCustomShieldConfiguration(for: application)
    }

    private func createCustomShieldConfiguration(for application: Application) -> ShieldConfiguration {
        // Read unlock duration from App Group
        let sharedDefaults = UserDefaults.appGroup
        let unlockDuration = sharedDefaults?.double(forKey: "unlockDuration") ?? 1800 // Default 30 minutes

        let durationText = TimeInterval(unlockDuration).formatted()

        // Get the app name
        let appName = application.localizedDisplayName ?? "this app"
        let subtitle = "\(appName) is on your blocklist — pay the fare for \(durationText) of access."

        // ScreenFare brand colors
        // #F5F2ED - Cream/warm off-white background (fully opaque)
        let backgroundColor = UIColor(red: 0.961, green: 0.949, blue: 0.929, alpha: 1.0)

        // #1A1A1A - Near-black for title (focusInk)
        let titleColor = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0)

        // #8B8680 - Muted gray for subtitle (focusMuted)
        let subtitleColor = UIColor(red: 0.545, green: 0.525, blue: 0.502, alpha: 1.0)

        // #D8764A - Orange/terracotta accent for primary button (focusAccent)
        let buttonColor = UIColor(red: 0.847, green: 0.463, blue: 0.290, alpha: 1.0)

        // Load and round the app icon (cached to avoid repeated Bundle I/O)
        let appIcon: UIImage? = {
            // Return cached icon if available
            if let cached = ShieldConfigurationExtension.cachedBrandIcon {
                return cached
            }

            // Only attempt to load once
            guard !ShieldConfigurationExtension.iconLoadAttempted else {
                return nil
            }

            ShieldConfigurationExtension.iconLoadAttempted = true

            guard let image = UIImage(named: "BrandIcon") else { return nil }
            let size = CGSize(width: 60, height: 60)
            let cornerRadius: CGFloat = 13.5 // iOS app icon corner radius proportion

            let renderer = UIGraphicsImageRenderer(size: size)
            let processedIcon = renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
                image.draw(in: rect)
            }

            // Cache the processed icon
            ShieldConfigurationExtension.cachedBrandIcon = processedIcon
            return processedIcon
        }()

        return ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: backgroundColor,
            icon: appIcon,
            title: ShieldConfiguration.Label(
                text: "Fare due",
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
                text: "Walk away",
                color: titleColor
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
