//
//  TodayView.swift
//  screenfare
//
//  Main "Today" tab showing current status and stats
//

import SwiftUI
import FamilyControls
import Combine

struct TodayView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        AppScreen(title: "Today") {
            VStack(spacing: 18) {
                // Status card
                StatusCard()

                // Stats card
                StatsCard()

                // Blocked apps section
                if hasBlockedApps {
                    VStack(spacing: 12) {
                        SectionTitle(text: "Blocked apps")

                        AppCard {
                            VStack(spacing: 14) {
                                ForEach(Array(blockingManager.selectedApps.applicationTokens.prefix(5)).indices, id: \.self) { index in
                                    let tokens = Array(blockingManager.selectedApps.applicationTokens.prefix(5))
                                    let token = tokens[index]

                                    HStack(spacing: 12) {
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .frame(width: 44, height: 44)
                                            .background(Color.focusCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 11))

                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(.focusInk)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.focusMuted)
                                    }
                                    .padding(.vertical, 4)

                                    if index < tokens.count - 1 {
                                        Divider()
                                            .background(Color.focusLine)
                                    }
                                }
                            }
                        }
                    }
                }

                // Recent activity
                VStack(spacing: 12) {
                    SectionTitle(text: "Recent activity")

                    AppCard {
                        VStack(spacing: 14) {
                            ActivityRow(
                                time: "Today 2:14 PM",
                                action: "Unlocked Instagram",
                                duration: "15 min access"
                            )

                            Divider().background(Color.focusLine)

                            ActivityRow(
                                time: "Today 11:32 AM",
                                action: "Unlocked Twitter",
                                duration: "5 min access"
                            )
                        }
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var hasBlockedApps: Bool {
        !blockingManager.selectedApps.applicationTokens.isEmpty
    }
}

/// Status card showing current blocking status
struct StatusCard: View {
    @StateObject private var blockingManager = AppBlockingManager.shared

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(blockingManager.isBlocking ? Color.focusAccent.opacity(0.15) : Color.focusInk.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: blockingManager.isBlocking ? "checkmark.shield.fill" : "shield")
                        .font(.system(size: 18))
                        .foregroundColor(blockingManager.isBlocking ? Color.focusAccent : .focusInk.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(blockingManager.isBlocking ? "Active" : "Paused")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(.focusInk)

                    Text(blockingManager.isBlocking ? "Apps are blocked" : "Tap to activate blocking")
                        .font(.inter(13.5))
                        .foregroundColor(.focusMuted)
                }

                Spacer()

                // Toggle button
                Button(action: {
                    if blockingManager.isBlocking {
                        blockingManager.removeBlocking()
                    } else {
                        blockingManager.applyBlocking()
                    }
                }) {
                    Text(blockingManager.isBlocking ? "Pause" : "Start")
                        .font(.inter(13, weight: .semibold))
                        .foregroundColor(blockingManager.isBlocking ? .focusInk : .focusAccentInk)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(blockingManager.isBlocking ? Color.focusInk.opacity(0.06) : Color.focusAccent)
                        )
                }
            }
        }
    }
}

/// Stats card showing usage statistics
struct StatsCard: View {
    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    StatItem(value: "12", label: "Challenges\ncompleted", isFirst: true)
                    StatItem(value: "3h", label: "Time\nsaved")
                    StatItem(value: "87%", label: "Success\nrate", isLast: true)
                }
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    var isFirst: Bool = false
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            // fontSize: 26px for stats
            Text(value)
                .font(.instrumentSerif(26))
                .foregroundColor(.focusInk)
                .monospacedDigit()

            // fontSize: 12px for labels
            Text(label)
                .font(.inter(12))
                .foregroundColor(.focusMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, isFirst ? 0 : 8)
        .padding(.trailing, isLast ? 0 : 8)
        .overlay(alignment: .trailing) {
            if !isLast {
                Rectangle()
                    .fill(Color.focusLine)
                    .frame(width: 1)
                    .padding(.vertical, 4)
            }
        }
    }
}

struct ActivityRow: View {
    let time: String
    let action: String
    let duration: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // fontSize: 15px
                Text(action)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(.focusInk)

                // fontSize: 12px
                Text(time)
                    .font(.inter(12))
                    .foregroundColor(.focusMuted)
            }

            Spacer()

            // fontSize: 13px
            Text(duration)
                .font(.inter(13))
                .foregroundColor(.focusMuted)
        }
    }
}

#Preview {
    TodayView()
}
