//
//  OnboardingScreenTimeView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct OnboardingScreenTimeView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @State private var hasAdvanced = false
    @State private var isVisible = false
    let onContinue: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 1, onBack: {})

                Spacer()
                    .frame(height: 36)

                // Icon
                PermissionIcon(kind: .time)

                // Title: fontSize: 36, lineHeight: 1.05, margin: 0 0 14px
                (Text("Allow Screen\n")
                    .font(.instrumentSerif(36))
                 + Text("Time access.")
                    .font(.instrumentSerif(36, italic: true)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(36 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 28)

                // Description: fontSize: 15.5, lineHeight: 1.5, margin: 0 0 28px
                Text("Focus needs Screen Time to monitor and gently restrict your selected apps.")
                    .font(.inter(15.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(15.5 * 0.5) // lineHeight 1.5 = 50% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)

                // Bullets
                VStack(spacing: 14) {
                    PermissionBullet(text: "Track time spent across apps")
                    PermissionBullet(text: "Apply blocks without leaving Focus")
                    PermissionBullet(text: "Your data never leaves your device")
                }
                .padding(.top, 28)

                Spacer()

                // Primary button
                PrimaryButton(title: "Allow access") {
                    Task {
                        try? await blockingManager.requestAuthorization()
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .onChange(of: blockingManager.isAuthorized) { isAuthorized in
            if isAuthorized && !hasAdvanced && isVisible {
                hasAdvanced = true
                onContinue()
            }
        }
        .onAppear {
            isVisible = true
            // Skip this screen if already authorized
            if blockingManager.isAuthorized && !hasAdvanced {
                hasAdvanced = true
                onContinue()
            }
        }
        .onDisappear {
            isVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Re-check authorization when returning from Settings (only if this view is visible)
            if isVisible && blockingManager.isAuthorized && !hasAdvanced {
                hasAdvanced = true
                onContinue()
            }
        }
    }
}

#Preview {
    OnboardingScreenTimeView(onContinue: {})
}
