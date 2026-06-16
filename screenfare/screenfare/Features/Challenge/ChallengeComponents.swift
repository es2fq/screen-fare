//
//  ChallengeComponents.swift
//  Screen Fare
//
//  Specialized challenge components for Typing and Memory challenges
//

import SwiftUI

// MARK: - Math Challenge View

struct MathChallengeContent: View {
    let challenge: MathChallenge
    @Binding var userAnswer: String
    @Binding var result: MathChallengeResult?
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Use shared math challenge field component
            MathChallengeField(
                questionText: challenge.questionText,
                userAnswer: $userAnswer,
                result: $result,
                isFocused: $isFocused,
                onSubmit: onSubmit
            )
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }
}

// MARK: - Typing Challenge View

struct TypingChallengeContent: View {
    let challenge: TypingChallenge
    @Binding var typedText: String
    @FocusState.Binding var isFocused: Bool
    let isUnlocked: Bool

    var isComplete: Bool {
        typedText == challenge.targetText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Use shared typing challenge field component
            TypingChallengeField(
                targetText: challenge.targetText,
                typedText: $typedText,
                isFocused: $isFocused
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(minHeight: 120)

            // Progress indicator
            HStack {
                if isComplete {
                    Text("Looks good")
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                } else {
                    Text("Keep going")
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                }

                Spacer()

                Text("\(typedText.count)/\(challenge.targetText.count)")
                    .font(.inter(12))
                    .foregroundColor(.focusMuted)
                    .monospacedDigit()
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }
}

// MARK: - Memory Challenge View

struct MemoryChallengeContent: View {
    let challenge: MemoryChallenge
    @Binding var selectedTiles: [Int]
    @Binding var stage: MemoryStage
    @Binding var countdown: Int
    let isUnlocked: Bool
    let showError: Bool

    enum MemoryStage {
        case memorize
        case recall
    }

    var body: some View {
        VStack(spacing: 0) {
            // Instruction row
            HStack {
                HStack(spacing: 0) {
                    if stage == .memorize {
                        Text("Memorize the lit tiles")
                            .font(.inter(13.5, weight: .medium))
                            .foregroundColor(.focusInk)
                    } else {
                        Text("Tap the \(challenge.litCount) tiles you saw")
                            .font(.inter(13.5, weight: .medium))
                            .foregroundColor(.focusInk)
                    }
                }

                Spacer()

                if stage == .memorize {
                    Text("\(countdown)")
                        .font(.inter(13, weight: .semibold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 26)
                        .frame(height: 26)
                        .padding(.horizontal, 8)
                        .background(Color.focusInk)
                        .cornerRadius(13)
                } else {
                    Text("\(selectedTiles.count)/\(challenge.litCount)")
                        .font(.inter(13))
                        .foregroundColor(.focusMuted)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: challenge.columns), spacing: 10) {
                ForEach(0..<challenge.gridSize, id: \.self) { index in
                    MemoryTile(
                        index: index,
                        isLit: challenge.litTiles.contains(index),
                        isSelected: selectedTiles.contains(index),
                        stage: stage,
                        showError: showError,
                        isUnlocked: isUnlocked
                    ) {
                        toggleTile(index)
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private func toggleTile(_ index: Int) {
        guard stage == .recall && !isUnlocked else { return }

        if selectedTiles.contains(index) {
            selectedTiles.removeAll { $0 == index }
        } else if selectedTiles.count < challenge.litCount {
            selectedTiles.append(index)
        }
    }
}

struct MemoryTile: View {
    let index: Int
    let isLit: Bool
    let isSelected: Bool
    let stage: MemoryChallengeContent.MemoryStage
    let showError: Bool
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(backgroundColor)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .cornerRadius(14)
        }
        .disabled(stage == .memorize || isUnlocked)
        .buttonStyle(PlainButtonStyle())
    }

    private var backgroundColor: Color {
        if isUnlocked {
            return isLit ? .focusInk : Color.focusInk.opacity(0.05)
        }

        if stage == .memorize {
            return isLit ? .focusInk : Color.focusInk.opacity(0.05)
        } else {
            // Recall stage
            if showError && isSelected && !isLit {
                return Color(red: 0.975, green: 0.95, blue: 0.94)
            } else if isSelected {
                return .focusInk
            } else {
                return Color.focusInk.opacity(0.05)
            }
        }
    }

    private var borderColor: Color {
        if stage == .recall && showError {
            if isSelected && !isLit {
                return Color(red: 0.9, green: 0.5, blue: 0.4)
            } else if isLit && !isSelected {
                return Color.focusInk.opacity(0.35)
            }
        }
        return .clear
    }

    private var borderWidth: CGFloat {
        if stage == .recall && showError {
            if isSelected && !isLit {
                return 1.5
            } else if isLit && !isSelected {
                return 1.5
            }
        }
        return 0
    }
}
