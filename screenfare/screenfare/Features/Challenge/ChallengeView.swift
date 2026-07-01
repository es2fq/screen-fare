//
//  ChallengeView.swift
//  Screen Fare
//
//  Ticket-themed challenge implementation
//  Design specs: challenge-ticket.jsx and challenge-ticket-pro.jsx
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedTab) private var selectedTab
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var historyManager = HistoryManager.shared

    // Challenge phase
    enum ChallengePhase {
        case challenge
        case paying    // Stamp and tear animation
        case unlocked  // Shows validated ticket with countdown
    }

    @State private var phase: ChallengePhase = .challenge
    @State private var challengeType: ChallengeType
    @State private var requestedApp: ApplicationToken?
    @State private var requestedCategory: ActivityCategoryToken?

    // Math challenge state
    @State private var mathChallenge: MathChallenge?
    @State private var userAnswer = ""
    @FocusState private var isMathFocused: Bool

    // Typing challenge state
    @State private var typingChallenge: TypingChallenge?
    @State private var typedText = ""
    @FocusState private var isTypingFocused: Bool

    // Memory challenge state
    @State private var memoryChallenge: MemoryChallenge?
    @State private var selectedTiles: [Int] = []
    @State private var memoryStage: MemoryStage = .memorize
    @State private var memoryCountdown = 3

    enum MemoryStage {
        case memorize
        case recall
    }

    // Breathing challenge state
    @State private var breathingChallenge: BreathingChallenge?
    @State private var currentBreath: Int = 0
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var phaseProgress: Double = 0
    @State private var isBreathingAnimating: Bool = false

    // Common state
    @State private var attempts = 0
    @State private var shakeCount = 0
    @State private var showError = false
    @State private var showStamp = false

    // Animation state for tear
    @State private var fareStubOffset: CGFloat = 0
    @State private var fareStubRotation: Double = 0
    @State private var fareStubOpacity: Double = 1
    @State private var passStubOffset: CGFloat = 0
    @State private var passStubScale: CGFloat = 1

    // Countdown timer - now uses current time to calculate from expiry
    @State private var currentTime = Date()
    @State private var countdownTimer: Timer?
    @State private var hasAutoDismissed = false // Prevent multiple dismiss calls

    // Strict mode support
    @State private var isStrictMode: Bool = false
    @State private var strictModeTitle: String = ""
    var onStrictModePass: (() -> Void)?

    init(challengeType: ChallengeType? = nil, isStrictMode: Bool = false, strictModeTitle: String? = nil, onStrictModePass: (() -> Void)? = nil) {
        let settings = SettingsManager.shared
        let selectedType = challengeType ?? settings.challengeType
        _challengeType = State(initialValue: selectedType)
        _isStrictMode = State(initialValue: isStrictMode)
        _strictModeTitle = State(initialValue: strictModeTitle ?? "")
        self.onStrictModePass = onStrictModePass

        // Load requested app token (skip if strict mode)
        if !isStrictMode, let sharedDefaults = UserDefaults.appGroup {
            if let data = sharedDefaults.data(forKey: "com.screenfare.requestedAppToken"),
               let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                _requestedApp = State(initialValue: token)
            }

            // Load requested category token
            if let data = sharedDefaults.data(forKey: "com.screenfare.requestedCategoryToken"),
               let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                _requestedCategory = State(initialValue: token)
            }
        }

        // Initialize challenge
        switch selectedType {
        case .math:
            _mathChallenge = State(initialValue: MathChallenge(difficulty: settings.challengeDifficulty))
        case .typing:
            _typingChallenge = State(initialValue: TypingChallenge(difficulty: settings.typingDifficulty))
        case .memory:
            _memoryChallenge = State(initialValue: MemoryChallenge(gridSize: settings.memoryGridSize, litCount: settings.memoryTilesToMatch))
        case .breathing:
            _breathingChallenge = State(initialValue: BreathingChallenge(totalBreaths: settings.breathingCycles))
        }
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (fixed)
                HStack(alignment: .center) {
                    Wordmark()

                    Spacer()

                    if phase == .challenge {
                        CloseX {
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 4)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(minHeight: 20)

                        // Main ticket
                        VStack(spacing: 0) {
                            // FARE STUB (top) - tears off on payment
                            if phase != .unlocked {
                                fareStub
                                    .offset(y: fareStubOffset)
                                    .rotationEffect(.degrees(fareStubRotation))
                                    .opacity(fareStubOpacity)
                            }

                            // PASS STUB (bottom) - what you keep
                            passStub
                                .offset(y: passStubOffset)
                                .scaleEffect(passStubScale)
                        }
                        .modifier(ShakeModifier(trigger: shakeCount))
                        .padding(.horizontal, 22)
                        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 20)

                        // Status message
                        HStack {
                            Spacer()
                            if phase == .challenge && showError {
                                Text(errorText)
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(.transitRed)
                                    .transition(.opacity)
                            }
                            Spacer()
                        }
                        .frame(height: 18)
                        .padding(.top, 16)

                        Spacer()
                            .frame(minHeight: 20)

                        // Footer button
                        footer
                            .padding(.horizontal, 22)
                            .padding(.bottom, 34)
                    }
                }
            }
        }
        .onAppear {
            focusInput()
            if challengeType == .memory {
                startMemoryCountdown()
            }

            // Record challenge started event when the challenge view actually appears (skip for strict mode)
            if !isStrictMode, let appToken = requestedApp {
                let appTokenData = try? JSONEncoder().encode(appToken)
                let challengeTypeName: String = {
                    switch challengeType {
                    case .math: return "Math"
                    case .typing: return "Typing"
                    case .memory: return "Memory"
                    case .breathing: return "Breathing"
                    }
                }()
                historyManager.recordEvent(
                    appTokenData: appTokenData,
                    eventType: .challengeStarted,
                    duration: 0,
                    challengeType: challengeTypeName
                )
            }
        }
    }

    // MARK: - Fare Stub (Top)

    @ViewBuilder
    private var fareStub: some View {
        ZStack {
            VStack(spacing: 0) {
                // Dark header
                HStack {
                    HStack(spacing: 8) {
                        if isStrictMode {
                            LockMini(color: .white, size: 13)

                            Text("OVERRIDE FARE")
                                .font(.inter(10, weight: .semibold))
                                .tracking(1.8)
                                .foregroundColor(.white.opacity(0.85))
                        } else {
                            Image(systemName: "star")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)

                            Text("SINGLE FARE")
                                .font(.inter(10, weight: .semibold))
                                .tracking(1.8)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    Spacer()

                    Text(ticketNumber)
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(0.44)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .padding(.bottom, -1)
                .background(Color.focusInk)

                // App info row
                HStack(alignment: .center, spacing: 11) {
                    // App, Category, or Lock icon (for strict mode)
                    if isStrictMode {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.focusInk)
                                .frame(width: 34, height: 34)

                            LockMini(color: .white)
                        }
                    } else if let category = requestedCategory {
                        Label(category)
                            .labelStyle(.iconOnly)
                            .scaleEffect(1.35)
                            .frame(width: 34, height: 34)
                    } else if let app = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first {
                        Label(app)
                            .labelStyle(.iconOnly)
                            .scaleEffect(1.35)
                            .frame(width: 34, height: 34)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(isStrictMode ? strictModeTitle : (requestedCategory != nil ? "Blocked Category" : "Blocked App"))
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(.focusInk)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(isStrictMode ? "Protected change" : "Boarding · blocked")
                            .font(.inter(11.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(isStrictMode ? "SCOPE" : "VALID")
                            .font(.inter(9.5, weight: .medium))
                            .tracking(1.33)
                            .foregroundColor(.focusMuted)

                        Text(isStrictMode ? "Once" : settings.unlockDurationText)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.focusInk)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)

                // Challenge content
                VStack(spacing: 0) {
                    if let fareLabel = fareLabel, let fareMeta = fareMeta {
                        HStack {
                            Text(fareLabel.uppercased())
                                .font(.inter(10.5, weight: .medium))
                                .tracking(1.68)
                                .foregroundColor(.focusMuted)

                            Spacer()

                            Text(fareMeta)
                                .font(.inter(11))
                                .foregroundColor(.focusMuted)
                        }
                        .padding(.bottom, 10)
                    }

                    challengeContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: phase == .unlocked ? 0 : 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: phase == .unlocked ? 0 : 22
            ))
            .overlay(
                // Paid stamp overlay - positioned absolutely in center
                Group {
                    if showStamp {
                        PaidStamp(show: showStamp)
                    }
                }
            )
        }
    }

    // MARK: - Pass Stub (Bottom)

    @ViewBuilder
    private var passStub: some View {
        VStack(spacing: 0) {
            if phase == .unlocked {
                // Validated/Authorized header (green)
                HStack {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text(isStrictMode ? "AUTHORIZED" : "VALIDATED")
                            .font(.inter(10, weight: .bold))
                            .tracking(1.8)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text(ticketNumber)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .padding(.bottom, -1)
                .background(Color.transitGreen)

                // App info
                HStack(spacing: 11) {
                    if isStrictMode {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.focusInk)
                                .frame(width: 34, height: 34)

                            LockMini(color: .white)
                        }
                    } else if let category = requestedCategory {
                        Label(category)
                            .labelStyle(.iconOnly)
                            .scaleEffect(1.35)
                            .frame(width: 34, height: 34)
                    } else if let app = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first {
                        Label(app)
                            .labelStyle(.iconOnly)
                            .scaleEffect(1.35)
                            .frame(width: 34, height: 34)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(isStrictMode ? strictModeTitle : (requestedCategory != nil ? "Blocked Category" : "Blocked App"))
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(.focusInk)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(isStrictMode ? "Cleared to change" : "Access granted")
                            .font(.inter(11.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 8)

                // Countdown or Authorization message
                if isStrictMode {
                    // Authorization granted message
                    VStack(spacing: 4) {
                        Text("AUTHORIZATION")
                            .font(.inter(10, weight: .medium))
                            .tracking(1.8)
                            .foregroundColor(.focusMuted)

                        Text("Granted")
                            .font(.instrumentSerif(44))
                            .tracking(-0.88)
                            .foregroundColor(.focusInk)
                            .padding(.vertical, 2)

                        Text("This override applies to one change, this time only.")
                            .font(.inter(12))
                            .foregroundColor(.focusMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1.4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                } else {
                    // Countdown timer
                    VStack(spacing: 4) {
                        Text("EXPIRES IN")
                            .font(.inter(10, weight: .medium))
                            .tracking(1.8)
                            .foregroundColor(.focusMuted)

                        Text(formatCountdown())
                            .font(.system(size: 46, weight: .semibold, design: .monospaced))
                            .tracking(-1.38)
                            .foregroundColor(.focusInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .padding(.top, 2)
                }

                // Barcode and zone/scope
                HStack {
                    Barcode()

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(isStrictMode ? "SCOPE" : "ZONE")
                            .font(.inter(9.5, weight: .medium))
                            .tracking(1.33)
                            .foregroundColor(.focusMuted)

                        Text(isStrictMode ? "Once" : "01")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.focusInk)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            } else {
                // Unstamped bottom stub
                HStack {
                    Barcode(tint: Color.focusInk.opacity(0.5), height: 30)

                    Spacer()

                    HStack(spacing: 18) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("ZONE")
                                .font(.inter(9, weight: .medium))
                                .tracking(1.26)
                                .foregroundColor(.focusMuted)

                            Text("01")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.focusInk)
                        }

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("TYPE")
                                .font(.inter(9, weight: .medium))
                                .tracking(1.26)
                                .foregroundColor(.focusMuted)

                            Text(ticketType)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.focusInk)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .padding(.bottom, 1)
            }
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: phase == .unlocked ? 22 : 0,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: 22,
            topTrailingRadius: phase == .unlocked ? 22 : 0
        ))
    }

    // MARK: - Challenge Content

    @ViewBuilder
    private var challengeContent: some View {
        switch challengeType {
        case .math:
            mathContent
        case .typing:
            typingContent
        case .memory:
            memoryContent
        case .breathing:
            breathingContent
        }
    }

    @ViewBuilder
    private var mathContent: some View {
        if let challenge = mathChallenge {
            VStack(spacing: 16) {
                // Problem
                Text(challenge.question)
                    .font(.instrumentSerif(50))
                    .foregroundColor(.focusInk)
                    .opacity(phase == .paying ? 0.5 : 1)
                    .monospacedDigit()

                // Answer field
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            showError ? Color.transitRed : (userAnswer.isEmpty ? Color.focusInk.opacity(0.14) : Color.focusInk),
                            lineWidth: 1.5
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(showError ? Color.transitRedSoft : Color.white)
                        )
                        .frame(height: 54)

                    if userAnswer.isEmpty {
                        Text("Enter answer")
                            .font(.inter(15))
                            .foregroundColor(Color.focusInk.opacity(0.28))
                    } else {
                        HStack(spacing: 2) {
                            Text(userAnswer)
                                .font(.system(size: 25, weight: .semibold, design: .monospaced))
                                .foregroundColor(.focusInk)

                            if phase == .challenge {
                                Rectangle()
                                    .fill(Color.focusInk)
                                    .frame(width: 2, height: 25)
                                    .blinking()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var typingContent: some View {
        if let challenge = typingChallenge {
            VStack(spacing: 12) {
                // Typing field with character-by-character feedback
                TypingField(
                    target: challenge.text,
                    typed: $typedText,
                    isFocused: $isTypingFocused,
                    isActive: phase == .challenge,
                    onComplete: checkTypingAnswer
                )

                // Hint
                Divider()
                    .background(Color.focusLine)

                HStack {
                    Text(typingHintText)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var memoryContent: some View {
        if let challenge = memoryChallenge {
            // Memory grid only (no level progress bar)
            MemoryGrid(
                challenge: challenge,
                selectedTiles: $selectedTiles,
                stage: memoryStage,
                showError: showError,
                gridSize: challenge.columns,
                isActive: phase == .challenge,
                onComplete: checkMemoryAnswer
            )
        }
    }

    @ViewBuilder
    private var breathingContent: some View {
        if let challenge = breathingChallenge {
            BreathingChallengeContent(
                challenge: challenge,
                currentBreath: $currentBreath,
                currentPhase: $currentPhase,
                phaseProgress: $phaseProgress,
                isAnimating: $isBreathingAnimating,
                onComplete: checkBreathingAnswer
            )
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if phase == .unlocked {
            TicketBtn("Close") {
                if isStrictMode {
                    dismiss()
                } else {
                    openUnlockedApp()
                    selectedTab?.wrappedValue = 0 // Navigate to Today tab
                    dismiss()
                }
            }
        } else {
            switch challengeType {
            case .math:
                TicketKeypad(input: $userAnswer, onSubmit: checkMathAnswer, canSubmit: !userAnswer.isEmpty && phase == .challenge)
            case .typing:
                EmptyView() // No button needed - auto-submits on completion
            case .memory:
                EmptyView() // No button needed - auto-submits on completion
            case .breathing:
                EmptyView() // No button needed - auto-completes on breath completion
            }
        }
    }

    // MARK: - Helpers

    private var ticketNumber: String {
        if isStrictMode {
            return "No. SM·0142"
        } else {
            let blockCount = StatsManager.shared.todayStats.blocksToday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMdd"
            let dateString = dateFormatter.string(from: Date())
            return "No. \(blockCount)·\(dateString)"
        }
    }

    private var ticketType: String {
        if isStrictMode {
            return "OVR"
        } else {
            switch challengeType {
            case .math: return "MATH"
            case .typing: return "TYPE"
            case .memory: return "MEM"
            case .breathing: return "BREATH"
            }
        }
    }

    private var fareLabel: String? {
        switch challengeType {
        case .math:
            return "Fare due"
        case .typing:
            return "Type the line"
        case .memory:
            switch memoryStage {
            case .memorize: return "Memorize \(memoryChallenge?.litCount ?? 4)"
            case .recall: return "Tap the \(memoryChallenge?.litCount ?? 4)"
            }
        case .breathing:
            return "Follow the breath"
        }
    }

    private var fareMeta: String? {
        switch challengeType {
        case .math:
            return attempts > 0 ? "Attempt \(attempts + 1)" : "Solve to board"
        case .typing:
            return "\(typedText.count)/\(typingChallenge?.text.count ?? 0)"
        case .memory:
            switch memoryStage {
            case .memorize: return "\(memoryCountdown)s"
            case .recall: return "\(selectedTiles.count)/\(memoryChallenge?.litCount ?? 4)"
            }
        case .breathing:
            let total = breathingChallenge?.totalBreaths ?? settings.breathingCycles
            return "Breath \(currentBreath)/\(total)"
        }
    }

    private var payingLabel: String {
        isStrictMode ? "Stamping your override…" : "Tearing your stub…"
    }

    private var errorText: String {
        switch challengeType {
        case .math:
            return "Not the right fare — try again"
        case .typing:
            return "That doesn't match — fix the highlighted part"
        case .memory:
            return "Not quite — watch the pattern again"
        case .breathing:
            return "" // Breathing challenge doesn't have errors
        }
    }

    private var typingHintText: String {
        if typingChallenge?.isCorrect(typedText) == true {
            return "Looks good — pay your fare"
        } else if showError {
            return "Match the line exactly"
        } else {
            return "Keep going"
        }
    }

    private var memoryButtonText: String {
        switch memoryStage {
        case .memorize:
            return "Memorizing… \(memoryCountdown)"
        case .recall:
            let remaining = (memoryChallenge?.litCount ?? 4) - selectedTiles.count
            if selectedTiles.count == memoryChallenge?.litCount {
                return "Pay your fare"
            } else {
                return "Select \(remaining) more"
            }
        }
    }

    private var memoryButtonDisabled: Bool {
        memoryStage != .recall || selectedTiles.count != memoryChallenge?.litCount
    }

    private func formatCountdown() -> String {
        var remainingSeconds = 0

        // Check if this is a category unlock
        if let categoryToken = requestedCategory,
           let categoryTokenData = try? JSONEncoder().encode(categoryToken) {
            if let expiryTime = blockingManager.temporaryCategoryUnlocks[categoryTokenData] {
                remainingSeconds = max(0, Int(expiryTime.timeIntervalSince(currentTime)))
            } else {
                print("[ChallengeView] ⚠️ Category token exists but not in temporaryCategoryUnlocks")
                print("[ChallengeView] temporaryCategoryUnlocks count: \(blockingManager.temporaryCategoryUnlocks.count)")
            }
        }
        // Otherwise check for app unlock
        else if let appToken = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first,
                let appTokenData = try? JSONEncoder().encode(appToken),
                let expiryTime = blockingManager.temporaryUnlocks[appTokenData] {
            remainingSeconds = max(0, Int(expiryTime.timeIntervalSince(currentTime)))
        } else {
            print("[ChallengeView] ⚠️ No valid unlock found for countdown")
        }

        // Auto-dismiss when countdown expires
        if remainingSeconds == 0 && phase == .unlocked && !hasAutoDismissed {
            hasAutoDismissed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }

        let mm = remainingSeconds / 60
        let ss = remainingSeconds % 60
        return String(format: "%d:%02d", mm, ss)
    }

    // MARK: - Actions

    private func focusInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch challengeType {
            case .math:
                isMathFocused = true
            case .typing:
                isTypingFocused = true
            case .memory:
                break
            case .breathing:
                break // Breathing starts when user taps the orb
            }
        }
    }

    private func checkMathAnswer() {
        guard let answer = Int(userAnswer),
              let challenge = mathChallenge else {
            return
        }

        if challenge.isCorrect(answer) {
            succeed()
        } else {
            handleError()
        }
    }

    private func checkTypingAnswer() {
        guard let challenge = typingChallenge else { return }

        if challenge.isCorrect(typedText) {
            succeed()
        } else {
            handleError()
        }
    }

    private func checkMemoryAnswer() {
        guard let challenge = memoryChallenge else { return }

        if challenge.isCorrect(selectedTiles) {
            succeed()
        } else {
            handleError()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                memoryChallenge = MemoryChallenge(gridSize: settings.memoryGridSize, litCount: settings.memoryTilesToMatch)
                selectedTiles = []
                showError = false
                memoryStage = .memorize
                startMemoryCountdown()
            }
        }
    }

    private func checkBreathingAnswer() {
        guard let challenge = breathingChallenge else { return }

        // Breathing challenge auto-completes when all breaths are done
        if challenge.isComplete(breathsCompleted: currentBreath) {
            succeed()
        }
    }

    private func succeed() {
        phase = .paying
        showStamp = true

        // Animate tear after stamp (even faster: 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animateTear()

            // Change phase to unlocked AFTER the tear animation completes (0.6s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                phase = .unlocked
                unlockApp()
            }
        }
    }

    private func handleError() {
        attempts += 1
        shakeCount += 1
        showError = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            if challengeType == .math {
                userAnswer = ""
            }
            showError = false
        }
    }

    private func animateTear() {
        // Fare stub tears away - faster with dramatic rotation
        withAnimation(.timingCurve(0.5, 0, 0.7, 0, duration: 0.6)) {
            fareStubOffset = -460
            fareStubRotation = -15  // Much more dramatic rotation for visible tear effect
        }

        // Fade at the end - adjusted timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.linear(duration: 0.3)) {
                fareStubOpacity = 0
            }
        }

        // Pass stub bounce - adjusted timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.15)) {
                passStubOffset = -7
                passStubScale = 1.012
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    passStubOffset = 0
                    passStubScale = 1.0
                }
            }
        }
    }

    private func unlockApp() {
        // For strict mode, execute the protected change immediately
        if isStrictMode {
            onStrictModePass?()
            return
        }

        // Check if this is a category unlock or app unlock
        if let categoryToken = requestedCategory {
            // Unlock the entire category
            blockingManager.temporaryUnlockCategory(categoryToken: categoryToken, duration: settings.unlockDuration)

            let categoryTokenData = try? JSONEncoder().encode(categoryToken)

            let challengeTypeName: String = {
                switch challengeType {
                case .math: return "Math"
                case .typing: return "Typing"
                case .memory: return "Memory"
                case .breathing: return "Breathing"
                }
            }()

            // Record category unlock to history
            historyManager.replaceChallengeStartedWithFarePaid(
                categoryTokenData: categoryTokenData,
                duration: settings.unlockDuration,
                challengeType: challengeTypeName
            )
        } else {
            // Unlock specific app
            let appToken = requestedApp ?? Array(blockingManager.selectedApps.applicationTokens).first
            blockingManager.temporaryUnlock(appToken: appToken, duration: settings.unlockDuration)

            let appTokenData = appToken.flatMap { try? JSONEncoder().encode($0) }

            let challengeTypeName: String = {
                switch challengeType {
                case .math: return "Math"
                case .typing: return "Typing"
                case .memory: return "Memory"
                case .breathing: return "Breathing"
                }
            }()

            // Replace challengeStarted event with farePaid event
            historyManager.replaceChallengeStartedWithFarePaid(
                appTokenData: appTokenData,
                duration: settings.unlockDuration,
                challengeType: challengeTypeName
            )
        }

        // Start countdown - update current time immediately and then every second
        currentTime = Date()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }

        // Clear tokens after unlock to prevent stale data on next challenge
        if let sharedDefaults = UserDefaults.appGroup {
            sharedDefaults.removeObject(forKey: "com.screenfare.requestedAppToken")
            sharedDefaults.removeObject(forKey: "com.screenfare.requestedCategoryToken")
        }
    }

    private func openUnlockedApp() {
        countdownTimer?.invalidate()
    }

    private func startMemoryCountdown() {
        memoryCountdown = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if memoryCountdown > 0 {
                memoryCountdown -= 1
                if memoryCountdown == 0 {
                    timer.invalidate()
                    memoryStage = .recall
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TypingField: View {
    let target: String
    @Binding var typed: String
    var isFocused: FocusState<Bool>.Binding
    let isActive: Bool
    let onComplete: () -> Void
    @State private var shakeCount = 0
    @State private var wrongChar: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Target text with character-by-character coloring
            Text(coloredText)
                .font(.instrumentSerif(26))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(2)
                .modifier(ShakeModifier(trigger: shakeCount))
                .onTapGesture {
                    isFocused.wrappedValue = true
                }

            // Invisible text field with validation
            TextField("", text: Binding(
                get: { typed },
                set: { newValue in
                    if !isActive { return }

                    // Prevent backspace - only allow moving forward
                    if newValue.count < typed.count {
                        return
                    }

                    // Validate each character as it's typed (case sensitive)
                    if newValue.count > typed.count {
                        let startIndex = typed.count
                        let endIndex = min(newValue.count, target.count)

                        var allCorrect = true
                        var firstWrongChar: String? = nil

                        // Check each new character
                        for i in startIndex..<endIndex {
                            let targetChar = Array(target)[i]
                            let typedChar = Array(newValue)[i]

                            if targetChar != typedChar {
                                allCorrect = false
                                firstWrongChar = String(typedChar)
                                break
                            }
                        }

                        if allCorrect && endIndex <= target.count {
                            // All new characters are correct - accept them
                            typed = String(newValue.prefix(endIndex))

                            // Auto-submit if complete
                            if typed.count == target.count {
                                // Hide keyboard
                                isFocused.wrappedValue = false
                                onComplete()
                            }
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
                            // Don't update typed - stay at current position
                        }
                    }
                }
            ), axis: .vertical)
                .focused(isFocused)
                .opacity(0)
                .disabled(!isActive)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
        }
        .frame(minHeight: 100) // Ensure minimum height for multi-line text
    }

    private var coloredText: AttributedString {
        var result = AttributedString()

        for (index, char) in target.enumerated() {
            let isDone = index < typed.count
            let isCorrect = isDone && Array(typed)[index] == char
            let isCursor = index == typed.count && isFocused.wrappedValue && isActive
            let isWrongPosition = index == typed.count && wrongChar != nil

            // Show the wrong character if present
            let displayChar = isWrongPosition && wrongChar != nil ? wrongChar! : String(char)
            var charString = AttributedString(displayChar)

            if isWrongPosition && wrongChar != nil {
                // Wrong character - show in red with background
                charString.foregroundColor = .transitRed
                charString.backgroundColor = .transitRedSoft
            } else if isCorrect {
                charString.foregroundColor = .focusInk
            } else if isCursor {
                // Cursor position - highlight the next character to type
                charString.foregroundColor = .focusInk
                charString.backgroundColor = Color.focusInk.opacity(0.12)
            } else {
                charString.foregroundColor = Color.focusInk.opacity(0.26)
            }

            result.append(charString)
        }

        return result
    }
}

struct MemoryGrid: View {
    let challenge: MemoryChallenge
    @Binding var selectedTiles: [Int]
    let stage: ChallengeView.MemoryStage
    let showError: Bool
    let gridSize: Int
    let isActive: Bool
    let onComplete: () -> Void

    private var radius: CGFloat {
        12
    }

    private var gap: CGFloat {
        9
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: gap), count: gridSize)

        LazyVGrid(columns: columns, spacing: gap) {
            ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                Button {
                    HapticManager.shared.impact()
                    toggleTile(index)
                } label: {
                    Rectangle()
                        .fill(tileColor(index))
                        .overlay(
                            RoundedRectangle(cornerRadius: radius)
                                .strokeBorder(tileBorder(index), lineWidth: 1.5)
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(radius)
                }
                .disabled(stage != .recall || !isActive)
            }
        }
    }

    private func toggleTile(_ index: Int) {
        if selectedTiles.contains(index) {
            selectedTiles.removeAll { $0 == index }
        } else if selectedTiles.count < challenge.litCount {
            selectedTiles.append(index)

            // Auto-submit when all tiles are selected
            if selectedTiles.count == challenge.litCount {
                onComplete()
            }
        }
    }

    private func tileColor(_ index: Int) -> Color {
        let isLit = challenge.litIndices.contains(index)
        let isSelected = selectedTiles.contains(index)

        if stage == .memorize {
            return isLit ? .focusInk : Color.focusInk.opacity(0.05)
        } else {
            if showError && isSelected && !isLit {
                return .transitRedSoft
            } else if isSelected {
                return .focusInk
            } else {
                return Color.focusInk.opacity(0.05)
            }
        }
    }

    private func tileBorder(_ index: Int) -> Color {
        let isLit = challenge.litIndices.contains(index)
        let isSelected = selectedTiles.contains(index)

        if stage == .recall && showError {
            if isSelected && !isLit {
                return .transitRed
            } else if isLit && !isSelected {
                return Color.focusInk.opacity(0.35)
            }
        }

        return .clear
    }
}

// MARK: - Ticket Keypad

struct TicketKeypad: View {
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
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
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

// MARK: - Extensions

extension View {
    func blinking() -> some View {
        self.modifier(BlinkingModifier())
    }
}

struct BlinkingModifier: ViewModifier {
    @State private var isVisible = true

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
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
