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
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Enable Notifications")
                    .font(.system(size: 34, weight: .bold))

                Text("Get notified when you need to complete a challenge")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                NotificationStep(icon: "hand.tap.fill", text: "Tap unlock on blocked app")
                NotificationStep(icon: "bell.fill", text: "Receive notification")
                NotificationStep(icon: "brain.head.profile", text: "Complete challenge")
            }
            .padding(.horizontal, 40)

            Spacer()

            if isDenied {
                VStack(spacing: 12) {
                    Text("Permission Denied")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("To enable notifications, go to Settings → ScreenFare → Notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                requestNotificationPermission()
            } label: {
                Text("Enable Notifications")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
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

struct NotificationStep: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    OnboardingNotificationView(onContinue: {})
}
