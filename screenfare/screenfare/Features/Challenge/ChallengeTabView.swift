//
//  ChallengeTabView.swift
//  Screen Fare
//
//  Configure challenge type with drill-in pattern
//  Design: challenge-config-patterns.jsx → DrillInChallenge
//

import SwiftUI

struct ChallengeTabView: View {
    @StateObject private var settings = SettingsManager.shared
    @Binding var selectedTab: Int
    @Binding var viewState: ChallengeViewState
    @Binding var selectedType: ChallengeType
    @State private var dragOffset: CGFloat = 0
    @FocusState private var isAnyFieldFocused: Bool
    @State private var configViewCount = 0 // Track config view appearances

    // Temporary difficulty settings (only saved when user presses Select/Done)
    @State private var tempChallengeDifficulty: ChallengeDifficulty
    @State private var tempTypingDifficulty: TypingDifficulty
    @State private var tempMemoryGridSize: Int
    @State private var tempMemoryTilesToMatch: Int
    @State private var tempBreathingCycles: Int

    // Challenge gate for strict mode
    @State private var showGate: ChallengeGateData?

    // Pre-generated challenges for preview
    @State private var previewChallenges: [ChallengeDifficulty: MathChallenge]
    @State private var typingChallenge: TypingChallenge
    @State private var memoryChallenge: MemoryChallenge
    @State private var breathingChallenge: BreathingChallenge

