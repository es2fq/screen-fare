//
//  TodayView.swift
//  screenfare
//
//  Main "Today" tab - pixel-perfect implementation from handoff
//  Design specs: app.jsx → HomeScreen (lines 149-273)
//

import SwiftUI
import FamilyControls
import ManagedSettings
import Combine

struct TodayView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var historyManager = UnlockHistoryManager.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header with title and date
                HStack(alignment: .bottom) {
                    (Text("Today")
                        .font(.instrumentSerif(36))
                     + Text(".")
                        .font(.instrumentSerif(36, italic: true))
                        .foregroundColor(.focusMuted))
                    .foregroundColor(.focusInk)

                    Spacer()

                    Text(formattedDate)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView {
            VStack(spacing: 0) {
                // Status hero card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(blockingManager.isBlocking ? Color.focusInk : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(blockingManager.isBlocking ? Color.clear : Color.focusLine, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 0) {
                        // Top row: "Focus is on/off" + Toggle
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Focus is")
                                    .font(.inter(11))
                                    .foregroundColor(blockingManager.isBlocking ? Color.white.opacity(0.6) : Color.focusInk.opacity(0.5))
                                    .tracking(1.2)
                                    .textCase(.uppercase)

                                if blockingManager.isBlocking {
                                    (Text("on")
                                        .font(.instrumentSerif(44))
                                     + Text(".")
                                        .font(.instrumentSerif(44, italic: true)))
                                        .foregroundColor(.white)
                                } else {
                                    Text("off")
                                        .font(.instrumentSerif(44, italic: true))
                                        .foregroundColor(.focusInk)
                                }
                            }

                            Spacer()

                            // Toggle switch
                            Toggle("", isOn: Binding(
                                get: { blockingManager.isBlocking },
                                set: { newValue in
                                    if newValue {
                                        blockingManager.applyBlocking()
                                    } else {
                                        blockingManager.removeBlocking()
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(blockingManager.isBlocking ? Color.white.opacity(0.3) : .focusInk)
                            .scaleEffect(1.1) // Make it slightly larger when off for better visibility
                            .animation(.easeInOut(duration: 0.2), value: blockingManager.isBlocking)
                        }

                        // Stats row
                        HStack(spacing: 0) {
                            StatPill(value: "12", label: "Blocks today", textColor: blockingManager.isBlocking ? .white : .focusInk)
                            StatPill(value: "8", label: "Solved", textColor: blockingManager.isBlocking ? .white : .focusInk)
                            StatPill(value: "47m", label: "Time saved", textColor: blockingManager.isBlocking ? .white : .focusInk)
                        }
                        .padding(.top, 22)
                        .overlay(
                            Rectangle()
                                .fill(blockingManager.isBlocking ? Color.white.opacity(0.12) : Color.focusLine)
                                .frame(height: 1),
                            alignment: .top
                        )
                    }
                    .padding(22)
                    .padding(.bottom, 2)
                }

                // Active rule section
                SectionHeader(title: "Active rule")
                    .padding(.top, 22)

                AppCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.focusInk.opacity(0.06))
                                .frame(width: 36, height: 36)

                            Image(systemName: "number")
                                .font(.system(size: 18))
                                .foregroundColor(.focusInk)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Math · \(difficultyText)")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Text("Unlock for \(settings.unlockDurationText) after solving")
                                .font(.inter(12.5))
                                .foregroundColor(.focusMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.focusMuted)
                    }
                    .padding(.vertical, 14)
                }

                // Temporary access section - show unlocked apps with countdown
                if !blockingManager.temporaryUnlocks.isEmpty {
                    SectionHeader(title: "Temporary access")
                        .padding(.top, 22)

                    AppCard {
                        VStack(spacing: 0) {
                            ForEach(Array(blockingManager.temporaryUnlocks.sorted(by: { $0.value < $1.value }).enumerated()), id: \.element.key) { index, unlock in
                                if index > 0 {
                                    Divider()
                                        .background(Color.focusLine)
                                        .padding(.vertical, 14)
                                }

                                if let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: unlock.key) {
                                    TemporaryUnlockRow(
                                        app: appToken,
                                        expiryTime: unlock.value,
                                        currentTime: currentTime
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Recent activity section
                SectionHeader(title: "Recent")
                    .padding(.top, 22)

                AppCard {
                    if historyManager.recentEvents.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Text("Your recent activity will appear here")
                                .font(.inter(13))
                                .foregroundColor(.focusMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(historyManager.recentEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                                if index > 0 {
                                    Divider()
                                        .background(Color.focusLine)
                                        .padding(.vertical, 14)
                                }

                                RecentActivityRow(
                                    app: try? JSONDecoder().decode(ApplicationToken.self, from: event.appTokenData),
                                    action: event.unlockMethod.rawValue,
                                    time: formatTime(event.timestamp)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 22)
                }
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            // Clean up any expired unlocks when user views Today tab
            blockingManager.cleanupExpiredUnlocks()
        }
    }

    private var difficultyText: String {
        switch settings.challengeDifficulty {
        case .veryEasy: return "Very Easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: currentTime)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

/// Section header with optional action button
struct SectionHeader: View {
    let title: String
    var action: String? = nil

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(.inter(11, weight: .semibold))
                .foregroundColor(.focusMuted)
                .tracking(0.6)
                .textCase(.uppercase)

            Spacer()

            if let action = action {
                Button(action: {}) {
                    Text(action)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 10)
    }
}

/// Stat item for the status card
struct StatPill: View {
    let value: String
    let label: String
    let textColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.instrumentSerif(26))
                .foregroundColor(textColor)
                .monospacedDigit()

            Text(label)
                .font(.inter(11))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Recent activity row
struct RecentActivityRow: View {
    let app: ApplicationToken?
    let action: String
    let time: String

    var body: some View {
        HStack(spacing: 14) {
            if let app = app {
                Label(app)
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            } else {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.focusInk.opacity(0.06))
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let app = app {
                    Label(app)
                        .labelStyle(.titleOnly)
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(.focusInk)
                } else {
                    Text("App")
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(.focusInk)
                }

                Text(action)
                    .font(.inter(12.5))
                    .foregroundColor(.focusMuted)
            }

            Spacer()

            Text(time)
                .font(.inter(12))
                .foregroundColor(.focusMuted)
                .monospacedDigit()
        }
    }
}

/// Temporary unlock row showing app with countdown timer
struct TemporaryUnlockRow: View {
    let app: ApplicationToken
    let expiryTime: Date
    let currentTime: Date

    var body: some View {
        HStack(spacing: 14) {
            Label(app)
                .labelStyle(.iconOnly)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Label(app)
                    .labelStyle(.titleOnly)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(.focusInk)

                Text(formatCountdown(expiryTime: expiryTime, currentTime: currentTime))
                    .font(.inter(12.5))
                    .foregroundColor(.focusMuted)
            }

            Spacer()

            Text(formatRemainingTime(expiryTime: expiryTime, currentTime: currentTime))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.focusAccent)
        }
    }

    private func formatCountdown(expiryTime: Date, currentTime: Date) -> String {
        let remaining = max(0, expiryTime.timeIntervalSince(currentTime))
        if remaining < 60 {
            return "Expires in less than 1 min"
        } else {
            let minutes = Int(remaining / 60)
            return "Expires in \(minutes) min"
        }
    }

    private func formatRemainingTime(expiryTime: Date, currentTime: Date) -> String {
        let remaining = max(0, expiryTime.timeIntervalSince(currentTime))
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Flow layout for wrapping app chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    TodayView()
}
