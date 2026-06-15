//
//  screenfareApp.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

@main
struct screenfareApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var blockingManager = AppBlockingManager.shared

    init() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()

        // SYNCHRONOUS re-block check (safety net #3)
        // Check if unlock timer expired while app was closed
        if let expiryTimestamp = UserDefaults.appGroup?.double(forKey: "quotaEndTimestamp"),
           UserDefaults.appGroup?.bool(forKey: "isCurrentlyUnlocked") == true {
            let expiryTime = Date(timeIntervalSince1970: expiryTimestamp)
            let now = Date()

            if now >= expiryTime {
                print("[App Init] ⏰ Unlock expired, re-locking synchronously")
                // Re-block immediately before any async work
                UserDefaults.appGroup?.set(false, forKey: "isCurrentlyUnlocked")
                // The blockingManager will recalculate shields on startup
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Reload state and restart timers when app becomes active
                    Task { @MainActor in
                        blockingManager.loadTemporaryUnlocks()
                        blockingManager.cleanupExpiredUnlocks() // Clean up and reapply shields
                        blockingManager.restartExpiredTimers()
                        print("[App] Did become active - cleaned up expired unlocks")
                    }
                }
        }
    }
}
