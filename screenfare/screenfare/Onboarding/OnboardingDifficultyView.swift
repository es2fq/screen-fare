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
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Challenge Difficulty")
                    .font(.system(size: 34, weight: .bold))

                Text("Live preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(previewChallenge.questionText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
            }

            // Difficulty slider
            VStack(spacing: 16) {
                CustomDifficultySlider(selectedDifficulty: $selectedDifficulty) {
                    previewChallenge = MathChallenge(difficulty: selectedDifficulty)
                }
                .padding(.horizontal, 32)

                Text(difficultyDescription(for: selectedDifficulty))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        case .veryEasy: return "1-10, addition & subtraction"
        case .easy: return "1-20, addition & subtraction"
        case .medium: return "10-50, all operations"
        case .hard: return "20-100, all operations"
        case .veryHard: return "50-200, all operations"
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
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Filled track
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(sliderValue / 4), height: 8)
                }
                .frame(height: 8)

                // Slider thumb
                GeometryReader { geometry in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 3)
                        )
                        .offset(x: geometry.size.width * CGFloat(sliderValue / 4) - 14)
                }
                .frame(height: 28)
            }
            .frame(height: 28)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percent = value.location.x / UIScreen.main.bounds.width * 1.3 // Adjust for padding
                        let newValue = max(0, min(4, percent * 4))
                        let snappedValue = round(newValue)
                        if snappedValue != sliderValue {
                            sliderValue = snappedValue
                            selectedDifficulty = difficulties[Int(snappedValue)]
                            onChange()
                        }
                    }
            )

            // Labels
            HStack {
                ForEach(Array(difficulties.enumerated()), id: \.offset) { index, difficulty in
                    Text(shortName(for: difficulty))
                        .font(.caption)
                        .foregroundColor(Int(sliderValue) == index ? .blue : .secondary)
                        .fontWeight(Int(sliderValue) == index ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func shortName(for difficulty: ChallengeDifficulty) -> String {
        switch difficulty {
        case .veryEasy: return "Very Easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }
}

#Preview {
    OnboardingDifficultyView(selectedDifficulty: .constant(.medium), onContinue: {})
}