    init(selectedTab: Binding<Int> = .constant(2), viewState: Binding<ChallengeViewState> = .constant(.list), selectedType: Binding<ChallengeType> = .constant(.math)) {
        _selectedTab = selectedTab
        _viewState = viewState
        _selectedType = selectedType
        let settings = SettingsManager.shared

        // Initialize temp difficulty settings from current settings
        self._tempChallengeDifficulty = State(initialValue: settings.challengeDifficulty)
        self._tempTypingDifficulty = State(initialValue: settings.typingDifficulty)
        self._tempMemoryGridSize = State(initialValue: settings.memoryGridSize)
        self._tempMemoryTilesToMatch = State(initialValue: settings.memoryTilesToMatch)
        self._tempBreathingCycles = State(initialValue: settings.breathingCycles)

        // Pre-generate one challenge for each difficulty level
        var challenges: [ChallengeDifficulty: MathChallenge] = [:]
        for difficulty in ChallengeDifficulty.allCases {
            challenges[difficulty] = MathChallenge(difficulty: difficulty)
        }
        self._previewChallenges = State(initialValue: challenges)
        self._typingChallenge = State(initialValue: TypingChallenge(difficulty: settings.typingDifficulty))
        self._memoryChallenge = State(initialValue: MemoryChallenge())
        self._breathingChallenge = State(initialValue: BreathingChallenge(totalBreaths: settings.breathingCycles))
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            // LIST LAYER
            listLayer
                .offset(x: viewState == .config ? -90 : 0)
                .brightness(viewState == .config ? -0.03 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: viewState)
                .animation(nil, value: dragOffset) // Don't animate background during drag

            // CONFIG LAYER
            configLayer
                .offset(x: viewState == .config ? dragOffset : UIScreen.main.bounds.width)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: -6, y: 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: viewState)
                .animation(.interactiveSpring(), value: dragOffset)
                .swipeBackGesture(isActive: viewState == .config, dragOffset: $dragOffset, onDismiss: {
                    isAnyFieldFocused = false
                    viewState = .list
                })
        }
        .sheet(item: $showGate) { data in
            ChallengeGate(
                data: data,
                difficulty: settings.challengeDifficulty.numericLevel
            )
            .presentationBackground(.clear)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SAVE LOGIC
    // ═══════════════════════════════════════════════════════════════

    private func handleSaveChanges() {
        // Check if any changes were made
        let hasChanges = (selectedType != settings.challengeType) ||
                         (tempChallengeDifficulty != settings.challengeDifficulty) ||
                         (tempTypingDifficulty != settings.typingDifficulty) ||
                         (tempMemoryGridSize != settings.memoryGridSize) ||
                         (tempMemoryTilesToMatch != settings.memoryTilesToMatch) ||
                         (tempBreathingCycles != settings.breathingCycles)

        // If strict mode is on and challenge protection is enabled, show gate
        if hasChanges && settings.strictModeEnabled && settings.strictProtectChallenge {
            showGate = ChallengeGateData(
                title: "Change challenge settings",
                onPass: {
                    commitChanges()
                }
            )
        } else {
            // No protection needed, save directly
            commitChanges()
        }
    }

    private func commitChanges() {
        // Save all temp settings to actual settings
        settings.challengeType = selectedType
        settings.challengeDifficulty = tempChallengeDifficulty
        settings.typingDifficulty = tempTypingDifficulty
        settings.memoryGridSize = tempMemoryGridSize
        settings.memoryTilesToMatch = tempMemoryTilesToMatch
        settings.breathingCycles = tempBreathingCycles

        // Return to list view
        viewState = .list
    }

    // ═══════════════════════════════════════════════════════════════
    // LIST LAYER
    // ═══════════════════════════════════════════════════════════════

    private var listLayer: some View {
        AppScreen(title: "Fare") {
            VStack(spacing: 0) {
                // Description
                Text("Choose what stands between you and a blocked app. Tap to set it up.")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 18)

                // Challenge type list
                AppCard(padding: EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) {
                    VStack(spacing: 0) {
                        ForEach(Array(ChallengeType.allCases.enumerated()), id: \.element) { index, type in
                            let isActive = settings.challengeType == type

                            Button(action: {
                                selectedType = type
                                // Load current settings into temp variables when entering config
                                tempChallengeDifficulty = settings.challengeDifficulty
                                tempTypingDifficulty = settings.typingDifficulty
                                tempMemoryGridSize = settings.memoryGridSize
                                tempMemoryTilesToMatch = settings.memoryTilesToMatch
                                viewState = .config
                                configViewCount += 1 // Increment to reset testers
                            }) {
                                HStack(spacing: 13) {
                                    // Icon
                                    TypeIcon(type: type, active: isActive)

                                    // Name + summary/description
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(type.rawValue)
                                                .font(.inter(15, weight: .medium))
                                                .foregroundColor(.focusInk)

                                            if type.isPro {
                                                ProTag()
                                            }
                                        }

                                        Text(isActive ? summaryText(for: type) : descriptionFor(type))
                                            .font(.inter(12.5, weight: isActive ? .medium : .regular))
                                            .foregroundColor(isActive ? .focusInk : .focusMuted)
                                    }

                                    Spacer()

                                    // Active indicator
                                    if isActive {
                                        Text("ACTIVE")
                                            .font(.inter(10, weight: .bold))
                                            .foregroundColor(.focusInk)
                                            .tracking(0.5)
                                    }

                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.focusMuted)
                                }
                                .padding(.vertical, 13)
                            }

                            if index < ChallengeType.allCases.count - 1 {
                                Divider().background(Color.focusLine)
                            }
                        }
                    }
                }

                // Access window section
                SectionTitle(text: "Access window")
                    .padding(.top, 4)

                AccessWindowCard(duration: $settings.unlockDuration)

                Text("Applies to every challenge.")
                    .font(.inter(11.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(1.5)
                    .padding(.horizontal, 4)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CONFIG LAYER
    // ═══════════════════════════════════════════════════════════════

    private var configLayer: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    isAnyFieldFocused = false
                }

            VStack(spacing: 0) {
                // Back button header
                HStack(spacing: 0) {
                    Button(action: {
                        isAnyFieldFocused = false
                        viewState = .list
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Fare")
                                .font(.inter(17, weight: .medium))
                        }
                        .foregroundColor(.focusInk)
                        .padding(.vertical, 10)
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping header area
                    isAnyFieldFocused = false
                }

                ScrollView {
                    VStack(spacing: 0) {
                        // Large header with icon + name
                        HStack(spacing: 13) {
                            TypeIcon(type: selectedType, active: settings.challengeType == selectedType, size: 46)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(selectedType.rawValue)
                                        .font(.instrumentSerif(26))
                                        .foregroundColor(.focusInk)

                                    if selectedType.isPro {
                                        ProTag()
                                    }
                                }

                                Text(descriptionFor(selectedType))
                                    .font(.inter(12.5))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Dismiss keyboard when tapping header
                            isAnyFieldFocused = false
                        }

                        // Config card
                        ConfigCard(
                            type: selectedType,
                            settings: settings,
                            previewChallenges: $previewChallenges,
                            typingChallenge: $typingChallenge,
                            memoryChallenge: $memoryChallenge,
                            breathingChallenge: $breathingChallenge,
                            isAnyFieldFocused: $isAnyFieldFocused,
                            configViewCount: configViewCount,
                            tempChallengeDifficulty: $tempChallengeDifficulty,
                            tempTypingDifficulty: $tempTypingDifficulty,
                            tempMemoryGridSize: $tempMemoryGridSize,
                            tempMemoryTilesToMatch: $tempMemoryTilesToMatch,
                            tempBreathingCycles: $tempBreathingCycles
                        )
                        .padding(.horizontal, 22)

                        // Select/Done button
                        Button(action: {
                            isAnyFieldFocused = false
                            handleSaveChanges()
                        }) {
                            Text(selectedType == settings.challengeType ? "Done" : "Select")
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.focusInk)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                        .padding(.bottom, 100)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping scroll area
                        isAnyFieldFocused = false
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════

    private func descriptionFor(_ type: ChallengeType) -> String {
        switch type {
        case .math: return "Solve math problems"
        case .typing: return "Type the prompt exactly"
        case .memory: return "Remember the pattern"
        case .breathing: return "Complete breathing cycles"
        }
    }

    private func summaryText(for type: ChallengeType) -> String {
        switch type {
        case .math:
            return difficultyLabel(for: settings.challengeDifficulty)
        case .typing:
            return typingDifficultyLabel(for: settings.typingDifficulty)
        case .memory:
            return "\(settings.memoryGridSize)×\(settings.memoryGridSize) grid"
        case .breathing:
            let cycles = settings.breathingCycles
            return "\(cycles) breath\(cycles == 1 ? "" : "s")"
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

    private func typingDifficultyLabel(for difficulty: TypingDifficulty) -> String {
        switch difficulty {
        case .shortest: return "Shortest"
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        case .longest: return "Longest"
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════

struct TypeIcon: View {
    let type: ChallengeType
    let active: Bool
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(active ? Color.focusAccent : Color.focusInk.opacity(0.06))
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.37))
                .foregroundColor(active ? .white : .focusInk)
        }
    }

    private var iconName: String {
        switch type {
        case .math: return "plus.forwardslash.minus"
        case .typing: return "keyboard"
        case .memory: return "brain.head.profile"
        case .breathing: return "wind"
        }
    }
}

struct ProTag: View {
    var body: some View {
        Text("PRO")
            .font(.inter(8.5, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(Color.focusInk)
            .cornerRadius(5)
            .tracking(0.09 * 8.5)
    }
}

struct ConfigCard: View {
    let type: ChallengeType
    @ObservedObject var settings: SettingsManager
    @Binding var previewChallenges: [ChallengeDifficulty: MathChallenge]
    @Binding var typingChallenge: TypingChallenge
    @Binding var memoryChallenge: MemoryChallenge
    @Binding var breathingChallenge: BreathingChallenge
    @FocusState.Binding var isAnyFieldFocused: Bool
    let configViewCount: Int
    @Binding var tempChallengeDifficulty: ChallengeDifficulty
    @Binding var tempTypingDifficulty: TypingDifficulty
    @Binding var tempMemoryGridSize: Int
    @Binding var tempMemoryTilesToMatch: Int
    @Binding var tempBreathingCycles: Int

    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                switch type {
                case .math:
                    mathConfig
                case .typing:
                    typingConfig
                case .memory:
                    memoryConfig
                case .breathing:
                    breathingConfig
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping card padding/background
            isAnyFieldFocused = false
        }
    }

    private var mathConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Difficulty")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text(difficultyLabel)
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(
                value: Binding(
                    get: { Double(ChallengeDifficulty.allCases.firstIndex(of: tempChallengeDifficulty) ?? 2) },
                    set: { tempChallengeDifficulty = ChallengeDifficulty.allCases[Int($0)] }
                ),
                range: 0...4,
                step: 1
            )

            MathTester(difficulty: tempChallengeDifficulty)
                .id("\(tempChallengeDifficulty.rawValue)-\(configViewCount)")
        }
    }

    private var typingConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Phrase length")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text(typingDifficultyLabel)
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(
                value: Binding(
                    get: { Double(TypingDifficulty.allCases.firstIndex(of: tempTypingDifficulty) ?? 2) },
                    set: {
                        tempTypingDifficulty = TypingDifficulty.allCases[Int($0)]
                        // Regenerate typing challenge with new difficulty
                        typingChallenge = TypingChallenge(difficulty: tempTypingDifficulty)
                    }
                ),
                range: 0...4,
                step: 1
            )

            TypingTester(difficulty: tempTypingDifficulty, isAnyFieldFocused: $isAnyFieldFocused)
                .id("\(tempTypingDifficulty.rawValue)-\(configViewCount)")
        }
    }

    private var memoryConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Grid size")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text(memoryDifficultyLabel)
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(
                value: Binding(
                    get: { Double(tempMemoryGridSize) },
                    set: { newValue in
                        let gridSize = Int(newValue)
                        tempMemoryGridSize = gridSize

                        // Set tiles to match based on grid size
                        // Keep it challenging but achievable
                        tempMemoryTilesToMatch = min(gridSize + 1, gridSize * gridSize)

                        // Regenerate memory challenge
                        memoryChallenge = MemoryChallenge(gridSize: tempMemoryGridSize, litCount: tempMemoryTilesToMatch)
                    }
                ),
                range: 3...7,
                step: 1
            )

            MemoryTester(gridSize: tempMemoryGridSize, tilesToMatch: tempMemoryTilesToMatch)
                .id("\(tempMemoryGridSize)-\(tempMemoryTilesToMatch)-\(configViewCount)") // Reset when settings change or when re-entering config
        }
    }

    private var breathingConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Breathing cycles")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("\(tempBreathingCycles) breath\(tempBreathingCycles == 1 ? "" : "s")")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(
                value: Binding(
                    get: { Double(tempBreathingCycles) },
                    set: { newValue in
                        tempBreathingCycles = Int(newValue)
                        // Regenerate breathing challenge
                        breathingChallenge = BreathingChallenge(totalBreaths: tempBreathingCycles)
                    }
                ),
                range: 1...5,
                step: 1
            )

            BreathingTester(challenge: breathingChallenge)
                .id("\(tempBreathingCycles)-\(configViewCount)")
        }
    }

    private var difficultyLabel: String {
        switch tempChallengeDifficulty {
        case .veryEasy: return "Very easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very hard"
        }
    }

    private var typingDifficultyLabel: String {
        switch tempTypingDifficulty {
        case .shortest: return "Shortest"
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        case .longest: return "Longest"
        }
    }

    private var memoryDifficultyLabel: String {
        let gridSize = tempMemoryGridSize
        return "\(gridSize)×\(gridSize)"
    }
}

