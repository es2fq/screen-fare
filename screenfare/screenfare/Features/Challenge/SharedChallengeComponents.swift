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
                charString.backgroundColor = Color.focusInk.opacity(0.12)
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

// MARK: - Trivia Challenge Field

/// A reusable trivia challenge component with multiple-choice answers
struct TriviaChallengeField: View {
    let triviaChallenge: TriviaChallenge
    let currentQuestion: Int
    let totalQuestions: Int
    @Binding var selectedAnswerIndex: Int?
    @Binding var hasSubmitted: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Progress indicator - matches memory challenge design
            HStack(spacing: 5) {
                ForEach(0..<totalQuestions, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressBarColor(for: i))
                        .frame(width: i == currentQuestion ? nil : nil, height: 5)
                        .frame(maxWidth: i == currentQuestion ? .infinity : .infinity)
                        .frame(width: i == currentQuestion ? nil : (UIScreen.main.bounds.width - 88) / CGFloat(totalQuestions * 2 - 1))
                }
            }
            .frame(height: 5)

            // Question text
            Text(triviaChallenge.question)
                .font(.instrumentSerif(27))
                .foregroundColor(.focusInk)
                .lineSpacing(27 * 1.22 - 27) // Line height 1.22
                .tracking(-0.01 * 27) // -0.01em letter spacing
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            // Answer choices
            VStack(spacing: 8) {
                ForEach(triviaChallenge.answers.indices, id: \.self) { index in
                    TriviaAnswerButton(
                        answer: triviaChallenge.answers[index],
                        letterIndex: index,
                        isSelected: selectedAnswerIndex == index,
                        isCorrect: hasSubmitted ? index == triviaChallenge.correctAnswerIndex : nil,
                        isWrong: hasSubmitted && selectedAnswerIndex == index && index != triviaChallenge.correctAnswerIndex
                    ) {
                        if !hasSubmitted {
                            selectedAnswerIndex = index
                        }
                    }
                }
            }

            // Submit button
            if !hasSubmitted {
                Button(action: onSubmit) {
                    Text(buttonText)
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selectedAnswerIndex != nil ? Color.focusInk : Color.focusInk.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(selectedAnswerIndex == nil)
                .padding(.top, 4)
            }
        }
    }

    private func progressBarColor(for index: Int) -> Color {
        if index < currentQuestion {
            return Color(red: 0.55, green: 0.65, blue: 0.4) // GREEN_C - completed
        } else if index == currentQuestion {
            return Color.focusInk // Current question
        } else {
            return Color.focusInk.opacity(0.14) // Upcoming
        }
    }

    private var buttonText: String {
        if selectedAnswerIndex == nil {
            return "Choose an answer"
        } else if currentQuestion == totalQuestions - 1 {
            return "Pay your fare"
        } else {
            return "Confirm answer"
        }
    }
}

/// Individual answer button for trivia questions
struct TriviaAnswerButton: View {
    let answer: String
    let letterIndex: Int // 0=A, 1=B, 2=C, 3=D
    let isSelected: Bool
    let isCorrect: Bool?
    let isWrong: Bool
    let action: () -> Void

