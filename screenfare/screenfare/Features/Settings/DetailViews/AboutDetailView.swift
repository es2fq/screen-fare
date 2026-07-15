//
//  AboutDetailView.swift
//  Screen Fare
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
                    BrandMark(size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Fare")
                            .font(.inter(16, weight: .semibold))
                            .foregroundColor(.focusInk)

                        Text("Version 1.0.0")
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()
                }
            }
            .padding(.bottom, 4)

            // MARK: - Spread the word section (commented out)
            /*
            SectionTitle(text: "Spread the word")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
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
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            */

            Spacer()
                .frame(height: 26)

            // Tagline
            Text("The tax on distraction.")
                .font(.instrumentSerif(18, italic: true))
                .foregroundColor(.focusMuted)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
                .frame(height: 16)
        }
    }
}