struct PreviewBox<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.inter(9.5, weight: .medium))
                .foregroundColor(.focusMuted)
                .tracking(0.7)

            content
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.focusInk.opacity(0.04))
        .cornerRadius(12)
        .padding(.top, 2)
    }
}

// ═══════════════════════════════════════════════════════════════
// INTERACTIVE CHALLENGE TESTERS
// ═══════════════════════════════════════════════════════════════

struct TryShell<Content: View>: View {
    @ViewBuilder let content: Content
    let hint: String?

    init(hint: String? = nil, @ViewBuilder content: () -> Content) {
        self.hint = hint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("TRY IT")
                .font(.inter(9.5, weight: .medium))
                .foregroundColor(.focusMuted)
                .tracking(0.7)

            content

            if let hint = hint {
                Text(hint)
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(1.45)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.focusInk.opacity(0.04))
        .cornerRadius(12)
        .padding(.top, 14)
    }
}

struct MathTester: View {
    let difficulty: ChallengeDifficulty
    @State private var problem: MathChallenge
    @State private var userAnswer = ""
    @State private var result: MathChallengeResult? = nil
    @FocusState private var isFocused: Bool

    init(difficulty: ChallengeDifficulty) {
        self.difficulty = difficulty
        self._problem = State(initialValue: MathChallenge(difficulty: difficulty))
    }

