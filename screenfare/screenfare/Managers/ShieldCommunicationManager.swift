//
//  ShieldCommunicationManager.swift
//  screenfare
//
//  Handles communication between Shield extensions and main app
//  Checks for unlock requests when app becomes active
//

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class ShieldCommunicationManager: ObservableObject {
    static let shared = ShieldCommunicationManager()

    @Published var shouldShowChallenge = false

    private init() {
        // Observe app lifecycle to check for unlock requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Check immediately on init
        checkForUnlockRequest()
    }

    @objc private func appDidBecomeActive() {
        checkForUnlockRequest()
    }

    @objc private func appWillEnterForeground() {
        checkForUnlockRequest()
    }

    func checkForUnlockRequest() {
        // If apps are currently blocked, show challenge when app opens
        let appBlockingManager = AppBlockingManager.shared
        if appBlockingManager.isBlocking {
            shouldShowChallenge = true
        }
    }
}
