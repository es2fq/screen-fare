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
    @StateObject private var historyManager = UnlockHistoryManager.shared

    @State private var challenge: MathChallenge
    @State private var userAnswer = ""
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var isUnlocked = false
    @State private var attempts = 0
    @State private var shakeCount = 0
    @State private var requestedApp: ApplicationToken?

    init() {
        let settings = SettingsManager.shared
        _challenge = State(initialValue: MathChallenge(difficulty: settings.challengeDifficulty))

        // Try to load the requested app token from App Group
        if let sharedDefaults = UserDefaults(suiteName: "group.esong.screenfare.shared"),
           let data = sharedDefaults.data(forKey: "com.screenfare.requestedAppToken"),
           let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
            _requestedApp = State(initialValue: token)
        }
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: "Not now" + "Math · Medium"
                HStack {
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

                    Text(isUnlocked ? "Done" : "Math · \(difficultyText)")
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                }
                .padding(.horizontal, 22)
                .padding(.top, 72)
                .padding(.bottom, 8)

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
                .padding(.horizontal, 22)
                .padding(.bottom, 16)

                // Main card
                ShakeEffect(trigger: shakeCount) {
                    VStack(spacing: 0) {
                        // App info row
                        HStack(spacing: 12) {
                            // Use Label from FamilyControls to show actual blocked app
                            ZStack(alignment: .bottomTrailing) {
                                // Prefer the requested app, fallback to first blocked app
                                if let app = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first {
                                    Label(app)
                                        .labelStyle(.iconOnly)
                                        .frame(width: 36, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    // Fallback if no apps available
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.focusAccent)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "app.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        )
                                }

                                // Lock badge
                                Circle()
                                    .fill(Color.focusBg)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.focusInk)
                                    )
                                    .offset(x: 4, y: 4)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                // Prefer the requested app, fallback to first blocked app
                                if let app = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first {
                                    Label(app)
                                        .labelStyle(.titleOnly)
                                        .font(.inter(15, weight: .semibold))
                                        .foregroundColor(.focusInk)
                                } else {
                                    Text("Blocked App")
                                        .font(.inter(15, weight: .semibold))
                                        .foregroundColor(.focusInk)
                                }
                                Text(isUnlocked ? "Unlocked for \(settings.unlockDurationText)" : "Solve to unlock for \(settings.unlockDurationText)")
                                    .font(.inter(12))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 20)

                        Divider()
                            .background(Color.focusLine)
                            .padding(.horizontal, 14)

                        Spacer().frame(height: 14)

                        // Dark problem/result area
                        VStack(spacing: 14) {
                            if isUnlocked {
                                // Success state
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
                            } else {
                                // Challenge state
                                Text(attempts > 0 ? "Attempt \(attempts + 1) · solve to continue" : "Solve to continue")
                                    .font(.inter(10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1.6)
                                    .textCase(.uppercase)

                                Text(challenge.questionText)
                                    .font(.instrumentSerif(46))
                                    .foregroundColor(.white)
                                    .opacity(showingResult && !isCorrect ? 1.0 : 1.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isUnlocked ? 26 : 22)
                        .background(Color.focusInk)
                        .cornerRadius(16)
                        .padding(.horizontal, 14)

                        // Answer input (only in challenge mode)
                        if !isUnlocked {
                            HStack {
                                Spacer()

                                if userAnswer.isEmpty {
                                    Text("Type the answer")
                                        .font(.inter(15, weight: .regular))
                                        .foregroundColor(Color.focusInk.opacity(0.28))
                                } else {
                                    Text(userAnswer)
                                        .font(.system(size: 24, weight: .semibold, design: .default))
                                        .foregroundColor(.focusInk)
                                    + Text("|")
                                        .font(.system(size: 24, weight: .ultraLight))
                                        .foregroundColor(.focusInk.opacity(0.3))
                                }

                                Spacer()
                            }
                            .frame(height: 54)
                            .background(showingResult && !isCorrect ? Color(red: 0.975, green: 0.95, blue: 0.94) : Color.focusInk.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        showingResult && !isCorrect ? Color(red: 0.9, green: 0.5, blue: 0.4) :
                                        !userAnswer.isEmpty ? Color.focusInk : Color.focusLine,
                                        lineWidth: 1.5
                                    )
                            )
                            .cornerRadius(14)
                            .padding(.top, 12)
                            .padding(.horizontal, 14)
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
                        Text("Not quite — give it another go")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.3))
                            .transition(.opacity)
                    }
                    Spacer()
                }
                .frame(height: 18)
                .padding(.top, 12)

                Spacer()

                // Keypad / Open button
                VStack {
                    if isUnlocked {
                        Button {
                            // Try to open the app that was unlocked
                            openUnlockedApp()
                            // Dismiss after attempting to open
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
                    } else {
                        CustomKeypad(
                            input: $userAnswer,
                            onSubmit: checkAnswer,
                            canSubmit: !userAnswer.isEmpty && !showingResult
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 38)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingResult)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
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

    private func formatCountdown() -> String {
        let seconds = Int(settings.unlockDuration)
        let mm = seconds / 60
        let ss = seconds % 60
        return String(format: "%d:%02d", mm, ss)
    }

    private func checkAnswer() {
        guard let answer = Int(userAnswer) else {
            return
        }

        isCorrect = challenge.isCorrect(answer)
        showingResult = true

        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Unlock the specific app that was requested
                let appToken = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first
                blockingManager.temporaryUnlock(appToken: appToken, duration: settings.unlockDuration)

                // Record the unlock event
                let appTokenData = appToken.flatMap { try? JSONEncoder().encode($0) }
                historyManager.recordUnlock(
                    appTokenData: appTokenData,
                    unlockMethod: .mathChallenge,
                    duration: settings.unlockDuration
                )

                isUnlocked = true
            }
        } else {
            attempts += 1
            shakeCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                challenge = MathChallenge(difficulty: settings.challengeDifficulty)
                userAnswer = ""
                showingResult = false
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

#Preview {
    ChallengeView()
}