    var body: some View {
        TryShell(hint: "Solve it the way you would to unlock — answers are checked.") {
            // Use shared math challenge field component
            MathChallengeField(
                questionText: problem.questionText,
                userAnswer: $userAnswer,
                result: $result,
                isFocused: $isFocused,
                onSubmit: handleAction
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping anywhere in the shell
            isFocused = false
        }
        .onChange(of: difficulty) { _, newDifficulty in
            problem = MathChallenge(difficulty: newDifficulty)
            userAnswer = ""
            result = nil
        }
    }

    private func handleAction() {
        if result == .correct {
            // Generate new problem
            problem = MathChallenge(difficulty: difficulty)
            userAnswer = ""
            result = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        } else {
            // Check answer
            guard let answer = Int(userAnswer) else { return }
            result = problem.isCorrect(answer) ? .correct : .wrong
        }
    }
}

struct TypingTester: View {
    let difficulty: TypingDifficulty
    @FocusState.Binding var isAnyFieldFocused: Bool
    @State private var typedText = ""
    @State private var challenge: TypingChallenge

    init(difficulty: TypingDifficulty, isAnyFieldFocused: FocusState<Bool>.Binding) {
        self.difficulty = difficulty
        self._isAnyFieldFocused = isAnyFieldFocused
        self._challenge = State(initialValue: TypingChallenge(difficulty: difficulty))
    }

