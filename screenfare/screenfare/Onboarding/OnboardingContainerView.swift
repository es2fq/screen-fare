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
        .onAppear {
            UIScrollView.appearance().isScrollEnabled = false
        }
        .onDisappear {
            UIScrollView.appearance().isScrollEnabled = true
        }
    }

    private func nextPage() {
        print("🚀 [Container] nextPage called - currentPage: \(currentPage) -> \(currentPage + 1)")
        withAnimation {
            currentPage += 1
        }
        print("🚀 [Container] nextPage completed - currentPage is now: \(currentPage)")
    }

    private func nextPageFromWelcome() {
        print("🚀 [Container] nextPageFromWelcome called - checking permission statuses")

        // First, explicitly check Screen Time authorization status
        blockingManager.checkAuthorizationStatus()

        // Check both permissions asynchronously
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            let notificationsAuthorized = notificationSettings.authorizationStatus == .authorized
            print("🚀 [Container] Notifications authorized: \(notificationsAuthorized)")

            // Get Screen Time authorization status on main thread
            DispatchQueue.main.async {
                let screenTimeAuthorized = self.blockingManager.isAuthorized
                print("🚀 [Container] Screen Time authorized: \(screenTimeAuthorized)")

                let targetPage: Int

                if !screenTimeAuthorized {
                    // Need Screen Time permission
                    targetPage = 1
                    print("🚀 [Container] Jumping to Screen Time (page 1)")
                } else if !notificationsAuthorized {
                    // Screen Time OK, need Notifications
                    targetPage = 2
                    print("🚀 [Container] Jumping to Notifications (page 2)")
                } else {
                    // Both authorized, skip to App Selection
                    targetPage = 3
                    print("🚀 [Container] Both authorized - jumping to App Selection (page 3)")
                }

                // Only animate if going to adjacent screen, otherwise instant jump
                let isAdjacentScreen = (targetPage - self.currentPage) == 1

                if isAdjacentScreen {
                    print("🚀 [Container] Adjacent screen - animating transition")
                    withAnimation {
                        self.currentPage = targetPage
                    }
                } else {
                    print("🚀 [Container] Skipping screen(s) - instant jump")
                    self.currentPage = targetPage
                }
                print("🚀 [Container] Navigation complete - currentPage is now: \(self.currentPage)")
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
