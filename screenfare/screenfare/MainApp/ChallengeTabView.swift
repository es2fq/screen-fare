//
//  ChallengeTabView.swift
//  screenfare
//
//  Configure challenge type, difficulty, and access window
//

import SwiftUI

struct ChallengeTabView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var previewChallenges: [ChallengeDifficulty: MathChallenge]
    @State private var currentChallenge: MathChallenge

    init() {
        let settings = SettingsManager.shared

        // Pre-generate one challenge for each difficulty level
        var challenges: [ChallengeDifficulty: MathChallenge] = [:]
        for difficulty in ChallengeDifficulty.allCases {
            challenges[difficulty] = MathChallenge(difficulty: difficulty)
        }
        self._previewChallenges = State(initialValue: challenges)
        self._currentChallenge = State(initialValue: challenges[settings.challengeDifficulty] ?? MathChallenge(difficulty: settings.challengeDifficulty))
    }

    var body: some View {
        AppScreen(title: "Challenge") {
            VStack(spacing: 18) {
                // Preview card (dark): borderRadius: 18, padding: 24px 22px, gap: 18px
                VStack(spacing: 18) {
                    // Preview label: fontSize: 11, opacity: 0.5, letterSpacing: 0.12em
                    Text("PREVIEW")
                        .font(.inter(11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(11 * 0.12) // letterSpacing: 0.12em = 1.32px at 11px

                    // Math question: fontSize: 44, lineHeight: 1
                    Text(currentChallenge.questionText)
                        .font(.instrumentSerif(44))
                        .foregroundColor(.white)
                        .lineSpacing(0) // lineHeight 1 = no extra spacing
                        .monospacedDigit()

                    // Mock input field
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(height: 52)
                        .overlay(
                            HStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 4, height: 4)
                                }
                            }
                        )
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.focusInk)
                )
                .onChange(of: settings.challengeDifficulty) { _, newDifficulty in
                    // Update the current challenge when difficulty changes
                    if let challenge = previewChallenges[newDifficulty] {
                        currentChallenge = challenge
                        print("DEBUG: Difficulty changed to \(newDifficulty), question: \(challenge.questionText)")
                    }
                }

                // Difficulty section
                SectionTitle(text: "Difficulty")

                AppCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Difficulty")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Spacer()

                            Text(difficultyLabel(for: settings.challengeDifficulty))
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.focusInk)
                        }

                        // Difficulty slider
                        Slider(
                            value: Binding(
                                get: { Double(ChallengeDifficulty.allCases.firstIndex(of: settings.challengeDifficulty) ?? 2) },
                                set: { settings.challengeDifficulty = ChallengeDifficulty.allCases[Int($0)] }
                            ),
                            in: 0...4,
                            step: 1
                        )
                        .tint(Color.focusInk)
                    }
                }

                // Access window section
                SectionTitle(text: "Access window")

                AppCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Duration")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Spacer()

                            Text(durationFormatted)
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.focusInk)
                                .monospacedDigit()
                        }

                        // Duration slider
                        VStack(spacing: 6) {
                            Slider(
                                value: $settings.unlockDuration,
                                in: 60...7200,
                                step: 60
                            )
                            .tint(Color.focusInk)

                            HStack {
                                Text("1 min")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                                Spacer()
                                Text("2 hours")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                            }
                        }

                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([2, 5, 15, 30, 60], id: \.self) { preset in
                                let isSelected = Int(settings.unlockDuration / 60) == preset
                                Button(action: {
                                    settings.unlockDuration = TimeInterval(preset * 60)
                                }) {
                                    Text(preset < 60 ? "\(preset)m" : "\(preset/60)h")
                                        .font(.inter(13, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .focusInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.focusInk : Color.focusLine, lineWidth: 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(isSelected ? Color.focusInk : Color.focusCard)
                                                )
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func difficultyLabel(for difficulty: ChallengeDifficulty) -> String {
        switch difficulty {
        case .veryEasy: return "Very easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very hard"
        }
    }

    private var durationFormatted: String {
        let minutes = Int(settings.unlockDuration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hours"
        }
    }
}

#Preview {
    ChallengeTabView()
}
