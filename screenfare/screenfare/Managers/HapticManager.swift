//
//  HapticManager.swift
//  screenfare
//
//  Created by Claude on 2026-06-28.
//

import UIKit

/// Manages haptic feedback throughout the app
class HapticManager {
    static let shared = HapticManager()

    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)

    private init() {
        // Prepare the generator to reduce latency
        lightImpactGenerator.prepare()
    }

    /// Triggers a light impact haptic feedback
    func impact() {
        lightImpactGenerator.impactOccurred()
        // Prepare for next use
        lightImpactGenerator.prepare()
    }
}
