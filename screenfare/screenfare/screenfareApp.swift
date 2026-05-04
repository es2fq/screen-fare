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

    init() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
        }
    }
}
