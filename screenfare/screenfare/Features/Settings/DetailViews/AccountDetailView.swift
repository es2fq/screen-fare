//
//  AccountDetailView.swift
//  Screen Fare
//
//  Account settings detail screen
//

import SwiftUI

struct AccountDetailView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var showToast: ToastData?
    @Binding var showConfirm: ConfirmDialogData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile card
            AppCard(padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)) {
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.focusAccent)
                            .frame(width: 56, height: 56)

                        Text(String(settings.userName.prefix(1).lowercased()))
                            .font(.instrumentSerif(26, italic: true))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.userName)
                            .font(.inter(17, weight: .semibold))
                            .foregroundColor(.focusInk)

                        Text(settings.userEmail)
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()
                }
            }
            .padding(.bottom, 4)

            // Profile section
            SectionTitle(text: "Profile")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                VStack(spacing: 0) {
                    SettingsRow(
                        label: "Name",
                        right: AnyView(
                            Text(settings.userName)
                                .font(.inter(14))
                                .foregroundColor(.focusMuted)
                        ),
                        action: {
                            showToast = ToastData(message: "Edit your name in the App Store account")
                        }
                    )

                    SettingsRow(
                        label: "Email",
                        right: AnyView(
                            Text(settings.userEmail)
                                .font(.inter(14))
                                .foregroundColor(.focusMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 150)
                        ),
                        last: true,
                        action: {
                            showToast = ToastData(message: "Email is managed by your Apple ID")
                        }
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Backup section
            SectionTitle(text: "Backup")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                ToggleRow(
                    icon: SettIcon(path: "M6 10a5 5 0 019.6-1.8A4 4 0 1116 17H7a4 4 0 01-1-7z"),
                    label: "iCloud sync",
                    sub: "Keep blocks and stats across your devices",
                    value: $settings.iCloudSyncEnabled,
                    last: true
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Session section
            SectionTitle(text: "Session")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                SettingsRow(
                    icon: SettIcon(path: "M13 4H6a2 2 0 00-2 2v10a2 2 0 002 2h7M9 11h9m0 0l-3-3m3 3l-3 3"),
                    label: "Sign out",
                    right: AnyView(Chevron()),
                    danger: true,
                    last: true,
                    action: {
                        showConfirm = ConfirmDialogData(
                            title: "Sign out",
                            body: "Your blocks stay active on this device. You can sign back in any time to restore your history.",
                            confirmLabel: "Sign out",
                            isDanger: true,
                            onConfirm: {
                                showToast = ToastData(message: "Signed out")
                            }
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Danger zone
            SectionTitle(text: "Danger zone")

            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                SettingsRow(
                    icon: SettIcon(path: "M5 6h12M9 6V4h4v2M7 6l1 12h6l1-12"),
                    label: "Delete account",
                    sub: "Erases your account and all synced data",
                    right: AnyView(Chevron()),
                    danger: true,
                    last: true,
                    action: {
                        showConfirm = ConfirmDialogData(
                            title: "Delete account",
                            body: "This permanently erases your account, synced blocks, and all history. This can't be undone.",
                            confirmLabel: "Delete forever",
                            isDanger: true,
                            onConfirm: {
                                showToast = ToastData(message: "Account scheduled for deletion")
                            }
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Spacer()
                .frame(height: 12)
        }
    }
}
