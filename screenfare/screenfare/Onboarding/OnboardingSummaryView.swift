//
//  OnboardingSummaryView.swift
//  screenfare
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
                ScreenHeader(currentStep: 6, onBack: {})

                Spacer()
                    .frame(height: 28)

                // Title: fontSize: 36, lineHeight: 1.05, margin: 0 0 10px
                (Text("Ready when\n")
                    .font(.instrumentSerif(36))
                 + Text("you are.")
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

                Spacer()
                    .frame(height: 22)

                ScrollView {
                    VStack(spacing: 14) {
                        // Summary card
                        VStack(spacing: 0) {
                            SummaryRow(
                                label: "Apps blocked",
                                value: AnyView(
                                    HStack(spacing: 8) {
                                        AppFacepile(
                                            orderedAppTokens: Array(selectedApps.applicationTokens).sorted(by: { $0.hashValue < $1.hashValue }),
                                            orderedCategoryTokens: Array(selectedApps.categoryTokens).sorted(by: { $0.hashValue < $1.hashValue }),
                                            totalCount: appCount
                                        )
                                        Text("\(appCount)")
                                            .font(.inter(13))
                                            .foregroundColor(.focusMuted)
                                    }
                                )
                            )

                            SummaryRow(
                                label: "Challenge",
                                value: AnyView(
                                    Text("Math · \(difficultyLabel)")
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(.focusInk)
                                )
                            )

                            SummaryRow(
                                label: "Sample",
                                value: AnyView(
                                    Text(sampleProblem)
                                        .font(.instrumentSerif(17, italic: true))
                                        .foregroundColor(.focusInk)
                                )
                            )

                            SummaryRow(
                                label: "Access window",
                                value: AnyView(
                                    Text(durationFormatted)
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(.focusInk)
                                ),
                                isLast: true
                            )
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.focusLine, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.focusCard)
                                )
                        )

                        // How it works card: borderRadius: 18, padding: 20px 20px 22px
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOW IT WORKS")
                                .font(.inter(11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(11 * 0.12) // letterSpacing: 0.12em

                            VStack(spacing: 10) {
                                HowItWorksStep(number: 1, text: "Tap a blocked app → iOS shows the block screen")
                                HowItWorksStep(number: 2, text: "Focus sends a notification → tap it")
                                HowItWorksStep(number: 3, text: "Solve a \(difficultyLabel.lowercased()) math problem")
                                HowItWorksStep(number: 4, text: "App unlocks for \(durationFormatted)")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.focusInk)
                        )
                    }
                }

                Spacer()
                    .frame(height: 14)

                // Primary button
                PrimaryButton(title: "Activate Focus", action: onComplete)
                    .padding(.bottom, 34)
            }
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: AnyView
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.inter(13))
                .foregroundColor(.focusMuted)
                .padding(.top, 2)
                .frame(maxWidth: 100, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            value
                .frame(maxWidth: 200, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 16)
        .overlay(
            Rectangle()
                .fill(isLast ? Color.clear : Color.focusLine)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct HowItWorksStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 18, height: 18)

                Text("\(number)")
                    .font(.inter(11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 1)

            Text(text)
                .font(.inter(13.5))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
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
