//
//  OnboardingContainerView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct OnboardingContainerView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var currentPage = 0
    @State private var selectedApps = FamilyActivitySelection()
    @State private var selectedDifficulty: ChallengeDifficulty = .medium
    @State private var selectedDuration: TimeInterval = 1800 // 30 minutes

    let onComplete: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomeView(onContinue: nextPage)
                .tag(0)

            OnboardingScreenTimeView(onContinue: nextPage)
                .tag(1)

            OnboardingNotificationView(onContinue: nextPage)
                .tag(2)

            OnboardingAppSelectionView(selectedApps: $selectedApps, onContinue: nextPage)
                .tag(3)

            OnboardingDifficultyView(selectedDifficulty: $selectedDifficulty, onContinue: nextPage)
                .tag(4)

            OnboardingTimeWindowView(selectedDuration: $selectedDuration, onContinue: nextPage)
                .tag(5)

            OnboardingSummaryView(
                selectedApps: selectedApps,
                difficulty: selectedDifficulty,
                duration: selectedDuration,
                onComplete: applySettingsAndComplete
            )
            .tag(6)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
        .interactiveDismissDisabled()
        .onAppear {
            UIScrollView.appearance().isScrollEnabled = false
        }
        .onDisappear {
            UIScrollView.appearance().isScrollEnabled = true
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }

    private func applySettingsAndComplete() {
        // Apply all settings
        blockingManager.selectedApps = selectedApps
        blockingManager.applyBlocking()
        settings.challengeDifficulty = selectedDifficulty
        settings.unlockDuration = selectedDuration

        // Complete onboarding
        settings.hasCompletedOnboarding = true
        onComplete()
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}
