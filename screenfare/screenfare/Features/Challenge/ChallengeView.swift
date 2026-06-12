//
//  ChallengeView.swift
//  screenfare
//
//  Pixel-perfect implementation of the "Card" variation from Claude Design handoff
//  Design specs: challenge-variations.jsx → VariationCard
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var historyManager = HistoryManager.shared

    // Challenge type and state
    @State private var challengeType: ChallengeType
    @State private var mathChallenge: MathChallenge?
    @State private var typingChallenge: TypingChallenge?
    @State private var memoryChallenge: MemoryChallenge?

    // Math challenge state
    @State private var userAnswer = ""
    @State private var mathResult: MathChallengeResult? = nil
    @FocusState private var isMathFocused: Bool

    // Typing challenge state
    @State private var typedText = ""
    @FocusState private var isTypingFocused: Bool

    // Memory challenge state
    @State private var selectedTiles: [Int] = []
    @State private var memoryStage: MemoryChallengeContent.MemoryStage = .memorize
    @State private var memoryCountdown = 3

    // Common state
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var isUnlocked = false
    @State private var attempts = 0
    @State private var shakeCount = 0
    @State private var requestedApp: ApplicationToken?

    init(challengeType: ChallengeType? = nil) {
        // Use provided challenge type or fall back to settings
        let settings = SettingsManager.shared
        let selectedType = challengeType ?? settings.challengeType
        _challengeType = State(initialValue: selectedType)

        // Try to load the requested app token from App Group
        if let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
           let data = sharedDefaults.data(forKey: "com.screenfare.requestedAppToken"),
           let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
            _requestedApp = State(initialValue: token)
        }

        // Initialize appropriate challenge
        switch selectedType {
        case .math:
            _mathChallenge = State(initialValue: MathChallenge(difficulty: settings.challengeDifficulty))
        case .typing:
            _typingChallenge = State(initialValue: TypingChallenge(difficulty: settings.typingDifficulty))
        case .memory:
            _memoryChallenge = State(initialValue: MemoryChallenge())
        }
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: "Not now" + "Math · Medium"
                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Not now")
                                .font(.inter(13, weight: .medium))
                        }
                        .foregroundColor(.focusMuted)
                        .padding(.horizontal, 14)
                        .padding(.leading, 10)
                        .padding(.vertical, 8)
                        .background(Color.focusInk.opacity(0.05))
                        .cornerRadius(17)
                    }

                    Spacer()
                        .frame(maxWidth: .infinity) // Prevent excessive stretching

                    Text(isUnlocked ? "Done" : challengeLabel)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                }
                .frame(height: 44) // Fixed height to prevent stretching
                .padding(.horizontal, 22)
                .padding(.top, 60)
                .padding(.bottom, 12)

                // Title
                HStack {
                    if isUnlocked {
                        (Text("Fare ")
                            .font(.instrumentSerif(30))
                         + Text("paid")
                            .font(.instrumentSerif(30, italic: true))
                         + Text(".")
                            .font(.instrumentSerif(30)))
                    } else {
                        (Text("Pay your ")
                            .font(.instrumentSerif(30))
                         + Text("fare")
                            .font(.instrumentSerif(30, italic: true))
                         + Text(".")
                            .font(.instrumentSerif(30)))
                    }
                }
                .foregroundColor(.focusInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true) // Prevent vertical stretching
                .padding(.horizontal, 22)
                .padding(.bottom, 16)

                // Main card
                ShakeEffect(trigger: shakeCount) {
                    VStack(spacing: 0) {
                        // App info row
                        HStack(spacing: 14) {
                            // Use Label from FamilyControls to show actual blocked app
                            ZStack(alignment: .bottomTrailing) {
                                // Prefer the requested app, fallback to first blocked app
                                if let app = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first {
                                    Label(app)
                                        .labelStyle(.iconOnly)
                                        .scaleEffect(1.6) // Scale up the FamilyControls icon
                                        .frame(width: 58, height: 58) // Frame to contain the scaled icon
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                } else {
                                    // Fallback if no apps available
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.focusAccent)
                                        .frame(width: 58, height: 58)
                                        .overlay(
                                            Image(systemName: "app.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(.white)
                                        )
                                }

                                // Lock badge
                                Circle()
                                    .fill(Color.focusBg)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.focusInk)
                                    )
                                    .offset(x: 7, y: 7)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                // Use generic title instead of app name
                                Text("Blocked App")
                                    .font(.inter(16, weight: .semibold))
                                    .foregroundColor(.focusInk)

                                Text(isUnlocked ? "Unlocked for \(settings.unlockDurationText)" : "Solve to unlock for \(settings.unlockDurationText)")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)

                        Divider()
                            .background(Color.focusLine)
                            .padding(.horizontal, 14)

                        Spacer().frame(height: 14)

                        // Challenge content area
                        if isUnlocked {
                            // Success state (same for all challenge types)
                            VStack(spacing: 14) {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 22, weight: .regular))
                                            .foregroundColor(.white)
                                    )

                                Text(formatCountdown())
                                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .tracking(-1.2)

                                Text("access remaining")
                                    .font(.inter(12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 26)
                            .background(Color.focusInk)
                            .cornerRadius(16)
                            .padding(.horizontal, 14)
                        } else {
                            // Challenge-specific content
                            switch challengeType {
                            case .math:
                                mathChallengeContent()
                            case .typing:
                                typingChallengeContent()
                            case .memory:
                                memoryChallengeContent()
                            }
                        }

                        Spacer().frame(height: 14)
                    }
                    .background(Color.white)
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.focusLine, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 10)
                }
                .padding(.horizontal, 22)

                // Error message
                HStack {
                    Spacer()
                    if showingResult && !isCorrect && !isUnlocked {
                        Text(errorMessage)
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.3))
                            .transition(.opacity)
                    }
                    Spacer()
                }
                .frame(height: 18)
                .padding(.top, 12)

                Spacer()
                    .frame(maxHeight: 100) // Limit spacer expansion to prevent stretching

                // Footer: Button (only for non-math challenges and unlocked state)
                VStack {
                    if isUnlocked {
                        Button {
                            openUnlockedApp()
                            dismiss()
                        } label: {
                            Text("Open App")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.focusInk)
                                .cornerRadius(16)
                        }
                    } else if challengeType != .math {
                        // Math challenge has its own inline button, so only show footer for typing/memory
                        switch challengeType {
                        case .math:
                            EmptyView()
                        case .typing:
                            Button {
                                checkTypingAnswer()
                            } label: {
                                Text(typingChallenge?.isCorrect(typedText) == true ? "Pay your fare" : "Type the line to continue")
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(typingChallenge?.isCorrect(typedText) == true ? Color.focusInk : Color.focusInk.opacity(0.12))
                                    .cornerRadius(16)
                            }
                            .disabled(typingChallenge?.isCorrect(typedText) != true)
                        case .memory:
                            Button {
                                checkMemoryAnswer()
                            } label: {
                                let remaining = (memoryChallenge?.litCount ?? 4) - selectedTiles.count
                                let buttonText = memoryStage == .memorize
                                    ? "Memorizing… \(memoryCountdown)"
                                    : selectedTiles.count == (memoryChallenge?.litCount ?? 4)
                                        ? "Confirm"
                                        : "Select \(remaining) more"

                                Text(buttonText)
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(memoryStage == .recall && selectedTiles.count == (memoryChallenge?.litCount ?? 4) ? Color.focusInk : Color.focusInk.opacity(0.12))
                                    .cornerRadius(16)
                            }
                            .disabled(memoryStage != .recall || selectedTiles.count != (memoryChallenge?.litCount ?? 4))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 38)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingResult)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
        .onAppear {
            // Auto-focus the appropriate field when challenge appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                switch challengeType {
                case .math:
                    isMathFocused = true
                case .typing:
                    isTypingFocused = true
                case .memory:
                    break // No keyboard for memory challenge
                }
            }
        }
    }

    private var challengeLabel: String {
        switch challengeType {
        case .math:
            return "Math · \(difficultyText)"
        case .typing:
            return "Typing · Pro"
        case .memory:
            return "Memory · Pro"
        }
    }

    private var difficultyText: String {
        switch settings.challengeDifficulty {
        case .veryEasy: return "Very Easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }

    private var errorMessage: String {
        switch challengeType {
        case .math:
            return "Not quite — give it another go"
        case .typing:
            return "That doesn't match — fix the highlighted part"
        case .memory:
            return "Not quite — watch the pattern again"
        }
    }

    // MARK: - Challenge Content Views

    @ViewBuilder
    private func mathChallengeContent() -> some View {
        if let challenge = mathChallenge {
            MathChallengeContent(
                challenge: challenge,
                userAnswer: $userAnswer,
                result: $mathResult,
                isFocused: $isMathFocused,
                onSubmit: checkMathAnswer
            )
        }
    }

    @ViewBuilder
    private func typingChallengeContent() -> some View {
        if let challenge = typingChallenge {
            TypingChallengeContent(
                challenge: challenge,
                typedText: $typedText,
                isFocused: $isTypingFocused,
                isUnlocked: isUnlocked
            )
        }
    }

    @ViewBuilder
    private func memoryChallengeContent() -> some View {
        if let challenge = memoryChallenge {
            MemoryChallengeContent(
                challenge: challenge,
                selectedTiles: $selectedTiles,
                stage: $memoryStage,
                countdown: $memoryCountdown,
                isUnlocked: isUnlocked,
                showError: showingResult && !isCorrect
            )
            .onAppear {
                startMemoryCountdown()
            }
        }
    }

    private func formatCountdown() -> String {
        let seconds = Int(settings.unlockDuration)
        let mm = seconds / 60
        let ss = seconds % 60
        return String(format: "%d:%02d", mm, ss)
    }

    // MARK: - Answer Checking

    private func checkMathAnswer() {
        guard let answer = Int(userAnswer),
              let challenge = mathChallenge else {
            return
        }

        let correct = challenge.isCorrect(answer)
        mathResult = correct ? .correct : .wrong

        if correct {
            unlockApp(eventType: .mathChallenge)
        } else {
            attempts += 1
            shakeCount += 1
            // Don't reset - let the user try again with feedback
        }
    }

    private func checkTypingAnswer() {
        guard let challenge = typingChallenge else { return }

        isCorrect = challenge.isCorrect(typedText)
        showingResult = true

        if isCorrect {
            unlockApp(eventType: .mathChallenge) // Using mathChallenge as placeholder
        } else {
            handleIncorrectAnswer {
                regenerateTypingChallenge()
            }
        }
    }

    private func checkMemoryAnswer() {
        guard let challenge = memoryChallenge else { return }

        isCorrect = challenge.isCorrect(selectedTiles)
        showingResult = true

        if isCorrect {
            unlockApp(eventType: .mathChallenge) // Using mathChallenge as placeholder
        } else {
            handleIncorrectAnswer {
                memoryChallenge = MemoryChallenge()
                selectedTiles = []
                memoryStage = .memorize
                startMemoryCountdown()
            }
        }
    }

    private func unlockApp(eventType: HistoryEvent.EventType) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Unlock the specific app that was requested
            let appToken = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first
            blockingManager.temporaryUnlock(appToken: appToken, duration: settings.unlockDuration)

            // Record the unlock event
            let appTokenData = appToken.flatMap { try? JSONEncoder().encode($0) }
            historyManager.recordEvent(
                appTokenData: appTokenData,
                eventType: eventType,
                duration: settings.unlockDuration
            )

            isUnlocked = true
        }
    }

    private func handleIncorrectAnswer(reset: @escaping () -> Void) {
        attempts += 1
        shakeCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            reset()
            showingResult = false
        }
    }

    private func regenerateTypingChallenge() {
        typingChallenge = TypingChallenge(difficulty: settings.typingDifficulty)
        typedText = ""
    }

    private func startMemoryCountdown() {
        memoryCountdown = 3
        memoryStage = .memorize

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if memoryCountdown > 1 {
                memoryCountdown -= 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    memoryStage = .recall
                }
            }
        }
    }

    private func openUnlockedApp() {
        // Get the app that was unlocked
        guard let appToken = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first else {
            print("[ChallengeView] No app token to open")
            return
        }

        // Unfortunately, iOS doesn't provide a direct API to open apps by ApplicationToken
        // The best we can do is dismiss and let the user manually open the app
        // The app is now unlocked, so it will open without showing the shield

        // Note: In theory we could try to extract the bundle ID and use openURL,
        // but ApplicationToken doesn't expose this information directly
        print("[ChallengeView] App unlocked, user can now open it manually")
    }
}

