//
//  DarwinNotificationManager.swift
//  Screen Fare
//
//  Handles Darwin Notifications for cross-process communication
//  Used by ShieldActionExtension to trigger challenge in main app
//

import Foundation
import Combine

@MainActor
class DarwinNotificationManager: ObservableObject {
    static let shared = DarwinNotificationManager()

    @Published var shouldShowChallenge = false

    private let notificationName = "com.screenfare.unlockChallenge" as CFString

    private init() {
        setupDarwinNotificationObserver()
    }

    private func setupDarwinNotificationObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        CFNotificationCenterAddObserver(
            center,
            observer,
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()

                Task { @MainActor in
                    manager.shouldShowChallenge = true
                }
            },
            notificationName,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }
}
