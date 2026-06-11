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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Reload state and restart timers when app becomes active
                    Task { @MainActor in
                        blockingManager.loadTemporaryUnlocks()
                        blockingManager.restartExpiredTimers()
                    }
                }
        }
    }
}
