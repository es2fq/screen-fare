//
//  HistoryManager.swift
//  Screen Fare
//
//  Tracks app interaction events for displaying in Recent activity
//

import Foundation
import SwiftUI
import Combine
import FamilyControls

struct HistoryEvent: Codable, Identifiable {
    let id: UUID
    let appTokenData: Data?  // Encoded ApplicationToken (optional for categories)
    let categoryTokenData: Data?  // Encoded ActivityCategoryToken (optional for apps)
    let timestamp: Date
    let eventType: EventType
    let duration: TimeInterval
    let challengeType: String? // e.g., "Math", "Typing", "Memory"

    enum EventType: String, Codable {
        case farePaid = "Fare paid"
        case walkedAway = "Walked away"
        case challengeStarted = "Challenge started"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case appTokenData
        case categoryTokenData
        case timestamp
        case eventType
        case duration
        case challengeType
    }

    // Helper computed property
    var isCategory: Bool {
        categoryTokenData != nil
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

    func recordEvent(appTokenData: Data? = nil, categoryTokenData: Data? = nil, eventType: HistoryEvent.EventType, duration: TimeInterval = 0, challengeType: String? = nil) {
        // Must have either app or category data
        guard (appTokenData != nil && !appTokenData!.isEmpty) || (categoryTokenData != nil && !categoryTokenData!.isEmpty) else { return }

        let event = HistoryEvent(
            id: UUID(),
            appTokenData: appTokenData,
            categoryTokenData: categoryTokenData,
            timestamp: Date(),
            eventType: eventType,
            duration: duration,
            challengeType: challengeType
        )

        recentEvents.insert(event, at: 0)

        // Keep only the most recent events
        if recentEvents.count > maxEvents {
            recentEvents = Array(recentEvents.prefix(maxEvents))
        }

        saveHistory()

        // Record stats - only count fares paid
        // Time spent will be tracked when the unlock expires or is manually ended
        if eventType == .farePaid {
            StatsManager.shared.recordChallengeSolved()
        }
    }

    func replaceChallengeStartedWithFarePaid(appTokenData: Data? = nil, categoryTokenData: Data? = nil, duration: TimeInterval, challengeType: String) {
        // Must have either app or category data
        guard (appTokenData != nil && !appTokenData!.isEmpty) || (categoryTokenData != nil && !categoryTokenData!.isEmpty) else { return }

        // Find and remove the most recent challengeStarted event for this app/category
        if let index = recentEvents.firstIndex(where: {
            $0.eventType == .challengeStarted &&
            (($0.appTokenData == appTokenData && appTokenData != nil) ||
             ($0.categoryTokenData == categoryTokenData && categoryTokenData != nil))
        }) {
            recentEvents.remove(at: index)
        }

        // Add farePaid event
        let event = HistoryEvent(
            id: UUID(),
            appTokenData: appTokenData,
            categoryTokenData: categoryTokenData,
            timestamp: Date(),
            eventType: .farePaid,
            duration: duration,
            challengeType: challengeType
        )

        recentEvents.insert(event, at: 0)

        // Keep only the most recent events
        if recentEvents.count > maxEvents {
            recentEvents = Array(recentEvents.prefix(maxEvents))
        }

        saveHistory()

        // Record stats
        StatsManager.shared.recordChallengeSolved()
    }

    func loadPendingEvents() {
        guard let sharedDefaults = UserDefaults.appGroup,
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

    // MARK: - History View Helpers

    /// Groups events by day for the history view
    func groupEventsByDay() -> [(day: String, date: String, events: [HistoryEvent])] {
        var groups: [(day: String, date: String, events: [HistoryEvent])] = []
        var currentDay: Date?
        var currentEvents: [HistoryEvent] = []

        // Sort events by date (newest first)
        let sortedEvents = recentEvents.sorted { $0.timestamp > $1.timestamp }

        for event in sortedEvents {
            let eventDay = event.timestamp.startOfDay()

            if let day = currentDay, day == eventDay {
                // Same day, add to current group
                currentEvents.append(event)
            } else {
                // New day, save previous group if it exists
                if let day = currentDay, !currentEvents.isEmpty {
                    groups.append((
                        day: day.dayLabel(),
                        date: day.shortDateLabel(),
                        events: currentEvents
                    ))
                }

                // Start new group
                currentDay = eventDay
                currentEvents = [event]
            }
        }

        // Add the last group
        if let day = currentDay, !currentEvents.isEmpty {
            groups.append((
                day: day.dayLabel(),
                date: day.shortDateLabel(),
                events: currentEvents
            ))
        }

        return groups
    }

    /// Calculates statistics for the history view (last 5 days)
    func weekStats() -> (walkedAway: Int, faresPaid: Int, walkAwayRate: Int) {
        let calendar = Calendar.current
        let now = Date()
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now) ?? now

        // Filter events from last 5 days
        let recentEvents = recentEvents.filter { $0.timestamp >= fiveDaysAgo }

        let walkedAwayCount = recentEvents.filter { $0.eventType == .walkedAway }.count
        let faresPaidCount = recentEvents.filter { $0.eventType == .farePaid }.count
        let totalCount = walkedAwayCount + faresPaidCount

        let walkAwayRate = totalCount > 0 ? Int(round(Double(walkedAwayCount) / Double(totalCount) * 100)) : 0

        return (walkedAway: walkedAwayCount, faresPaid: faresPaidCount, walkAwayRate: walkAwayRate)
    }
}