    private var isComplete: Bool {
        typedText == challenge.targetText
    }

    var body: some View {
        TryShell(hint: isComplete ? nil : "Tap the line and type it exactly.") {
            VStack(spacing: 10) {
                // Use shared typing challenge field component
                TypingChallengeField(
                    targetText: challenge.targetText,
                    typedText: $typedText,
                    isFocused: $isAnyFieldFocused
                )

                if isComplete {
                    Text("Matched — that would unlock.")
                        .font(.inter(12.5, weight: .medium))
                        .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.4))
                }
            }
        }
        .onChange(of: difficulty) { _, newDifficulty in
            // Reset typing state and generate new challenge when difficulty changes
            challenge = TypingChallenge(difficulty: newDifficulty)
            typedText = ""
        }
    }
}

struct MemoryTester: View {
    let gridSize: Int  // e.g., 3 for 3x3, 4 for 4x4
    let tilesToMatch: Int
    @State private var targetTiles: [Int] = []
    @State private var selectedTiles: [Int] = []
    @State private var stage: Stage = .idle
    @State private var countdown: Int = 3

    enum Stage {
        case idle
        case memorize
        case recall
        case done
        case wrong
    }

    private var totalTiles: Int {
        gridSize * gridSize
    }

    var body: some View {
        TryShell(hint: stage == .idle ? "Memorize the lit tiles, then tap them back from memory." : nil) {
            VStack(spacing: 12) {
                // Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize), spacing: 8) {
                    ForEach(0..<totalTiles, id: \.self) { index in
                        Button(action: {
                            if stage == .recall {
                                toggleTile(index)
                            }
                        }) {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(tileColor(for: index))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .strokeBorder(tileBorder(for: index), lineWidth: 1.5)
                                )
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .disabled(stage != .recall)
                    }
                }

                // Button
                Button(action: handleAction) {
                    Text(buttonText)
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(buttonDisabled ? Color.focusInk.opacity(0.3) : Color.focusInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(buttonDisabled ? Color.focusLine.opacity(0.5) : Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(11)
                }
                .disabled(buttonDisabled)
            }
        }
    }

    private func tileColor(for index: Int) -> Color {
        let isTarget = targetTiles.contains(index)
        let isSelected = selectedTiles.contains(index)

        switch stage {
        case .idle:
            return Color.focusInk.opacity(0.06)
        case .memorize:
            return isTarget ? Color.focusInk : Color.focusInk.opacity(0.06)
        case .recall:
            return isSelected ? Color.focusInk : Color.focusInk.opacity(0.06)
        case .wrong:
            // Show discrepancy: wrong selections in red, correct answers highlighted
            if isSelected && !isTarget {
                return .transitRedSoft
            } else if isTarget {
                return Color.focusInk
            } else {
                return Color.focusInk.opacity(0.06)
            }
        case .done:
            return isTarget ? Color(red: 0.55, green: 0.65, blue: 0.4) : Color.focusInk.opacity(0.06)
        }
    }

    private func tileBorder(for index: Int) -> Color {
        let isTarget = targetTiles.contains(index)
        let isSelected = selectedTiles.contains(index)

        if stage == .wrong {
            if isSelected && !isTarget {
                return .transitRed
            }
        }
        return .clear
    }

    private var buttonText: String {
        switch stage {
        case .idle:
            return "Start"
        case .memorize:
            return "Memorizing… \(countdown)"
        case .recall:
            return "\(selectedTiles.count)/\(tilesToMatch)"
        case .wrong:
            return "Again"
        case .done:
            return "Again"
        }
    }

    private var buttonDisabled: Bool {
        stage == .memorize || stage == .recall
    }

    private func toggleTile(_ index: Int) {
        if selectedTiles.contains(index) {
            selectedTiles.removeAll { $0 == index }
        } else if selectedTiles.count < tilesToMatch {
            selectedTiles.append(index)

            // Auto-submit when all tiles are selected
            if selectedTiles.count == tilesToMatch {
                checkAnswer()
            }
        }
    }

    private func handleAction() {
        switch stage {
        case .idle, .done, .wrong:
            startGame()
        case .recall:
            // No manual check needed - auto-submits on tile selection
            break
        default:
            break
        }
    }

    private func startGame() {
        // Generate random target tiles
        var allIndices = Array(0..<totalTiles)
        allIndices.shuffle()
        targetTiles = Array(allIndices.prefix(tilesToMatch)).sorted()
        selectedTiles = []

        // Start memorization phase with 3-second countdown (same as actual challenge)
        stage = .memorize
        countdown = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
                if countdown == 0 {
                    timer.invalidate()
                    stage = .recall
                }
            }
        }
    }

    private func checkAnswer() {
        let isCorrect = Set(selectedTiles) == Set(targetTiles)

        if isCorrect {
            stage = .done
        } else {
            stage = .wrong
            // Stay on wrong state until user clicks "Try again"
        }
    }
}

