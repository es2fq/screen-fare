//
//  ChallengeTabView.swift
//  screenfare
//
//  Configure challenge type, difficulty, and access window
//

import SwiftUI

struct ChallengeTabView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var previewChallenge: MathChallenge

    init() {
        let settings = SettingsManager.shared
        _previewChallenge = State(initialValue: MathChallenge(difficulty: settings.challengeDifficulty))
    }

    var body: some View {
        AppScreen(title: "Challenge") {
            VStack(spacing: 18) {
                // Preview card
                AppCard(padding: EdgeInsets(top: 24, leading: 22, bottom: 24, trailing: 22)) {
                    VStack(spacing: 18) {
                        Text("PREVIEW")
                            .font(.inter(11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(11 * 0.12)

                        Text(previewChallenge.questionText)
                            .font(.instrumentSerif(44))
                            .foregroundColor(.white)
                            .lineSpacing(0)
                            .monospacedDigit()

                        // Mock input field
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .frame(height: 52)
                            .overlay(
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { _ in
                                        Circle()
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.focusInk)
                )

                // Difficulty section
                SectionTitle(text: "Difficulty")

                AppCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Difficulty")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Spacer()

                            Text(difficultyLabel(for: settings.challengeDifficulty))
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.focusInk)
                        }

                        // Difficulty slider
                        VStack(spacing: 10) {
                            Slider(
                                value: Binding(
                                    get: { Double(ChallengeDifficulty.allCases.firstIndex(of: settings.challengeDifficulty) ?? 2) },
                                    set: { settings.challengeDifficulty = ChallengeDifficulty.allCases[Int($0)] }
                                ),
                                in: 0...4,
                                step: 1
                            )
                            .tint(Color.focusInk)
                            .onChange(of: settings.challengeDifficulty) { _, _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    previewChallenge = MathChallenge(difficulty: settings.challengeDifficulty)
                                }
                            }

                            // Tick marks
                            HStack {
                                ForEach(0..<5) { index in
                                    let currentIndex = ChallengeDifficulty.allCases.firstIndex(of: settings.challengeDifficulty) ?? 2
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index <= currentIndex ? Color.focusInk : Color.focusInk.opacity(0.2))
                                        .frame(width: 4, height: 4)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            // Labels
                            HStack {
                                Text("Very easy")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                                Spacer()
                                Text("Very hard")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                            }
                        }
                    }
                }

                // Access window section
                SectionTitle(text: "Access window")

                AppCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Duration")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Spacer()

                            Text(durationFormatted)
                                .font(.inter(15, weight: .semibold))
                                .foregroundColor(.focusInk)
                                .monospacedDigit()
                        }

                        // Duration slider
                        VStack(spacing: 6) {
                            Slider(
                                value: $settings.unlockDuration,
                                in: 60...7200,
                                step: 60
                            )
                            .tint(Color.focusInk)

                            HStack {
                                Text("1 min")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                                Spacer()
                                Text("2 hours")
                                    .font(.inter(11))
                                    .foregroundColor(.focusMuted)
                            }
                        }

                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([2, 5, 15, 30, 60], id: \.self) { preset in
                                let isSelected = Int(settings.unlockDuration / 60) == preset
                                Button(action: {
                                    settings.unlockDuration = TimeInterval(preset * 60)
                                }) {
                                    Text(preset < 60 ? "\(preset)m" : "\(preset/60)h")
                                        .font(.inter(13, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .focusInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.focusInk : Color.focusLine, lineWidth: 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(isSelected ? Color.focusInk : Color.focusCard)
                                                )
                                        )
                                }
                            }
                        }
                    }
                }
            }
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

    private var durationFormatted: String {
        let minutes = Int(settings.unlockDuration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hours"
        }
    }
}

#Preview {
    ChallengeTabView()
}
