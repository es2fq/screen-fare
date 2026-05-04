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
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                Text("Enable Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Notifications help you unlock apps when you tap the shield screen")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                PermissionReasonRow(icon: "hand.tap.fill", text: "Tap 'Unlock' on a blocked app's shield screen")
                PermissionReasonRow(icon: "bell.fill", text: "Receive a notification to open ScreenFare")
                PermissionReasonRow(icon: "brain.head.profile", text: "Complete a challenge to unlock the app")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                requestNotificationPermission()
            } label: {
                Text(isAuthorized ? "Notifications Enabled ✓" : "Enable Notifications")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAuthorized ? Color.green : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(isAuthorized)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .onChange(of: isAuthorized) { authorized in
            if authorized {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                isAuthorized = granted
            }
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}

#Preview {
    OnboardingNotificationView(onContinue: {})
}