    @State private var shakeCount = 0

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: {
            if isCorrect == nil {
                action()
            }
        }) {
            HStack(spacing: 11) {
                // Letter badge
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(badgeBackgroundColor)
                        .frame(width: 24, height: 24)

                    Text(letters[letterIndex])
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(badgeForegroundColor)
                }

                // Answer text
                Text(answer)
                    .font(.inter(14.5, weight: .medium))
                    .foregroundColor(textColor)
                    .tracking(-0.01 * 14.5) // -0.01em letter spacing
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(ShakeModifier(trigger: shakeCount))
        .onChange(of: isWrong) { _, newValue in
            if newValue {
                shakeCount += 1
            }
        }
    }

    private var backgroundColor: Color {
        if isCorrect == true {
            return Color(red: 0.94, green: 0.97, blue: 0.92) // Light green (TRIV_GREEN_SOFT)
        } else if isWrong {
            return Color(red: 0.99, green: 0.95, blue: 0.94) // Light red (TRIV_RED_SOFT)
        } else if isSelected {
            return Color.focusInk
        }
        return Color.white
    }

    private var borderColor: Color {
        if isCorrect == true {
            return Color(red: 0.55, green: 0.65, blue: 0.4) // GREEN_C
        } else if isWrong {
            return Color(red: 0.9, green: 0.5, blue: 0.4) // RED_C (TRIV_RED)
        } else if isSelected {
            return Color.focusInk
        }
        return Color.focusLine
    }

    private var textColor: Color {
        if isCorrect == true {
            return Color.focusInk // Dark text on light green background (visible)
        } else if isWrong {
            return Color(red: 0.9, green: 0.5, blue: 0.4) // TRIV_RED when wrong
        } else if isSelected {
            return Color.white // White text on dark background
        }
        return Color.focusInk
    }

    private var badgeBackgroundColor: Color {
        if isCorrect == true {
            return Color(red: 0.55, green: 0.65, blue: 0.4) // GREEN_C
        } else if isWrong {
            return Color(red: 0.9, green: 0.5, blue: 0.4) // TRIV_RED
        } else if isSelected {
            return Color.white.opacity(0.22)
        }
        return Color.focusInk.opacity(0.06)
    }

    private var badgeForegroundColor: Color {
        if isCorrect == true || isWrong || isSelected {
            return Color.white
        }
        return Color.focusMuted
    }
}

// MARK: - Trivia Loading Components

/// Animated bouncing dots for trivia loading state
struct TrivDots: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.focusInk)
                    .frame(width: 5, height: 5)
                    .modifier(BounceModifier(delay: Double(index) * 0.16))
            }
        }
    }
}

/// Bounce animation modifier for bouncing dots
private struct BounceModifier: ViewModifier {
    let delay: Double
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? -7 : 0)
            .opacity(isAnimating ? 1.0 : 0.4)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton placeholder for trivia loading (static gray)
struct TrivSkel: View {
    var width: CGFloat? = nil
    var height: CGFloat = 13
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.focusInk.opacity(0.08))
            .frame(width: width, height: height)
    }
}

// MARK: - Trivia Error State

/// Shared error state for trivia challenges when network connection fails
struct TriviaErrorView: View {
    let isNoConnection: Bool
    let onRetry: () -> Void
    let onSwitchToMath: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            // Icon container with background circle
            ZStack {
                Circle()
                    .fill(Color.focusInk.opacity(0.05))
                    .frame(width: 56, height: 56)

                Image(systemName: isNoConnection ? "wifi.slash" : "exclamationmark.triangle")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.4)) // TRIV_RED
            }

            // Title
            Text(isNoConnection ? "No connection" : "Can't load trivia")
                .font(.instrumentSerif(27))
                .foregroundColor(.focusInk)
                .lineSpacing(27 * 1.1 - 27)

            // Description
            Text(isNoConnection
                ? "Check your internet connection and try again."
                : "Unable to load trivia questions right now. Try the math challenge instead — it works offline.")
                .font(.inter(13.5))
                .foregroundColor(.focusMuted)
                .lineSpacing(13.5 * 1.5 - 13.5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
                .fixedSize(horizontal: false, vertical: true)

            // Button(s)
            if let switchToMath = onSwitchToMath {
                // Challenge view: Show both options
                VStack(spacing: 8) {
                    Button("Switch to Math") {
                        switchToMath()
                    }
                    .font(.inter(14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.focusInk)
                    .cornerRadius(10)

                    Button("Try again") {
                        onRetry()
                    }
                    .font(.inter(13, weight: .medium))
                    .foregroundColor(.focusMuted)
                }
            } else {
                // Config tester: Just "Try again" as primary button
                Button("Try again") {
                    onRetry()
                }
                .font(.inter(14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.focusInk)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
    }
}
