//
//  DataPrivacyDetailView.swift
//  Screen Fare
//
//  Data & Privacy settings detail screen
//

import SwiftUI

struct DataPrivacyDetailView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var showToast: ToastData?
    @Binding var showConfirm: ConfirmDialogData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Intro note
            IntroNote(text: "Your activity only lives on your device.")

            // MVP: Commented out for initial release
            // Your data section
            // SectionTitle(text: "Your data")
            //
            // AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
            //     VStack(spacing: 0) {
            //         ToggleRow(
            //             icon: SettIcon(path: "M6 10a5 5 0 019.6-1.8A4 4 0 1116 17H7a4 4 0 01-1-7z"),
            //             label: "iCloud sync",
            //             sub: "Back up blocks & stats to iCloud",
            //             value: $settings.iCloudSyncEnabled
            //         )
            //
            //         SettingsRow(
            //             icon: SettIcon(path: "M11 3v11M6 9l5 5 5-5M4 18h14"),
            //             label: "Export your data",
            //             sub: "A CSV of blocks, fares & history",
            //             right: AnyView(Chevron()),
            //             last: true,
            //             action: {
            //                 showToast = ToastData(message: "Preparing your export…")
            //             }
            //         )
            //     }
            //     .clipShape(RoundedRectangle(cornerRadius: 18))
            // }
            //
            // // Reset section
            // SectionTitle(text: "Reset")
            //
            // AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
            //     SettingsRow(
            //         icon: SettIcon(path: "M5 8a6 6 0 1110.5 4M16 5v3h-3"),
            //         label: "Reset statistics",
            //         sub: "Streaks, time saved & history",
            //         right: AnyView(Chevron()),
            //         danger: true,
            //         last: true,
            //         action: {
            //             showConfirm = ConfirmDialogData(
            //                 title: "Reset statistics",
            //                 body: "Clears streaks, time saved, and your activity history. Your blocks and settings stay exactly as they are.",
            //                 confirmLabel: "Reset statistics",
            //                 isDanger: true,
            //                 onConfirm: {
            //                     showToast = ToastData(message: "Statistics reset")
            //                 }
            //             )
            //         }
            //     )
            //     .clipShape(RoundedRectangle(cornerRadius: 18))
            // }

            // Legal section
            SectionTitle(text: "Legal")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: SettIcon(path: "M11 3l7 3v5c0 4-3 7-7 8-4-1-7-4-7-8V6l7-3z"),
                        label: "Privacy policy",
                        right: AnyView(Chevron()),
                        action: {
                            showToast = ToastData(message: "Opens in Safari")
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M6 3h7l4 4v12H6zM13 3v4h4"),
                        label: "Terms of service",
                        right: AnyView(Chevron()),
                        last: true,
                        action: {
                            showToast = ToastData(message: "Opens in Safari")
                        }
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Spacer()
                .frame(height: 12)
        }
    }
}
