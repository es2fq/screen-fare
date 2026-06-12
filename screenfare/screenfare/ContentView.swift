//
//  ContentView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var darwinNotificationManager = DarwinNotificationManager.shared
    @StateObject private var shieldCommunicationManager = ShieldCommunicationManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var showingChallenge = false
    @State private var showingOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView(selectedTab: $selectedTab)
                    .sheet(isPresented: $showingChallenge) {
                        ChallengeView()
                            .environment(\.selectedTab, $selectedTab)
                    }
                    .onChange(of: notificationManager.shouldShowChallenge) { _, shouldShow in
                        if shouldShow {
                            showingChallenge = true
                            notificationManager.shouldShowChallenge = false
                        }
                    }
                    .onChange(of: darwinNotificationManager.shouldShowChallenge) { _, shouldShow in
                        if shouldShow {
                            showingChallenge = true
                            darwinNotificationManager.shouldShowChallenge = false
                        }
                    }
                    .onChange(of: shieldCommunicationManager.shouldShowChallenge) { _, shouldShow in
                        print("[ContentView] shieldCommunicationManager.shouldShowChallenge changed to: \(shouldShow)")
                        if shouldShow {
                            print("[ContentView] Setting showingChallenge = true")
                            showingChallenge = true
                            shieldCommunicationManager.shouldShowChallenge = false
                            print("[ContentView] Challenge sheet should now appear")
                        }
                    }
            } else {
                OnboardingContainerView {
                    // Onboarding complete - this will trigger a view update
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager.shared)
}
