//
//  SettingsTabView.swift
//  screenfare
//
//  App settings and preferences
//

import SwiftUI

struct SettingsTabView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showingOnboardingReset = false

    var body: some View {
        AppScreen(title: "Settings") {
            VStack(spacing: 18) {
                // Profile section
                SectionTitle(text: "Profile")

                AppCard {
                    HStack(spacing: 14) {
                        // Profile icon
                        ZStack {
                            Circle()
                                .fill(Color.focusAccent.opacity(0.15))
                                .frame(width: 52, height: 52)

                            Text("F")
                                .font(.instrumentSerif(22))
                                .foregroundColor(.focusAccent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus User")
                                .font(.inter(17, weight: .semibold))
                                .foregroundColor(.focusInk)

                            Text("Premium • Active")
                                .font(.inter(13))
                                .foregroundColor(.focusMuted)
                        }

                        Spacer()
                    }
                }

                // General settings
                SectionTitle(text: "General")

                AppCard {
                    VStack(spacing: 14) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            subtitle: "Enabled",
                            action: {}
                        )

                        Divider().background(Color.focusLine)

                        SettingsRow(
                            icon: "hand.raised.fill",
                            title: "Screen Time",
                            subtitle: "Authorized",
                            action: {}
                        )

                        Divider().background(Color.focusLine)

                        SettingsRow(
                            icon: "moon.fill",
                            title: "Do Not Disturb",
                            subtitle: "Off",
                            action: {}
                        )
                    }
                }

                // Behavior section
                SectionTitle(text: "Behavior")

                AppCard {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-relock")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk)

                                Text("Apps relock after access window")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .tint(Color.focusAccent)
                        }

                        Divider().background(Color.focusLine)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Haptic feedback")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk)

                                Text("Vibrate on challenge success")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .tint(Color.focusAccent)
                        }
                    }
                }

                // About section
                SectionTitle(text: "About")

                AppCard {
                    VStack(spacing: 14) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "Version",
                            subtitle: "1.0.0",
                            showChevron: false,
                            action: {}
                        )

                        Divider().background(Color.focusLine)

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Privacy Policy",
                            subtitle: nil,
                            action: {}
                        )

                        Divider().background(Color.focusLine)

                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Support",
                            subtitle: nil,
                            action: {}
                        )
                    }
                }

                // Danger zone
                SectionTitle(text: "Danger zone")

                Button(action: {
                    showingOnboardingReset = true
                }) {
                    AppCard {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset onboarding")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.red)

                                Text("Start setup from scratch")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.focusMuted)
                        }
                    }
                }
                .alert("Reset Onboarding", isPresented: $showingOnboardingReset) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        settings.hasCompletedOnboarding = false
                    }
                } message: {
                    Text("This will reset the app and show the onboarding flow again.")
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.focusInk.opacity(0.06))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.focusInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(.focusInk)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.inter(13))
                            .foregroundColor(.focusMuted)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.focusMuted)
                }
            }
        }
    }
}

#Preview {
    SettingsTabView()
}
