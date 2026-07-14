//
//  PermissionsDetailView.swift
//  Screen Fare
//
//  Permissions settings detail screen
//

import SwiftUI
import UserNotifications
import CoreMotion

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
                        action: {
                            handleNotificationPermission()
                        }
                    )

                    SettingsRow(
                        icon: SettIcon(path: "M12 2L8 8h3v6h2V8h3l-4-6zm-6 16h12v2H6v-2z"),
                        label: "Motion & Fitness",
                        sub: "Required for walking challenge",
                        right: AnyView(
                            StatusPill(
                                text: settings.motionPermission.displayText,
                                tone: settings.motionPermission == .granted ? .on : .warn
                            )
                        ),
                        last: true,
                        action: {
                            handleMotionPermission()
                        }
                    )
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

    private func handleMotionPermission() {
        // Check if step counting is available
        guard CMPedometer.isStepCountingAvailable() else {
            showToast = ToastData(message: "Motion tracking not available on this device")
            return
        }

        switch settings.motionPermission {
        case .granted:
            // Already granted - show message
            showToast = ToastData(message: "Motion permission already granted")

        case .notDetermined:
            // Request permission by starting the pedometer (this triggers the permission dialog)
            requestMotionPermission()

        case .denied:
            // Denied - must go to settings to enable
            openAppSettings()
        }
    }

    private func requestMotionPermission() {
        // Start and immediately stop pedometer to trigger permission prompt
        let pedometer = CMPedometer()
        pedometer.startUpdates(from: Date()) { _, _ in
            // Stop immediately - we just wanted to trigger the permission
            pedometer.stopUpdates()

            // Update permission status after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                settings.updateMotionPermission()
            }
        }
    }
}
