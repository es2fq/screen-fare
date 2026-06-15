//
//  AboutDetailView.swift
//  screenfare
//
//  About & Support detail screen
//

import SwiftUI

struct AboutDetailView: View {
    @Binding var showToast: ToastData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App info card
            AppCard(padding: EdgeInsets(top: 20, leading: 18, bottom: 20, trailing: 18)) {
                HStack(spacing: 14) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.focusInk)
                            .frame(width: 52, height: 52)

                        Text("f")
                            .font(.instrumentSerif(32, italic: true))
                            .foregroundColor(.white)
                            .kerning(-1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Fare")
                            .font(.inter(16, weight: .semibold))
                            .foregroundColor(.focusInk)

                        Text("Version 1.0 · build 14")
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()
                }
            }
            .padding(.bottom, 4)

            // Support section
            SectionTitle(text: "Support")

            AppCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: SettIcon(path: "M11 16v0M8.5 8.5a2.5 2.5 0 014.6 1.3c0 1.7-2.1 1.9-2.1 3.2", circle: "11,11,8"),
                        label: "Help center",
                        sub: "Guides & common questions",
                        right: AnyView(Chevron()),
                        action: {
                            showToast = ToastData(message: "Opens in Safari")
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M4 6h14v10H4zM4 7l7 5 7-5"),
                        label: "Contact support",
                        sub: "We read every message",
                        right: AnyView(Chevron()),
                        last: true,
                        action: {
                            showToast = ToastData(message: "Opens Mail")
                        }
                    )
                }
            }

            // Spread the word section
            SectionTitle(text: "Spread the word")

            AppCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: SettIcon(path: "M11 4l2.5 5 5.5.8-4 4 1 5.5-5-2.6-5 2.6 1-5.5-4-4 5.5-.8L11 4z"),
                        label: "Rate Screen Fare",
                        sub: "A review keeps it free",
                        right: AnyView(Chevron()),
                        action: {
                            showToast = ToastData(message: "Opens the App Store")
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M11 4l2 4 4 .6-3 3 .8 4.4L11 14l-3.8 2 .8-4.4-3-3 4-.6 2-4z"),
                        label: "What's new",
                        right: AnyView(Chevron()),
                        last: true,
                        action: {
                            showToast = ToastData(message: "You're on the latest version")
                        }
                    )
                }
            }

            Spacer()
                .frame(height: 26)

            // Tagline
            Text("The pause before you scroll.")
                .font(.instrumentSerif(18, italic: true))
                .foregroundColor(.focusMuted)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
                .frame(height: 16)
        }
    }
}
