//
//  SettingsView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var blockingManager = AppBlockingManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Unlock Duration Section
                Section {
                    ForEach(UnlockDurationOption.allCases) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settings.unlockDuration = option.duration
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.displayName)
                                        .foregroundColor(.primary)
                                        .fontWeight(settings.unlockDuration == option.duration ? .semibold : .regular)

                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if settings.unlockDuration == option.duration {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Unlock Duration")
                } footer: {
                    Text("Choose how long apps stay unlocked after completing a challenge")
                }

                // Challenge Difficulty Section
                Section {
                    ForEach(ChallengeDifficulty.allCases, id: \.self) { difficulty in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settings.challengeDifficulty = difficulty
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(difficulty.rawValue)
                                        .foregroundColor(.primary)
                                        .fontWeight(settings.challengeDifficulty == difficulty ? .semibold : .regular)

                                    Text(difficultyDescription(for: difficulty))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if settings.challengeDifficulty == difficulty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Challenge Difficulty")
                } footer: {
                    Text("Adjust the difficulty of math problems")
                }

                // Current Status Section
                if blockingManager.isCurrentlyUnlocked(), let remaining = blockingManager.remainingUnlockTime() {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.open.fill")
                                    .foregroundColor(.green)
                                Text("Apps Currently Unlocked")
                                    .fontWeight(.semibold)
                            }

                            Text("Time remaining: \(formatTime(remaining))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Status")
                    }
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func difficultyDescription(for difficulty: ChallengeDifficulty) -> String {
        switch difficulty {
        case .veryEasy: return "Numbers 1-10, addition & subtraction only"
        case .easy: return "Numbers 1-20, addition & subtraction only"
        case .medium: return "Numbers 10-50, all operations"
        case .hard: return "Numbers 20-100, all operations"
        case .veryHard: return "Numbers 50-200, all operations"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    SettingsView()
}
