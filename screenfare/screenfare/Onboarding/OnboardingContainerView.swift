//
//  OnboardingContainerView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls
import UserNotifications

struct OnboardingContainerView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var currentPage = 0
    @State private var selectedApps = FamilyActivitySelection()
    @State private var selectedDifficulty: ChallengeDifficulty = .medium
    @State private var selectedDuration: TimeInterval = 1800 // 30 minutes

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header that doesn't animate with page transitions
                if currentPage > 0 {
                    ScreenHeader(currentStep: currentPage, onBack: previousPage, hideBackButton: currentPage < 4)
                        .padding(.horizontal, 28)
                        .transition(.opacity)
                }

                // Content area with page transitions
                TabView(selection: $currentPage) {
                    OnboardingWelcomeView(onContinue: nextPageFromWelcome)
                        .tag(0)

                    OnboardingScreenTimeView(onContinue: nextPage)
                        .tag(1)

                    OnboardingNotificationView(onContinue: nextPage)
                        .tag(2)

                    OnboardingAppSelectionView(selectedApps: $selectedApps, onContinue: nextPage)
                        .tag(3)

                    OnboardingDifficultyView(selectedDifficulty: $selectedDifficulty, onContinue: nextPage)
                        .id("difficulty-view") // Maintain view identity to prevent recreation
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
                .interactiveDismissDisabled()
            }
        }
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

    private func previousPage() {
        // Don't allow going back before the difficulty screen (page 4)
        guard currentPage >= 4 else { return }

        withAnimation {
            currentPage -= 1
        }
    }

    private func nextPageFromWelcome() {
        // First, explicitly check Screen Time authorization status
        blockingManager.checkAuthorizationStatus()

        // Check both permissions asynchronously
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            let notificationsAuthorized = notificationSettings.authorizationStatus == .authorized

            // Get Screen Time authorization status on main thread
            DispatchQueue.main.async {
                let screenTimeAuthorized = self.blockingManager.isAuthorized

                let targetPage: Int

                if !screenTimeAuthorized {
                    // Need Screen Time permission
                    targetPage = 1
                } else if !notificationsAuthorized {
                    // Screen Time OK, need Notifications
                    targetPage = 2
                } else {
                    // Both authorized, skip to App Selection
                    targetPage = 3
                }

                // Only animate if going to adjacent screen, otherwise instant jump
                let isAdjacentScreen = (targetPage - self.currentPage) == 1

                if isAdjacentScreen {
                    withAnimation {
                        self.currentPage = targetPage
                    }
                } else {
                    self.currentPage = targetPage
                }
            }
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