// Custom keypad matching the Card design
struct CustomKeypad: View {
    @Binding var input: String
    let onSubmit: () -> Void
    let canSubmit: Bool

    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    let digits = ["1","2","3","4","5","6","7","8","9"]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(digits, id: \.self) { digit in
                KeypadButton(style: .number, content: digit) {
                    input += digit
                }
            }

            // Delete button
            KeypadButton(style: .auxiliary, icon: "delete.left") {
                if !input.isEmpty {
                    input.removeLast()
                }
            }

            // 0
            KeypadButton(style: .number, content: "0") {
                input += "0"
            }

            // Submit button
            KeypadButton(style: .submit, icon: "checkmark", enabled: canSubmit) {
                if canSubmit {
                    onSubmit()
                }
            }
        }
    }
}

struct KeypadButton: View {
    enum Style {
        case number, auxiliary, submit
    }

    let style: Style
    var content: String?
    var icon: String?
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let content = content {
                    Text(content)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.focusInk)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: style == .submit ? 18 : 16, weight: .regular))
                        .foregroundColor(style == .submit ? (enabled ? .white : Color.white.opacity(0.6)) : .focusMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .disabled(!enabled)
    }

    private var backgroundColor: Color {
        switch style {
        case .number:
            return .white
        case .auxiliary:
            return Color.focusInk.opacity(0.05)
        case .submit:
            return enabled ? .focusInk : Color.focusInk.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch style {
        case .number:
            return Color.focusLine
        case .auxiliary, .submit:
            return .clear
        }
    }
}

// Shake animation on error
struct ShakeEffect<Content: View>: View {
    let trigger: Int
    let content: Content

    init(trigger: Int, @ViewBuilder content: () -> Content) {
        self.trigger = trigger
        self.content = content()
    }

    @State private var offset: CGFloat = 0

    var body: some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _ in
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

#Preview("Math Challenge") {
    ChallengeView(challengeType: .math)
}

#Preview("Typing Challenge") {
    ChallengeView(challengeType: .typing)
}

#Preview("Memory Challenge") {
    ChallengeView(challengeType: .memory)
}
