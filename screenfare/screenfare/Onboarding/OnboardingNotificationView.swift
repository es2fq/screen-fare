//
//  OnboardingNotificationView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import UserNotifications

struct OnboardingNotificationView: View {
    @State private var isAuthorized = false
    @State private var isDenied = false
    @State private var hasAdvanced = false
    @State private var isVisible = false
    let onContinue: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 2, onBack: {})

                Spacer()
                    .frame(height: 36)

                // Icon
                PermissionIcon(kind: .notification)

                // Title
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Enable")
                            .font(.instrumentSerif(36))
                            .foregroundColor(.focusInk)
                        Spacer()
                    }

                    HStack {
                        Text("notifications.")
                            .font(.instrumentSerif(36, italic: true))
                            .foregroundColor(.focusInk)
                        Spacer()
                    }
                }
                .padding(.top, 28)

                // Description
                Text("When you tap a blocked app, iOS shows its block screen. Focus sends a notification you can tap to come back here and complete a challenge.")
                    .font(.inter(15.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                // Bullets
                VStack(spacing: 14) {
                    PermissionBullet(text: "A bridge from the iOS block screen back to Focus")
                    PermissionBullet(text: "Tap the notification → complete challenge → unlock")
                    PermissionBullet(text: "No marketing pings, ever")
                }
                .padding(.top, 28)

                Spacer()

                // Primary button
                PrimaryButton(title: "Allow access") {
                    requestNotificationPermission()
                }
                .padding(.bottom, 34)
            }
        }
        .onChange(of: isAuthorized) { authorized in
            if authorized && !hasAdvanced && isVisible {
                hasAdvanced = true
                onContinue()
            }
        }
        .onAppear {
            isVisible = true
            checkNotificationStatus(skipIfAuthorized: true)
        }
        .onDisappear {
            isVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Re-check notification status when returning from Settings (only if this view is visible)
            if isVisible && !hasAdvanced {
                checkNotificationStatus(skipIfAuthorized: false)
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    isAuthorized = true
                    isDenied = false
                } else {
                    checkNotificationStatus(skipIfAuthorized: false)
                }
            }
        }
    }

    private func checkNotificationStatus(skipIfAuthorized: Bool = false) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                isAuthorized = settings.authorizationStatus == .authorized
                isDenied = settings.authorizationStatus == .denied

                // Skip this screen if already authorized (when first appearing)
                if skipIfAuthorized && isAuthorized && !hasAdvanced {
                    hasAdvanced = true
                    onContinue()
                }
                // onChange will handle calling onContinue() in other cases
            }
        }
    }
}

#Preview {
    OnboardingNotificationView(onContinue: {})
}
