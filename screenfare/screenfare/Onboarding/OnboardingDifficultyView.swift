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
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                Text("Choose Difficulty")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Select how challenging the math problems should be")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Preview of math problem
            VStack(spacing: 16) {
                Text("Example Challenge")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(previewChallenge.questionText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)

                Text(difficultyDescription(for: selectedDifficulty))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // Difficulty slider
            VStack(spacing: 16) {
                HStack {
                    ForEach(ChallengeDifficulty.allCases, id: \.self) { difficulty in
                        Button {
                            selectedDifficulty = difficulty
                            previewChallenge = MathChallenge(difficulty: difficulty)
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(selectedDifficulty == difficulty ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)

                                Text(difficulty.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(selectedDifficulty == difficulty ? .primary : .secondary)
                            }
                        }

                        if difficulty != ChallengeDifficulty.allCases.last {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private func difficultyDescription(for difficulty: ChallengeDifficulty) -> String {
        switch difficulty {
        case .veryEasy: return "Numbers 1-10 • Addition & Subtraction"
        case .easy: return "Numbers 1-20 • Addition & Subtraction"
        case .medium: return "Numbers 10-50 • All Operations"
        case .hard: return "Numbers 20-100 • All Operations"
        case .veryHard: return "Numbers 50-200 • All Operations"
        }
    }
}

#Preview {
    OnboardingDifficultyView(selectedDifficulty: .constant(.medium), onContinue: {})
}
