//
//  HistoryManager.swift
//  screenfare
//
//  Tracks app interaction events for displaying in Recent activity
//

import Foundation
import SwiftUI
import Combine
import FamilyControls

struct HistoryEvent: Codable, Identifiable {
    let id: UUID
    let appTokenData: Data  // Encoded ApplicationToken
    let timestamp: Date
    let eventType: EventType
    let duration: TimeInterval

    enum EventType: String, Codable {
        case mathChallenge = "Unlocked · math solved"
        case dismissed = "Block dismissed"
        case blocked = "App blocked"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case appTokenData
        case timestamp
        case eventType
        case duration
    }
}

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published private(set) var recentEvents: [HistoryEvent] = []

    private let maxEvents = 10
    private let storageKey = "com.screenfare.history"
    private let sharedStorageKey = "com.screenfare.pendingHistoryEvents"

    private init() {
        loadHistory()
    }

    func recordEvent(appTokenData: Data?, eventType: HistoryEvent.EventType, duration: TimeInterval = 0) {
        guard let appTokenData = appTokenData, !appTokenData.isEmpty else { return }

        let event = HistoryEvent(
            id: UUID(),
            appTokenData: appTokenData,
            timestamp: Date(),
            eventType: eventType,
            duration: duration
        )

        recentEvents.insert(event, at: 0)

        // Keep only the most recent events
        if recentEvents.count > maxEvents {
            recentEvents = Array(recentEvents.prefix(maxEvents))
        }

        saveHistory()

        // Record stats - only count fares paid for math challenges
        // Time spent will be tracked when the unlock expires or is manually ended
        if eventType == .mathChallenge {
            StatsManager.shared.recordChallengeSolved()
        }
    }

    func loadPendingEvents() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
              let data = sharedDefaults.data(forKey: sharedStorageKey),
              let pendingEvents = try? JSONDecoder().decode([HistoryEvent].self, from: data),
              !pendingEvents.isEmpty else {
            return
        }

        // Add all pending events
        for event in pendingEvents.reversed() {
            recentEvents.insert(event, at: 0)
        }

        // Keep only the most recent events
        if recentEvents.count > maxEvents {
            recentEvents = Array(recentEvents.prefix(maxEvents))
        }

        saveHistory()

        // Clear pending events from shared storage
        sharedDefaults.removeObject(forKey: sharedStorageKey)
        sharedDefaults.synchronize()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(recentEvents) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryEvent].self, from: data) else {
            return
        }
        recentEvents = decoded
    }
}
