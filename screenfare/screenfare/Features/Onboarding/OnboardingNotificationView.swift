//
//  OnboardingNotificationView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import UserNotifications

struct OnboardingNotificationView: View {
    @State private var hasAdvanced = false
    @State private var isVisible = false
    @State private var isDenied = false
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            OnboardingScreen {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 24)

                    // Title: fontSize: 36, lineHeight: 1.05, margin: 0 0 14px
                    (Text("Enable ")
                        .font(.instrumentSerif(36))
                        .foregroundColor(.focusInk)
                     + Text("notifications.")
                        .font(.instrumentSerif(36, italic: true))
                        .foregroundColor(.focusAccent))
                        .lineSpacing(36 * 0.05) // lineHeight 1.05 = 5% extra spacing
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 28)

                    // Description: fontSize: 15.5, lineHeight: 1.5, margin: 0 0 28px
                    Text("Screen Time sends a notification you can tap to pay a fare.")
                        .font(.inter(16))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(16 * 0.5) // lineHeight 1.5 = 50% extra spacing
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 14)

                    Spacer()

                    // Primary button - changes based on permission status
                    PrimaryButton(title: isDenied ? "Open Settings" : "Allow access") {
                        if isDenied {
                            openSettings()
                        } else {
                            // Check if already authorized before requesting
                            checkPermissionStatusAndProceed()
                        }
                    }

                    // Skip button (only shown when denied)
                    if isDenied {
                        Button(action: {
                            // Skip and continue to next screen
                            if !hasAdvanced {
                                hasAdvanced = true
                                onContinue()
                            }
                        }) {
                            Text("Skip")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(.focusMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .padding(.top, 12)
                    }

                    Spacer()
                        .frame(height: 34)
                }
            }

            // Show different prompts based on permission status
            if isDenied {
                // Settings screen mockup when denied
                SettingsScreenMockup(onTap: {
                    openSettings()
                })
                .offset(y: 0)
            } else {
                // Notification prompt - positioned like iOS system alert
                NotificationPermissionPrompt(onTap: {
                    checkPermissionStatusAndProceed()
                })
                .offset(y: 27)
            }
        }
        .onAppear {
            isVisible = true
            checkPermissionStatus()
        }
        .onDisappear {
            isVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Re-check when returning from Settings
            if isVisible {
                checkPermissionStatus()
            }
        }
    }

    private func checkPermissionStatusAndProceed() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    // Already authorized, proceed immediately
                    if !self.hasAdvanced {
                        self.hasAdvanced = true
                        self.onContinue()
                    }
                } else {
                    // Not authorized, request permission
                    self.requestNotificationPermission()
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Check status after request completes
            DispatchQueue.main.async {
                self.checkPermissionStatus()

                // Only advance if granted and we haven't already advanced
                if granted && !self.hasAdvanced {
                    self.hasAdvanced = true
                    self.onContinue()
                }
            }
        }
    }

    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = settings.authorizationStatus

                // Update isDenied state
                self.isDenied = (status == .denied)

                // If authorized, advance automatically
                if status == .authorized && !self.hasAdvanced && self.isVisible {
                    self.hasAdvanced = true
                    self.onContinue()
                }
            }
        }
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    OnboardingNotificationView(onContinue: {})
}
