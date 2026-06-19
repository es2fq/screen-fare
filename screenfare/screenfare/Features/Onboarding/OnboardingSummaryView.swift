//
//  OnboardingSummaryView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingSummaryView: View {
    let selectedApps: FamilyActivitySelection
    let difficulty: ChallengeDifficulty
    let duration: TimeInterval
    let onComplete: () -> Void

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    private var durationMinutes: Int {
        Int(duration / 60)
    }

    private var durationFormatted: String {
        if durationMinutes < 60 {
            return "\(durationMinutes) minutes"
        } else if durationMinutes == 60 {
            return "1 hour"
        } else {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hours"
        }
    }

    private var difficultyLabel: String {
        switch difficulty {
        case .veryEasy: return "Very easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very hard"
        }
    }

    private var sampleProblem: String {
        let challenge = MathChallenge(difficulty: difficulty)
        return challenge.questionText
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 28)

                // Title: fontSize: 36, lineHeight: 1.05, margin: 0 0 10px
                (Text("Ready when")
                    .font(.instrumentSerif(36))
                 + Text(" you are.")
                    .font(.instrumentSerif(36, italic: true)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(36 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 15, margin: 0 0 22px
                Text("Review your setup. Nothing changes until you tap activate.")
                    .font(.inter(15))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // "Your setup" section label
                        SectionLabel(text: "Your setup")
                            .padding(.top, 22)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 4)

                        // Summary card with icon-led rows
                        VStack(spacing: 0) {
                            SummaryIconRow(
                                icon: SUM_ICONS.blocks,
                                label: "\(appCount) \(appCount == 1 ? "app" : "apps") blocked",
                                sub: "Pay a fare to open",
                                right: AnyView(
                                    HStack(spacing: 0) {
                                        // Facepile of icons (max 3)
                                        ForEach(Array(selectedApps.categoryTokens.prefix(3)).sorted(by: { $0.hashValue < $1.hashValue }), id: \.self) { token in
                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(1.2)
                                                .frame(width: 26, height: 26)
                                                .background(Color.focusCard)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.focusCard, lineWidth: 1.5)
                                                )
                                                .padding(.leading, token == selectedApps.categoryTokens.sorted(by: { $0.hashValue < $1.hashValue }).first ? 0 : -7)
                                        }

                                        ForEach(Array(selectedApps.applicationTokens.prefix(max(0, 3 - selectedApps.categoryTokens.count))).sorted(by: { $0.hashValue < $1.hashValue }), id: \.self) { token in
                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(1.2)
                                                .frame(width: 26, height: 26)
                                                .background(Color.focusCard)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.focusCard, lineWidth: 1.5)
                                                )
                                                .padding(.leading, -7)
                                        }

                                        if appCount > 3 {
                                            Text("+\(appCount - 3)")
                                                .font(.inter(13))
                                                .foregroundColor(.focusMuted)
                                                .padding(.leading, 7)
                                        }
                                    }
                                )
                            )

                            SummaryIconRow(
                                icon: SUM_ICONS.math,
                                label: "Math · \(difficultyLabel)",
                                sub: {
                                    let challenge = MathChallenge(difficulty: difficulty)
                                    return "Sample: \(challenge.questionText)"
                                }()
                            )

                            SummaryIconRow(
                                icon: SUM_ICONS.clock,
                                label: "Unlocks for \(durationFormatted)",
                                sub: "Then re-locks automatically",
                                isLast: true
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.focusLine, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.focusCard)
                                )
                        )

                        // "How it works" section label
                        SectionLabel(text: "How it works")
                            .padding(.top, 22)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 4)

                        // How it works card
                        VStack(spacing: 13) {
                            HowItWorksStep(number: 1, text: "Tap a blocked app — iOS shows the block screen")
                            HowItWorksStep(number: 2, text: "Screen Fare sends a notification — tap it")
                            HowItWorksStep(number: 3, text: "Solve a \(difficultyLabel.lowercased()) math problem")
                            HowItWorksStep(number: 4, text: "The app unlocks for \(durationFormatted)")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.focusInk)
                        )

                        Spacer()
                            .frame(height: 4)
                    }
                }

                Spacer()
                    .frame(height: 14)

                // Primary button
                PrimaryButton(title: "Activate Screen Fare", action: onComplete)
                    .padding(.bottom, 34)
            }
        }
    }
}

// MARK: - Section Label Component

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.inter(11, weight: .semibold))
            .foregroundColor(.focusMuted)
            .tracking(11 * 0.06) // letterSpacing: 0.6em = 6% of font size
    }
}

// MARK: - Summary Icon Row Component

struct SummaryIconRow: View {
    let icon: AnyView
    let label: String
    var sub: String?
    var right: AnyView?
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon container: 36x36 rounded square with subtle background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.focusInk.opacity(0.06))
                    .frame(width: 36, height: 36)

                icon
            }
            .frame(width: 36, height: 36)

            // Label and sublabel
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(.focusInk)
                    .lineSpacing(15 * 0.2) // lineHeight 1.2

                if let sub = sub {
                    Text(sub)
                        .font(.inter(12.5))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(12.5 * 0.3) // lineHeight 1.3
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right content (optional)
            if let right = right {
                right
            }
        }
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .fill(isLast ? Color.clear : Color.focusLine)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Summary Icons (using SF Symbols for consistency with main app)

struct SUM_ICONS {
    // Blocks icon - uses same SF Symbol as Blocks tab in MainTabView
    static let blocks = AnyView(
        Image(systemName: "shield")
            .font(.system(size: 18))
            .foregroundColor(.focusInk)
    )

    // Math icon - uses same SF Symbol as TodayView challenge type
    static let math = AnyView(
        Image(systemName: "plus.forwardslash.minus")
            .font(.system(size: 18))
            .foregroundColor(.focusInk)
    )

    // Clock icon - uses same SF Symbol as main app
    static let clock = AnyView(
        Image(systemName: "clock")
            .font(.system(size: 18))
            .foregroundColor(.focusInk)
    )
}

struct HowItWorksStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 22, height: 22)

                Text("\(number)")
                    .font(.inter(11, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.inter(13.5))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(13.5 * 0.4) // lineHeight 1.4
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingSummaryView(
        selectedApps: FamilyActivitySelection(),
        difficulty: .medium,
        duration: 300,
        onComplete: {}
    )
}
