//
//  SettingsModals.swift
//  screenfare
//
//  Modal overlays for Settings: Toast, ChallengeGate, ConfirmDialog
//

import SwiftUI

// MARK: - Toast Notification

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

struct SettingsToast: View {
    let toast: ToastData?

    var body: some View {
        if let toast = toast {
            VStack {
                Spacer()

                Text(toast.message)
                    .font(.inter(13.5, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(Color.focusInk)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.26), radius: 13, x: 0, y: 8)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 34)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast.id)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Challenge Gate Modal

struct MathProblem {
    let question: String
    let answer: Int
}

struct ChallengeGateData: Identifiable {
    let id = UUID()
    let title: String
    let onPass: () -> Void
}

struct ChallengeGate: View {
    let data: ChallengeGateData
    let difficulty: Int
    @Environment(\.dismiss) var dismiss

    @State private var problem: MathProblem
    @State private var userAnswer = ""
    @State private var isShaking = false
    @FocusState private var isInputFocused: Bool

    init(data: ChallengeGateData, difficulty: Int = 3) {
        self.data = data
        self.difficulty = difficulty
        _problem = State(initialValue: ChallengeGate.makeProblem(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.5))
                .onTapGesture {
                    dismiss()
                }

            VStack {
                Spacer()

                // Challenge card
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.focusInk)
                                .frame(width: 30, height: 30)

                            LockMini(color: .white)
                        }

                        Text("STRICT MODE · PAY YOUR FARE")
                            .font(.inter(11, weight: .semibold))
                            .foregroundColor(.focusMuted)
                            .kerning(0.8)
                    }
                    .padding(.bottom, 14)

                    // Title
                    HStack(spacing: 0) {
                        Text(data.title)
                            .font(.instrumentSerif(25))
                            .foregroundColor(.focusInk)

                        Text(".")
                            .font(.instrumentSerif(25, italic: true))
                            .foregroundColor(.focusMuted)
                    }
                    .padding(.bottom, 4)

                    // Subtitle
                    Text("Solve the problem to make this change. This pause is the point.")
                        .font(.inter(13))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(2)
                        .padding(.bottom, 18)

                    // Problem card
                    VStack(spacing: 12) {
                        Text(problem.question)
                            .font(.instrumentSerif(34))
                            .foregroundColor(.focusInk)
                            .monospacedDigit()

                        TextField("Answer", text: $userAnswer)
                            .font(.inter(22, weight: .semibold))
                            .foregroundColor(.focusInk)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                            .frame(width: 150)
                            .padding(.vertical, 4)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(isShaking ? .focusWarn : Color.focusInk.opacity(0.18)),
                                alignment: .bottom
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.focusLine, lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .offset(x: isShaking ? -5 : 0)
                    .animation(isShaking ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: isShaking)

                    // Continue button
                    Button(action: submit) {
                        Text("Continue")
                            .font(.inter(15.5, weight: .semibold))
                            .foregroundColor(userAnswer.isEmpty ? Color.focusInk.opacity(0.35) : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(userAnswer.isEmpty ? Color.focusInk.opacity(0.15) : Color.focusInk)
                            .cornerRadius(16)
                    }
                    .disabled(userAnswer.isEmpty)
                    .padding(.top, 14)

                    // Cancel button
                    Button(action: { dismiss() }) {
                        Text("Keep it locked")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(.focusMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 26)
                .padding(.bottom, 20)
                .background(Color.focusBg)
                .cornerRadius(26)
                .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: -8)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                isInputFocused = true
            }
        }
    }

    private func submit() {
        guard !userAnswer.isEmpty else { return }

        if let answer = Int(userAnswer), answer == problem.answer {
            // Correct answer
            data.onPass()
            dismiss()
        } else {
            // Wrong answer - shake and reset
            isShaking = true
            userAnswer = ""
            problem = ChallengeGate.makeProblem(difficulty: difficulty)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                isShaking = false
            }
        }
    }

    static func makeProblem(difficulty: Int) -> MathProblem {
        let d = min(max(difficulty, 1), 5)

        switch d {
        case 1, 2:
            // Easy addition
            let a = Int.random(in: 2...9)
            let b = Int.random(in: 2...9)
            return MathProblem(question: "\(a) + \(b)", answer: a + b)
        case 3:
            // Medium addition
            let a = Int.random(in: 11...29)
            let b = Int.random(in: 13...29)
            return MathProblem(question: "\(a) + \(b)", answer: a + b)
        case 4:
            // Multiplication
            let a = Int.random(in: 3...12)
            let b = Int.random(in: 4...12)
            return MathProblem(question: "\(a) × \(b)", answer: a * b)
        default:
            // Hard multiplication
            let a = Int.random(in: 12...24)
            let b = Int.random(in: 4...12)
            return MathProblem(question: "\(a) × \(b)", answer: a * b)
        }
    }
}

// MARK: - Confirm Dialog

struct ConfirmDialogData: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let confirmLabel: String
    let isDanger: Bool
    let onConfirm: () -> Void
}

struct ConfirmDialog: View {
    let data: ConfirmDialogData
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.5))
                .onTapGesture {
                    dismiss()
                }

            // Dialog card
            VStack(alignment: .leading, spacing: 0) {
                // Title
                HStack(spacing: 0) {
                    Text(data.title)
                        .font(.instrumentSerif(25))
                        .foregroundColor(.focusInk)

                    Text("?")
                        .font(.instrumentSerif(25, italic: true))
                        .foregroundColor(.focusMuted)
                }
                .padding(.bottom, 8)

                // Body
                Text(data.body)
                    .font(.inter(13.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(3)
                    .padding(.bottom, 20)

                // Confirm button
                Button(action: {
                    data.onConfirm()
                    dismiss()
                }) {
                    Text(data.confirmLabel)
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(data.isDanger ? Color.focusWarn : Color.focusInk)
                        .cornerRadius(15)
                }

                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(.focusMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 18)
            .background(Color.focusBg)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.22), radius: 25, x: 0, y: 12)
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
