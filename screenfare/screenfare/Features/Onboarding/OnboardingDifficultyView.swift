//
//  OnboardingDifficultyView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingDifficultyView: View {
    @Binding var selectedDifficulty: ChallengeDifficulty
    @State private var previewChallenges: [ChallengeDifficulty: MathChallenge]
    let onContinue: () -> Void

    init(selectedDifficulty: Binding<ChallengeDifficulty>, onContinue: @escaping () -> Void) {
        self._selectedDifficulty = selectedDifficulty
        self.onContinue = onContinue

        // Pre-generate one challenge for each difficulty level
        var challenges: [ChallengeDifficulty: MathChallenge] = [:]
        for difficulty in ChallengeDifficulty.allCases {
            challenges[difficulty] = MathChallenge(difficulty: difficulty)
        }
        self._previewChallenges = State(initialValue: challenges)
    }

    private var currentChallenge: MathChallenge {
        previewChallenges[selectedDifficulty] ?? MathChallenge(difficulty: selectedDifficulty)
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05
                (Text("The ")
                    .font(.instrumentSerif(32))
                 + Text("fare")
                    .font(.instrumentSerif(32, italic: true))
                 + Text("\nbefore you scroll.")
                    .font(.instrumentSerif(32)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 14.5
                Text("Solve a math problem to unlock a blocked app. You may change this later.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 22)

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

                Spacer()
                    .frame(height: 22)

                // Difficulty slider card
                VStack(spacing: 14) {
                    HStack(alignment: .center) {
                        Text("Difficulty")
                            .font(.inter(13))
                            .foregroundColor(.focusMuted)
                        Spacer()
                        Text(difficultyLabel(for: selectedDifficulty))
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(.focusInk)
                    }

                    // Custom slider
                    CustomSlider(
                        value: Binding(
                            get: { Double(ChallengeDifficulty.allCases.firstIndex(of: selectedDifficulty) ?? 2) },
                            set: { selectedDifficulty = ChallengeDifficulty.allCases[Int($0)] }
                        ),
                        range: 0...4,
                        step: 1
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.focusLine, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.focusCard)
                        )
                )

                Spacer()

                // Primary button
                PrimaryButton(title: "Continue", action: onContinue)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
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
}

#Preview {
    OnboardingDifficultyView(selectedDifficulty: .constant(.medium), onContinue: {})
}
