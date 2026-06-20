//
//  HistoryView.swift
//  Screen Fare
//
//  Full history view showing all recent activity grouped by day
//  Design specs: app.jsx → HistoryPanel (lines 180-262)
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack(spacing: 0) {
                    Button(action: onClose) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Today")
                                .font(.inter(15))
                        }
                        .foregroundColor(.focusInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // Title
                HStack {
                    Text("History")
                        .font(.instrumentSerif(34))
                        .foregroundColor(.focusInk)

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
                .padding(.bottom, 12)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Week summary card
                        weekSummaryCard
                            .padding(.horizontal, 22)

                        // Day groups
                        dayGroupsList
                            .padding(.horizontal, 22)

                        Spacer().frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Week Summary Card

    private var weekSummaryCard: some View {
        let stats = historyManager.weekStats()

        return AppCard(padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)) {
            HStack(spacing: 0) {
                // Walked away
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(stats.walkedAway)")
                        .font(.instrumentSerif(30))
                        .foregroundColor(.focusAccent)

                    Text("Walked away")
                        .font(.inter(10.5))
                        .foregroundColor(.focusMuted)
                        .tracking(0.02)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Fares paid
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(stats.faresPaid)")
                        .font(.instrumentSerif(30))
                        .foregroundColor(.focusInk)

                    Text("Fares paid")
                        .font(.inter(10.5))
                        .foregroundColor(.focusMuted)
                        .tracking(0.02)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Walk-away rate
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(stats.walkAwayRate)%")
                        .font(.instrumentSerif(30))
                        .foregroundColor(.focusInk)
                        .monospacedDigit()

                    Text("Walk-away rate")
                        .font(.inter(10.5))
                        .foregroundColor(.focusMuted)
                        .tracking(0.02)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
    }

    // MARK: - Day Groups List

    private var dayGroupsList: some View {
        let groups = historyManager.groupEventsByDay()

        return ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
            VStack(alignment: .leading, spacing: 0) {
                // Day header
                HStack(alignment: .lastTextBaseline) {
                    HStack(alignment: .lastTextBaseline, spacing: 7) {
                        Text(group.day)
                            .font(.inter(14, weight: .semibold))
                            .foregroundColor(.focusInk)

                        Text(group.date)
                            .font(.inter(11.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()

                    // Day stats
                    dayStats(for: group.events)
                }
                .padding(.horizontal, 4)
                .padding(.top, 22)
                .padding(.bottom, 10)

                // Events card
                AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                    VStack(spacing: 0) {
                        ForEach(Array(group.events.enumerated()), id: \.element.id) { eventIndex, event in
                            VStack(spacing: 0) {
                                RecentActivityRow(
                                    app: event.appTokenData.flatMap { try? JSONDecoder().decode(ApplicationToken.self, from: $0) },
                                    category: event.categoryTokenData.flatMap { try? JSONDecoder().decode(ActivityCategoryToken.self, from: $0) },
                                    action: event.eventType.rawValue,
                                    time: formatTime(event.timestamp),
                                    challengeType: event.challengeType,
                                    duration: event.duration
                                )

                                if eventIndex < group.events.count - 1 {
                                    Divider()
                                        .background(Color.focusLine)
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Day Stats Helper

    private func dayStats(for events: [HistoryEvent]) -> some View {
        let walkedCount = events.filter { $0.eventType == .walkedAway }.count
        let paidCount = events.filter { $0.eventType == .farePaid }.count

        return HStack(spacing: 0) {
            if walkedCount > 0 {
                Text("\(walkedCount) walked")
                    .font(.inter(11))
                    .foregroundColor(.focusAccent)
                    .monospacedDigit()

                if paidCount > 0 {
                    Text(" · ")
                        .font(.inter(11))
                        .foregroundColor(.focusMuted)
                        .monospacedDigit()
                }
            }

            if paidCount > 0 {
                Text("\(paidCount) paid")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    HistoryView(onClose: {})
}
