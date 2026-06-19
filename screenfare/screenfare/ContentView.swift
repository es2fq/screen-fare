//
//  ContentView.swift
//  Screen Fare
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
    @State private var showingLaunchAnimation = false
    @State private var lastChallengeRequestTime: Date?

    var body: some View {
        ZStack {
            Group {
                if settings.hasCompletedOnboarding {
                    MainTabView(selectedTab: $selectedTab)
                        .environment(\.selectedTab, $selectedTab)
                        .sheet(isPresented: $showingChallenge) {
                            ChallengeView()
                                .environment(\.selectedTab, $selectedTab)
                        }
                        .onChange(of: notificationManager.shouldShowChallenge) { _, _ in
                            handleChallengeRequest(from: "NotificationManager")
                        }
                        .onChange(of: darwinNotificationManager.shouldShowChallenge) { _, _ in
                            handleChallengeRequest(from: "DarwinNotificationManager")
                        }
                        .onChange(of: shieldCommunicationManager.shouldShowChallenge) { _, _ in
                            handleChallengeRequest(from: "ShieldCommunicationManager")
                        }
                } else {
                    OnboardingContainerView {
                        // Onboarding complete - this will trigger a view update
                    }
                }
            }
            .opacity(showingLaunchAnimation ? 0 : 1)
            .onAppear {
                // Show animation if user hasn't completed onboarding, or if this was a cold start
                if !settings.hasCompletedOnboarding {
                    showingLaunchAnimation = true
                } else if let launchTime = UserDefaults.standard.object(forKey: "appLaunchTime") as? TimeInterval {
                    let launchScreenDuration = Date().timeIntervalSince1970 - launchTime
                    print("[ContentView] Launch screen was visible for: \(launchScreenDuration) seconds")
                    UserDefaults.standard.removeObject(forKey: "appLaunchTime")

                    // Show animation only if launch took longer than 2 seconds (cold start)
                    if launchScreenDuration > 2.0 {
                        showingLaunchAnimation = true
                    }
                }
            }

            // Launch animation overlay
            if showingLaunchAnimation {
                LaunchAnimationView(
                    speed: 0.7,
                    entrance: "slot",
                    ripple: true,
                    glow: true,
                    landing: true
                ) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingLaunchAnimation = false
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    // MARK: - Helper Functions

    /// Consolidated challenge request handler with deduplication
    /// Prevents showing the same challenge multiple times when multiple sources trigger simultaneously
    private func handleChallengeRequest(from source: String) {
        let now = Date()

        // Debounce: ignore if we just handled a challenge request within the last 0.5 seconds
        if let lastRequest = lastChallengeRequestTime,
           now.timeIntervalSince(lastRequest) < 0.5 {
            print("[ContentView] Ignoring duplicate challenge request from \(source) (debounced)")
            return
        }

        print("[ContentView] Handling challenge request from \(source)")

        // Reset all notification flags
        notificationManager.shouldShowChallenge = false
        darwinNotificationManager.shouldShowChallenge = false
        shieldCommunicationManager.shouldShowChallenge = false

        // Show challenge
        showingChallenge = true
        lastChallengeRequestTime = now
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager.shared)
}