struct AccessWindowCard: View {
    @Binding var duration: TimeInterval

    private var selectedMinutes: Int {
        Int(duration / 60)
    }

    var body: some View {
        AppCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Unlock duration")
                        .font(.inter(13))
                        .foregroundColor(.focusMuted)
                    Spacer()
                    Text(formattedDuration)
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(.focusInk)
                        .monospacedDigit()
                }

                CustomSlider(
                    value: $duration,
                    range: 60...3600,
                    step: 60
                )

                HStack {
                    Text("1 min")
                        .font(.inter(11))
                        .foregroundColor(.focusMuted)
                    Spacer()
                    Text("1 hour")
                        .font(.inter(11))
                        .foregroundColor(.focusMuted)
                }
                .padding(.top, 4)

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([5, 15, 30, 45, 60], id: \.self) { preset in
                        Button(action: {
                            duration = TimeInterval(preset * 60)
                        }) {
                            Text(preset < 60 ? "\(preset)m" : "\(preset/60)h")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(selectedMinutes == preset ? .white : .focusInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedMinutes == preset ? Color.focusInk : Color.focusLine, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedMinutes == preset ? Color.focusInk : Color.focusCard)
                                        )
                                )
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    private var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            }
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Breathing Tester

struct BreathingTester: View {
    let challenge: BreathingChallenge
    @State private var currentBreath: Int = 0
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var phaseProgress: Double = 0
    @State private var isAnimating: Bool = false
    @State private var stage: Stage = .idle

