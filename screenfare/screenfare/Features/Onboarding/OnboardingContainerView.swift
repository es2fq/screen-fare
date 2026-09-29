//
//  OnboardingContainerView.swift
//  Screen Fare
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
    @State private var selectedGridSize: Int = 4
    @State private var selectedDuration: TimeInterval = 1800 // 30 minutes
    @State private var showActivationAnimation = false

    let onComplete: () -> Void

    // Computed property to help type inference
    @ViewBuilder
    private var practiceFareView: some View {
        // Built on arrival (so the memory countdown starts when visible and earlier grid or
        // duration changes are picked up) and kept while the summary slides in
        if currentPage == 6 || currentPage == 7 {
            OnboardingPracticeFareView(
                selectedApps: selectedApps,
                gridSize: selectedGridSize,
                duration: selectedDuration,
                onContinue: nextPage
            )
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var onboardingTabView: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomeView(onContinue: nextPageFromWelcome)
                .tag(0)

            OnboardingScreenTimeView(onContinue: nextPage)
                .tag(1)

            OnboardingNotificationView(onContinue: nextPage)
                .tag(2)

            OnboardingAppSelectionView(selectedApps: $selectedApps, onContinue: nextPage)
                .tag(3)

            OnboardingDifficultyView(selectedGridSize: $selectedGridSize, onContinue: nextPage)
                .id("difficulty-view") // Maintain view identity to prevent recreation
                .tag(4)

            OnboardingTimeWindowView(selectedDuration: $selectedDuration, onContinue: nextPage)
                .tag(5)

            practiceFareView
                .tag(6)

            OnboardingSummaryView(
                selectedApps: selectedApps,
                gridSize: selectedGridSize,
                duration: selectedDuration,
                onComplete: startActivation
            )
            .tag(7)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .interactiveDismissDisabled()
    }

    private var shouldShowHeader: Bool {
        currentPage > 0
    }

    private var shouldHideBackButton: Bool {
        currentPage < 4
    }

    private var skipAction: (() -> Void)? {
        if currentPage == 6 {
            return nextPage
        } else {
            return nil
        }
    }

    @ViewBuilder
    private var screenHeader: some View {
        if shouldShowHeader {
            ScreenHeader(
                currentStep: currentPage,
                onBack: previousPage,
                hideBackButton: shouldHideBackButton,
                onSkip: skipAction
            )
            .padding(.horizontal, 28)
            .transition(.opacity)
        }
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            if showActivationAnimation {
                // Show activation animation
                OnboardingActivationView(
                    selectedApps: selectedApps,
                    duration: selectedDuration,
                    onComplete: finalizeOnboarding
                )
                .transition(.opacity)
            } else {
                // Show onboarding flow
                VStack(spacing: 0) {
                    screenHeader
                    onboardingTabView
                }
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

    private func startActivation() {
        // Apply settings immediately
        blockingManager.selectedApps = selectedApps
        blockingManager.applyBlocking()

        // Set Memory as the default challenge type
        settings.challengeType = .memory
        settings.memoryGridSize = selectedGridSize
        settings.memoryTilesToMatch = min(selectedGridSize + 1, selectedGridSize * selectedGridSize)
        settings.unlockDuration = selectedDuration

        // Show activation animation
        withAnimation {
            showActivationAnimation = true
        }
    }

    private func finalizeOnboarding() {
        // Complete onboarding after animation finishes with smooth fade
        withAnimation(.easeInOut(duration: 0.6)) {
            settings.hasCompletedOnboarding = true
        }

        // Call completion callback after animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete()
        }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}
