//
//  ContentView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var settings = SettingsManager.shared
    @State private var showingChallenge = false
    @State private var showingOnboarding = false

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
                    .sheet(isPresented: $showingChallenge) {
                        ChallengeView()
                    }
                    .onChange(of: notificationManager.shouldShowChallenge) { shouldShow in
                        if shouldShow {
                            showingChallenge = true
                            notificationManager.shouldShowChallenge = false
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