    enum Stage {
        case idle
        case breathing
        case done
    }

    var body: some View {
        TryShell(hint: stage == .idle ? "Follow the animated orb through \(challenge.totalBreaths) breath cycle\(challenge.totalBreaths == 1 ? "" : "s")." : nil) {
            VStack(spacing: 12) {
                // Breathing instructions and orb
                if stage == .breathing {
                    VStack(spacing: 4) {
                        Text(currentPhase.label)
                            .font(.instrumentSerif(24))
                            .foregroundColor(Color(red: 0.46, green: 0.52, blue: 0.49))
                            .transition(.opacity)
                            .id(currentPhase)

                        Text("\(phaseCountdown)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .tracking(0.52)
                            .foregroundColor(Color(red: 0.66, green: 0.74, blue: 0.70))
                            .monospacedDigit()
                    }
                    .frame(height: 50)
                }

                // Breathing orb preview (smaller version)
                BreathingOrbView(
                    challenge: challenge,
                    currentBreath: $currentBreath,
                    currentPhase: $currentPhase,
                    phaseProgress: $phaseProgress,
                    isAnimating: $isAnimating,
                    onComplete: handleComplete
                )
                .scaleEffect(0.7)
                .frame(height: stage == .breathing ? 210 : 240)

                // Breath count dots
                HStack(spacing: 9) {
                    ForEach(1...challenge.totalBreaths, id: \.self) { breathNum in
                        Circle()
                            .fill(breathNum <= currentBreath - 1 ? Color(red: 0.46, green: 0.52, blue: 0.49) : (breathNum == currentBreath ? Color(red: 0.46, green: 0.52, blue: 0.49).opacity(0.55) : Color.focusInk.opacity(0.13)))
                            .frame(width: 7, height: 7)
                            .scaleEffect(breathNum == currentBreath ? 1.35 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentBreath)
                    }
                }
                .frame(height: 20)

                // Button
                Button(action: handleAction) {
                    Text(buttonText)
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(buttonDisabled ? Color.focusInk.opacity(0.3) : Color.focusInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(buttonDisabled ? Color.focusLine.opacity(0.5) : Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(11)
                }
                .disabled(buttonDisabled)
            }
        }
    }

    private var phaseCountdown: Int {
        let phaseDuration: TimeInterval
        switch currentPhase {
        case .inhale:
            phaseDuration = challenge.inhaleDuration
        case .hold:
            phaseDuration = challenge.holdDuration
        case .exhale:
            phaseDuration = challenge.exhaleDuration
        }

        let elapsed = phaseProgress * phaseDuration
        return max(1, Int(ceil(phaseDuration - elapsed)))
    }

    private var buttonText: String {
        switch stage {
        case .idle:
            return "Start"
        case .breathing:
            return "Breathing..."
        case .done:
            return "Done · Try again"
        }
    }

    private var buttonDisabled: Bool {
        stage == .breathing
    }

    private func handleAction() {
        switch stage {
        case .idle:
            startBreathing()
        case .breathing:
            break
        case .done:
            resetBreathing()
        }
    }

    private func startBreathing() {
        stage = .breathing
        currentBreath = 0
        isAnimating = true
    }

    private func handleComplete() {
        stage = .done
        isAnimating = false
    }

    private func resetBreathing() {
        stage = .idle
        currentBreath = 0
        currentPhase = .inhale
        phaseProgress = 0
        isAnimating = false
    }
}

#Preview {
    ChallengeTabView()
}
