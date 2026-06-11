//
//  UnlockHistoryManager.swift
//  screenfare
//
//  Tracks unlock events for displaying in Recent activity
//

import Foundation
import SwiftUI
import Combine
import FamilyControls

struct UnlockEvent: Codable, Identifiable {
    let id: UUID
    let appTokenData: Data  // Encoded ApplicationToken
    let timestamp: Date
    let unlockMethod: UnlockMethod
    let duration: TimeInterval

    enum UnlockMethod: String, Codable {
        case mathChallenge = "Math solved"
        case dismissed = "Block dismissed"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case appTokenData
        case timestamp
        case unlockMethod
        case duration
    }
}

@MainActor
class UnlockHistoryManager: ObservableObject {
    static let shared = UnlockHistoryManager()

    @Published private(set) var recentEvents: [UnlockEvent] = []

    private let maxEvents = 10
    private let storageKey = "com.screenfare.unlockHistory"

    private init() {
        loadHistory()
    }

    func recordUnlock(appTokenData: Data?, unlockMethod: UnlockEvent.UnlockMethod, duration: TimeInterval) {
        guard let appTokenData = appTokenData, !appTokenData.isEmpty else { return }

        let event = UnlockEvent(
            id: UUID(),
            appTokenData: appTokenData,
            timestamp: Date(),
            unlockMethod: unlockMethod,
            duration: duration
        )

        recentEvents.insert(event, at: 0)

        // Keep only the most recent events
        if recentEvents.count > maxEvents {
            recentEvents = Array(recentEvents.prefix(maxEvents))
        }

        saveHistory()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(recentEvents) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([UnlockEvent].self, from: data) else {
            return
        }
        recentEvents = decoded
    }
}
