//
//  ChallengeTabView.swift
//  screenfare
//
//  Configure challenge type with drill-in pattern
//  Design: challenge-config-patterns.jsx → DrillInChallenge
//

import SwiftUI

struct ChallengeTabView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var view: ViewState = .list
    @State private var selectedType: ChallengeType = .math

    // Pre-generated challenges for preview
    @State private var previewChallenges: [ChallengeDifficulty: MathChallenge]
    @State private var typingChallenge: TypingChallenge
    @State private var memoryChallenge: MemoryChallenge

    enum ViewState {
        case list
        case config
    }

    init() {
        let settings = SettingsManager.shared

        // Pre-generate one challenge for each difficulty level
        var challenges: [ChallengeDifficulty: MathChallenge] = [:]
        for difficulty in ChallengeDifficulty.allCases {
            challenges[difficulty] = MathChallenge(difficulty: difficulty)
        }
        self._previewChallenges = State(initialValue: challenges)
        self._typingChallenge = State(initialValue: TypingChallenge())
        self._memoryChallenge = State(initialValue: MemoryChallenge())
        self._selectedType = State(initialValue: settings.challengeType)
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            // LIST LAYER
            listLayer
                .offset(x: view == .config ? -90 : 0)
                .brightness(view == .config ? -0.03 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: view)

            // CONFIG LAYER
            configLayer
                .offset(x: view == .config ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: view)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: -6, y: 0)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // LIST LAYER
    // ═══════════════════════════════════════════════════════════════

    private var listLayer: some View {
        AppScreen(title: "Challenge") {
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
                AppCard {
                    VStack(spacing: 0) {
                        ForEach(Array(ChallengeType.allCases.enumerated()), id: \.element) { index, type in
                            let isActive = settings.challengeType == type

                            Button(action: {
                                selectedType = type
                                view = .config
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
                                            .font(.inter(12.5))
                                            .foregroundColor(isActive ? .focusInk : .focusMuted)
                                            .fontWeight(isActive ? .medium : .regular)
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

            VStack(spacing: 0) {
                // Back button header
                HStack(spacing: 0) {
                    Button(action: {
                        view = .list
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Challenge")
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

                ScrollView {
                    VStack(spacing: 0) {
                        // Large header with icon + name
                        HStack(spacing: 13) {
                            TypeIcon(type: selectedType, active: true, size: 46)

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

                        // Config card
                        ConfigCard(type: selectedType, settings: settings, previewChallenges: $previewChallenges, typingChallenge: $typingChallenge, memoryChallenge: $memoryChallenge)
                            .padding(.horizontal, 22)

                        // Done button
                        Button(action: {
                            settings.challengeType = selectedType
                            view = .list
                        }) {
                            Text("Done")
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.focusInk)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                        .padding(.bottom, 24)
                    }
                }
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
        }
    }

    private func summaryText(for type: ChallengeType) -> String {
        switch type {
        case .math:
            return difficultyLabel(for: settings.challengeDifficulty)
        case .typing:
            return "8 words"
        case .memory:
            return "4 tiles"
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
                .fill(active ? Color.focusInk : Color.focusInk.opacity(0.06))
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.37))
                .foregroundColor(active ? .white : .focusInk)
        }
    }

    private var iconName: String {
        switch type {
        case .math: return "plus.forwardslash.minus"
        case .typing: return "textformat"
        case .memory: return "grid"
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
                }
            }
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
                    get: { Double(ChallengeDifficulty.allCases.firstIndex(of: settings.challengeDifficulty) ?? 2) },
                    set: { settings.challengeDifficulty = ChallengeDifficulty.allCases[Int($0)] }
                ),
                range: 0...4,
                step: 1
            )

            HStack {
                Text("Very easy")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("Very hard")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
            }
            .padding(.top, 4)

            PreviewBox(label: "Sample problem") {
                if let challenge = previewChallenges[settings.challengeDifficulty] {
                    Text(challenge.questionText)
                        .font(.instrumentSerif(27))
                        .foregroundColor(.focusInk)
                        .monospacedDigit()
                }
            }
        }
    }

    private var typingConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Phrase length")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("8 words")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(value: .constant(8), range: 5...16, step: 1)

            HStack {
                Text("5 words")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("16 words")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
            }
            .padding(.top, 4)

            PreviewBox(label: "Preview") {
                Text("\"I'll use this on purpose, not by reflex.\"")
                    .font(.instrumentSerif(16, italic: true))
                    .foregroundColor(Color.focusInk)
                    .lineSpacing(1.3)
            }
        }
    }

    private var memoryConfig: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tiles to match")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("4 tiles")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(.focusInk)
            }

            CustomSlider(value: .constant(4), range: 3...6, step: 1)

            HStack {
                Text("3")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
                Spacer()
                Text("6 tiles")
                    .font(.inter(11))
                    .foregroundColor(.focusMuted)
            }
            .padding(.top, 4)

            PreviewBox(label: "Preview") {
                Text("Memorize the lit tiles, then tap them back from memory.")
                    .font(.instrumentSerif(16, italic: true))
                    .foregroundColor(Color.focusInk)
                    .lineSpacing(1.3)
            }
        }
    }

    private var difficultyLabel: String {
        switch settings.challengeDifficulty {
        case .veryEasy: return "Very easy"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very hard"
        }
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

struct AccessWindowCard: View {
    @Binding var duration: TimeInterval

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
                    range: 60...7200,
                    step: 60
                )

                HStack {
                    Text("1 min")
                        .font(.inter(11))
                        .foregroundColor(.focusMuted)
                    Spacer()
                    Text("2 hours")
                        .font(.inter(11))
                        .foregroundColor(.focusMuted)
                }
                .padding(.top, 4)
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

#Preview {
    ChallengeTabView()
}
