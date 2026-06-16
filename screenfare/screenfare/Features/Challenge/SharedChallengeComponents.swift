//
//  SharedChallengeComponents.swift
//  Screen Fare
//
//  Shared, reusable challenge components used in both previews and actual challenges
//

import SwiftUI

// MARK: - Math Challenge Field

/// A reusable math challenge input field with validation and feedback
struct MathChallengeField: View {
    let questionText: String
    @Binding var userAnswer: String
    @Binding var result: MathChallengeResult?
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            // Problem display
            Text(questionText.replacingOccurrences(of: " = ?", with: " ="))
                .font(.instrumentSerif(32))
                .foregroundColor(.focusInk)
                .monospacedDigit()
                .tracking(-0.01 * 32)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping outside input
                    isFocused = false
                }

            // Input + Button
            HStack(spacing: 8) {
                TextField("Answer", text: $userAnswer)
                    .keyboardType(.numberPad)
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(.focusInk)
                    .monospacedDigit()
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(result == .wrong ? Color(red: 0.955, green: 0.95, blue: 0.94) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                    .cornerRadius(11)
                    .focused($isFocused)
                    .onChange(of: userAnswer) { _, _ in
                        if result == .wrong {
                            result = nil
                        }
                    }
                    .onSubmit {
                        if canSubmit {
                            onSubmit()
                        }
                    }

                Button(action: onSubmit) {
                    Text(result == .correct ? "Next" : "Check")
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                        .background(canSubmit ? Color.focusInk : Color.focusInk.opacity(0.1))
                        .cornerRadius(11)
                }
                .disabled(!canSubmit)
            }

            // Feedback
            Text(feedbackText)
                .font(.inter(12.5, weight: .medium))
                .foregroundColor(feedbackColor)
                .frame(height: 16, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping outside input
                    isFocused = false
                }
        }
    }

    private var canSubmit: Bool {
        result == .correct || !userAnswer.isEmpty
    }

    private var borderColor: Color {
        if result == .correct {
            return Color(red: 0.55, green: 0.65, blue: 0.4) // GREEN_C
        } else if result == .wrong {
            return Color(red: 0.9, green: 0.5, blue: 0.4) // RED_C
        }
        return Color.focusLine
    }

    private var feedbackText: String {
        if result == .correct {
            return "Correct — that would unlock."
        } else if result == .wrong {
            return "Not quite. Try again."
        }
        return "·"
    }

    private var feedbackColor: Color {
        if result == .correct {
            return Color(red: 0.55, green: 0.65, blue: 0.4) // GREEN_C
        } else if result == .wrong {
            return Color(red: 0.7, green: 0.4, blue: 0.3) // RED_C
        }
        return Color.clear
    }
}

/// Result state for math challenges
enum MathChallengeResult {
    case correct
    case wrong
}

// MARK: - Typing Challenge Field

/// A reusable typing challenge input field with robust character-by-character validation
struct TypingChallengeField: View {
    let targetText: String
    @Binding var typedText: String
    @FocusState.Binding var isFocused: Bool
    @State private var shakeCount = 0
    @State private var wrongChar: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Visible text with character coloring
            Text(coloredText)
                .font(.instrumentSerif(21))
                .lineSpacing(1.4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(ShakeModifier(trigger: shakeCount))
                .onTapGesture {
                    // Only the text itself focuses the keyboard
                    isFocused = true
                }

            // Hidden text field with custom binding for validation
            TextField("", text: Binding(
                get: { typedText },
                set: { newValue in
                    // Prevent backspace - only allow moving forward
                    if newValue.count < typedText.count {
                        return
                    }

                    // Validate each character as it's typed (case sensitive)
                    if newValue.count > typedText.count {
                        // Validate ALL new characters, not just the last one
                        // This prevents skipping when typing very quickly
                        let startIndex = typedText.count
                        let endIndex = min(newValue.count, targetText.count)

                        var allCorrect = true
                        var firstWrongChar: String? = nil

                        // Check each new character
                        for i in startIndex..<endIndex {
                            let targetChar = Array(targetText)[i]
                            let typedChar = Array(newValue)[i]

                            if targetChar != typedChar {
                                allCorrect = false
                                firstWrongChar = String(typedChar)
                                break
                            }
                        }

                        if allCorrect && endIndex <= targetText.count {
                            // All new characters are correct - accept them
                            typedText = String(newValue.prefix(endIndex))
                        } else {
                            // Wrong character detected - show it briefly, then reject
                            if let wrongCharacter = firstWrongChar {
                                wrongChar = wrongCharacter
                                shakeCount += 1

                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()

                                // Clear wrong char after brief delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    wrongChar = nil
                                }
                            }
                            // Don't update typedText - stay at current position
                        }
                    }
                }
            ))
                .opacity(0)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
        }
        .padding(.vertical, 2)
    }

    private var coloredText: AttributedString {
        var result = AttributedString()

        for (index, char) in targetText.enumerated() {
            let isDone = index < typedText.count
            let isCorrect = isDone && Array(typedText)[index] == char
            let isCursor = index == typedText.count && isFocused
            let isWrongPosition = index == typedText.count && wrongChar != nil

            // Show the wrong character if present
            let displayChar = isWrongPosition && wrongChar != nil ? wrongChar! : String(char)
            var charString = AttributedString(displayChar)

            if isWrongPosition && wrongChar != nil {
                // Wrong character - show in red with background
                charString.foregroundColor = Color(red: 0.7, green: 0.4, blue: 0.3)
                charString.backgroundColor = Color(red: 0.955, green: 0.95, blue: 0.94)
            } else if isCorrect {
                charString.foregroundColor = Color.focusInk
            } else if isCursor {
                // Cursor position - highlight the next character to type
                charString.foregroundColor = Color.focusInk
                charString.backgroundColor = Color.focusAccent.opacity(0.2)
            } else {
                charString.foregroundColor = Color.focusInk.opacity(0.3)
            }

            result.append(charString)
        }

        return result
    }
}

// MARK: - Shake Modifier

/// A view modifier that adds a shake animation effect
struct ShakeModifier: ViewModifier {
    let trigger: Int
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { oldValue, newValue in
                withAnimation(.linear(duration: 0.08)) {
                    offset = -9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.linear(duration: 0.08)) {
                        offset = 8
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.linear(duration: 0.08)) {
                            offset = -5
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            withAnimation(.linear(duration: 0.08)) {
                                offset = 3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                withAnimation(.linear(duration: 0.08)) {
                                    offset = 0
                                }
                            }
                        }
                    }
                }
            }
    }
}
