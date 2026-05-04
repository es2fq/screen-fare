//
//  OnboardingDifficultyView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingDifficultyView: View {
    @Binding var selectedDifficulty: ChallengeDifficulty
    @State private var previewChallenge: MathChallenge
    let onContinue: () -> Void

    init(selectedDifficulty: Binding<ChallengeDifficulty>, onContinue: @escaping () -> Void) {
        self._selectedDifficulty = selectedDifficulty
        self.onContinue = onContinue
        self._previewChallenge = State(initialValue: MathChallenge(difficulty: selectedDifficulty.wrappedValue))
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 4, onBack: {})

                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05
                (Text("The ")
                    .font(.instrumentSerif(32))
                 + Text("pause")
                    .font(.instrumentSerif(32, italic: true))
                 + Text("\nbefore you scroll.")
                    .font(.instrumentSerif(32)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 14.5
                Text("Solve a math problem to unlock a blocked app. Pick a difficulty.")
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
                    Text(previewChallenge.questionText)
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
                    HStack {
                        Text("Difficulty")
                            .font(.inter(13))
                            .foregroundColor(.focusMuted)
                        Spacer()
                        Text(difficultyLabel(for: selectedDifficulty))
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(.focusInk)
                    }

                    // Custom slider
                    CustomDifficultySlider(selectedDifficulty: $selectedDifficulty) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            previewChallenge = MathChallenge(difficulty: selectedDifficulty)
                        }
                    }
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

struct CustomDifficultySlider: View {
    @Binding var selectedDifficulty: ChallengeDifficulty
    let onChange: () -> Void

    @State private var sliderValue: Double = 2 // Start at medium (index 2)

    private let difficulties = ChallengeDifficulty.allCases

    init(selectedDifficulty: Binding<ChallengeDifficulty>, onChange: @escaping () -> Void) {
        self._selectedDifficulty = selectedDifficulty
        self.onChange = onChange
        let index = ChallengeDifficulty.allCases.firstIndex(of: selectedDifficulty.wrappedValue) ?? 2
        self._sliderValue = State(initialValue: Double(index))
    }

    var body: some View {
        VStack(spacing: 10) {
            // Slider
            Slider(
                value: $sliderValue,
                in: 0...4,
                step: 1
            )
            .tint(Color.focusInk)
            .onChange(of: sliderValue) { newValue in
                selectedDifficulty = difficulties[Int(newValue)]
                onChange()
            }

            // Tick marks
            HStack {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= Int(sliderValue) ? Color.focusInk : Color.focusInk.opacity(0.2))
                        .frame(width: 4, height: 4)
                        .frame(maxWidth: .infinity)
                }
            }

            // Labels
            HStack {
                Text("Very easy")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("Very hard")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
            }
        }
    }
}

#Preview {
    OnboardingDifficultyView(selectedDifficulty: .constant(.medium), onContinue: {})
}
