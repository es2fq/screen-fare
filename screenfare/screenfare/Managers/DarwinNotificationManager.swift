//
//  DarwinNotificationManager.swift
//  Screen Fare
//
//  Manages Darwin Notifications for low-level cross-process communication
//  via CFNotificationCenter (system-level notifications)
//
//  ⚠️ NOTE: This is different from NotificationManager!
//
//  ## Purpose
//  - Enables app extensions to communicate with the main app
//  - Works even when main app is terminated or in background
//  - Does NOT require user permission
//  - Does NOT show any visible UI to the user
//
//  ## Use Cases
//  - ShieldActionExtension triggering challenge in main app
//  - DeviceActivityMonitor signaling stats updates
//  - Any extension → app communication that must work without user interaction
//
//  ## How It Works
//  1. Extension posts Darwin notification: CFNotificationCenterPostNotification()
//  2. Main app receives via CFNotificationCenterAddObserver()
//  3. No payload data - just a signal that something happened
//  4. App reads shared state from UserDefaults.appGroup if needed
//
//  ## Related Managers
//  - **NotificationManager**: For user-visible notifications (alerts, banners)
//    that require permission and show in notification center
//
//  ## Notification Names
//  - "com.screenfare.unlockChallenge" - Extension requesting challenge screen
//  - "com.screenfare.statsUpdated" - Extension signaling stats changed
//

import Foundation
import Combine
import UserNotifications

/// Manages Darwin Notifications for cross-process communication (extension → app)
@MainActor
class DarwinNotificationManager: ObservableObject {
    static let shared = DarwinNotificationManager()

    /// Triggers challenge view when extension posts unlock request
    @Published var shouldShowChallenge = false

    /// Callback invoked when extension signals stats have changed
    var onStatsUpdated: (() -> Void)?

    // Darwin notification identifiers (must match extension code)
    private let challengeNotificationName = "com.screenfare.unlockChallenge" as CFString
    private let statsNotificationName = "com.screenfare.statsUpdated" as CFString

    private init() {
        setupDarwinNotificationObserver()
    }

    /// Sets up observers for Darwin notifications from extensions
    /// Uses CFNotificationCenter (low-level) not UNUserNotificationCenter
    private func setupDarwinNotificationObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        // Listen for challenge requests from ShieldActionExtension
        CFNotificationCenterAddObserver(
            center,
            observer,
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()

                Task { @MainActor in
                    manager.shouldShowChallenge = true
                }
            },
            challengeNotificationName,
            nil,
            .deliverImmediately
        )

        // Listen for stats updates from DeviceActivityMonitor (replaces polling)
        CFNotificationCenterAddObserver(
            center,
            observer,
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()

                Task { @MainActor in
                    manager.onStatsUpdated?()
                }
            },
            statsNotificationName,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }
}
