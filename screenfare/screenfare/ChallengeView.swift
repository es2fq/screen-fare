//
//  ChallengeView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared

    @State private var challenge: MathChallenge
    @State private var userAnswer = ""
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var isUnlocked = false

    init() {
        let settings = SettingsManager.shared
        _challenge = State(initialValue: MathChallenge(difficulty: settings.challengeDifficulty))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !isUnlocked {
                    // Challenge mode
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.7))

                                Text("Solve to Continue")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text("Complete this challenge to unlock your apps")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)

                            // Math problem
                            VStack(spacing: 20) {
                                Text(challenge.questionText)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                TextField("Your answer", text: $userAnswer)
                                    .font(.system(size: 36, weight: .medium, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .frame(maxWidth: 200)
                            }
                            .padding(.vertical, 20)

                            // Submit button
                            Button {
                                checkAnswer()
                            } label: {
                                Text("Submit")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(userAnswer.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(userAnswer.isEmpty)
                            .padding(.horizontal, 40)

                            if showingResult {
                                HStack(spacing: 8) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(isCorrect ? "Correct!" : "Try again")
                                }
                                .font(.headline)
                                .foregroundColor(isCorrect ? .green : .red)
                                .padding()
                                .background((isCorrect ? Color.green : Color.red).opacity(0.1))
                                .cornerRadius(12)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                } else {
                    // Success mode
                    VStack(spacing: 32) {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)

                            Text("Unlocked!")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Your apps are now accessible for \(settings.unlockDurationText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            Button {
                                dismiss()
                                // Open the blocked app - this will be handled by deep linking
                            } label: {
                                Text("Go to App")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)

                            Button {
                                dismiss()
                            } label: {
                                Text("Stay in ScreenFare")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .animation(.easeInOut, value: showingResult)
            .animation(.easeInOut, value: isUnlocked)
        }
    }

    private func checkAnswer() {
        guard let answer = Int(userAnswer) else {
            return
        }

        isCorrect = challenge.isCorrect(answer)
        showingResult = true

        if isCorrect {
            // Unlock apps
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                blockingManager.temporaryUnlock(duration: settings.unlockDuration)
                isUnlocked = true
            }
        } else {
            // Wrong answer - generate new challenge
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                challenge = MathChallenge(difficulty: settings.challengeDifficulty)
                userAnswer = ""
                showingResult = false
            }
        }
    }
}

#Preview {
    ChallengeView()
}
