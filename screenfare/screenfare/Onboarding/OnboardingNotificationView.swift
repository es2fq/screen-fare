//
//  OnboardingNotificationView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import UserNotifications

struct OnboardingNotificationView: View {
    @State private var hasAdvanced = false
    @State private var isVisible = false
    let onContinue: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 2, onBack: {})

                Spacer()
                    .frame(height: 36)

                // Icon - left aligned
                PermissionIcon(kind: .notification)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Title: fontSize: 36, lineHeight: 1.05, margin: 0 0 14px
                (Text("Enable\n")
                    .font(.instrumentSerif(36))
                 + Text("notifications.")
                    .font(.instrumentSerif(36, italic: true)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(36 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 28)

                // Description: fontSize: 15.5, lineHeight: 1.5, margin: 0 0 28px
                Text("When you tap a blocked app, iOS shows its block screen. Focus sends a notification you can tap to come back here and complete a challenge.")
                    .font(.inter(15.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(15.5 * 0.5) // lineHeight 1.5 = 50% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .onAppear {
            print("🔔 [Notifications] onAppear - isVisible: \(isVisible), hasAdvanced: \(hasAdvanced)")
            isVisible = true
        }
        .onDisappear {
            print("🔔 [Notifications] onDisappear")
            isVisible = false
        }
    }

    private func requestNotificationPermission() {
        print("🔔 [Notifications] Button tapped - requesting permission")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 [Notifications] Authorization callback - granted: \(granted), error: \(String(describing: error))")

            // Only advance if granted and we haven't already advanced
            if granted && !self.hasAdvanced {
                DispatchQueue.main.async {
                    print("🔔 [Notifications] ✅ Permission granted - advancing to next screen")
                    self.hasAdvanced = true
                    self.onContinue()
                }
            }
        }
    }
}

#Preview {
    OnboardingNotificationView(onContinue: {})
}
