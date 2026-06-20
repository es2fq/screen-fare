//
//  PermissionsDetailView.swift
//  Screen Fare
//
//  Permissions settings detail screen
//

import SwiftUI
import UserNotifications

struct PermissionsDetailView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var showToast: ToastData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Intro note
            IntroNote(text: "Screen Fare needs these permissions to work properly.")

            // Permissions
            AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: SettIcon(path: "M4 6h14v9H4zM4 18h14M9 18v2h4v-2"),
                        label: "Screen Time",
                        sub: "Required for blocking",
                        right: AnyView(
                            StatusPill(
                                text: settings.screenTimePermission.displayText,
                                tone: settings.screenTimePermission == .granted ? .on : .warn
                            )
                        ),
                        action: {
                            if settings.screenTimePermission != .granted {
                                openAppSettings()
                            }
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M12 19c-3.86 0-7-3.14-7-7s3.14-7 7-7 7 3.14 7 7-3.14 7-7 7zm0-12c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5z M12 8v4l3 2"),
                        label: "Notifications",
                        sub: "Alerts for unblocking",
                        right: AnyView(
                            StatusPill(
                                text: settings.notificationPermission.displayText,
                                tone: settings.notificationPermission == .granted ? .on : .warn
                            )
                        ),
                        last: true,
                        action: {
                            handleNotificationPermission()
                        }
                    )

                    // TODO: Re-enable once we have a step challenge
                    // SettingsRow(
                    //     icon: SettIcon(path: "M11 18s-6-4-6-8a3.5 3.5 0 016-2 3.5 3.5 0 016 2c0 4-6 8-6 8z"),
                    //     label: "Health — steps",
                    //     sub: "Only for the \"Take a walk\" challenge",
                    //     right: AnyView(
                    //         StatusPill(
                    //             text: settings.healthPermission.displayText,
                    //             tone: settings.healthPermission == .granted ? .on : .warn
                    //         )
                    //     ),
                    //     last: true,
                    //     action: {
                    //         if settings.healthPermission == .granted {
                    //             showToast = ToastData(message: "Manage in iOS Settings → Health")
                    //         } else {
                    //             openAppSettings()
                    //         }
                    //     }
                    // )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Spacer()
                .frame(height: 12)
        }
        .onAppear {
            // Update permission statuses when view appears
            settings.updateAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Update permissions when returning from Settings
            settings.updateAllPermissions()
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func handleNotificationPermission() {
        switch settings.notificationPermission {
        case .granted:
            // Already granted - no action needed
            break

        case .notDetermined:
            // Not determined - request permission
            requestNotificationPermission()

        case .denied:
            // Denied - must go to settings to enable
            openAppSettings()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                // Update permission status
                settings.updateNotificationPermission()
            }
        }
    }
}
