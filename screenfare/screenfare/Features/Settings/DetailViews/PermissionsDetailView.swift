//
//  PermissionsDetailView.swift
//  screenfare
//
//  Permissions settings detail screen
//

import SwiftUI

struct PermissionsDetailView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var showToast: ToastData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Intro note
            IntroNote(text: "Screen Fare runs on Apple's on-device APIs. It never sees which apps you open by name — only the tokens iOS hands it.")

            // Permissions
            AppCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: SettIcon(path: "M4 6h14v9H4zM4 18h14M9 18v2h4v-2"),
                        label: "Screen Time",
                        sub: "Required — powers blocking & shields",
                        right: AnyView(
                            StatusPill(
                                text: settings.screenTimePermission.displayText,
                                tone: settings.screenTimePermission == .granted ? .on : .warn
                            )
                        ),
                        action: {
                            if settings.screenTimePermission == .granted {
                                showToast = ToastData(message: "Manage in iOS Settings → Screen Time")
                            } else {
                                settings.screenTimePermission = .granted
                                showToast = ToastData(message: "Screen Time access granted")
                            }
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M11 18s-6-4-6-8a3.5 3.5 0 016-2 3.5 3.5 0 016 2c0 4-6 8-6 8z"),
                        label: "Health — steps",
                        sub: "Only for the \"Take a walk\" challenge",
                        right: AnyView(
                            StatusPill(
                                text: settings.healthPermission.displayText,
                                tone: settings.healthPermission == .granted ? .on : .warn
                            )
                        ),
                        last: true,
                        action: {
                            if settings.healthPermission == .granted {
                                showToast = ToastData(message: "Manage in iOS Settings → Health")
                            } else {
                                settings.healthPermission = .granted
                                showToast = ToastData(message: "Health access granted")
                            }
                        }
                    )
                }
            }

            FootNote(text: "You can change any of these in the iOS Settings app at any time. Revoking Screen Time will pause all blocking.")

            Spacer()
                .frame(height: 12)
        }
    }
}
