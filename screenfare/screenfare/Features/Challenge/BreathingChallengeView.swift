//
//  BreathingChallengeView.swift
//  Screen Fare
//
//  Breathing challenge visualization with animated orb
//  Design based on "Aurora Soft" variant from breathing-variations.jsx
//

import SwiftUI

// MARK: - Breathing Phase

enum BreathingPhase {
    case inhale
    case hold
    case exhale

    var label: String {
        switch self {
        case .inhale: return "Breathe in"
        case .hold: return "Hold"
        case .exhale: return "Breathe out"
        }
    }
}

// MARK: - Breathing Orb View

struct BreathingOrbView: View {
    let challenge: BreathingChallenge
    @Binding var currentBreath: Int
    @Binding var currentPhase: BreathingPhase
    @Binding var phaseProgress: Double
    @Binding var isAnimating: Bool
    let onComplete: () -> Void

    @State private var animationTimer: Timer?
    @State private var phaseStartTime: Date?
    @State private var countdownSeconds: Int = 4

    // Animation state
    private var orbScale: CGFloat {
        let restScale: CGFloat = 0.5
        let fullScale: CGFloat = 1.0
        let progress = animationProgress

        switch currentPhase {
        case .inhale:
            return restScale + (fullScale - restScale) * progress
        case .hold:
            return fullScale
        case .exhale:
            return fullScale - (fullScale - restScale) * progress
        }
    }

    private var glowOpacity: Double {
        let baseOpacity = 0.3
        let maxOpacity = 0.5
        let progress = animationProgress

        switch currentPhase {
        case .inhale:
            return baseOpacity + (maxOpacity * progress)
        case .hold:
            return baseOpacity + maxOpacity
        case .exhale:
            return baseOpacity + (maxOpacity * (1 - progress))
        }
    }

    private var animationProgress: CGFloat {
        // Ease function: 0.5 - 0.5 * cos(π * t)
        let t = phaseProgress
        let eased = 0.5 - 0.5 * cos(.pi * t)
        return CGFloat(eased)
    }

    private var ringStrokeDashoffset: CGFloat {
        let circumference: CGFloat = 2 * .pi * 142
        let totalProgress = Double(currentBreath - 1) / Double(challenge.totalBreaths)
        let currentCycleProgress = phaseProgress / 3.0 // Each breath has 3 phases
        let overallProgress = totalProgress + (currentCycleProgress / Double(challenge.totalBreaths))
        return circumference * CGFloat(1 - overallProgress)
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.8, green: 0.878, blue: 0.835).opacity(0.55),
                            Color(red: 0.8, green: 0.878, blue: 0.835).opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 8)
                .opacity(glowOpacity)

            // Guide rings
            Circle()
                .stroke(Color(red: 0.72, green: 0.84, blue: 0.78).opacity(0.18), lineWidth: 1)
                .frame(width: 232, height: 232)

            Circle()
                .stroke(Color(red: 0.72, green: 0.84, blue: 0.78).opacity(0.10), lineWidth: 1)
                .frame(width: 286, height: 286)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.95, green: 0.97, blue: 0.96), location: 0),
                            .init(color: Color(red: 0.78, green: 0.86, blue: 0.82), location: 1)
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: Color.white.opacity(0.4), radius: 10, x: 0, y: 2)
                .shadow(color: Color(red: 0.62, green: 0.75, blue: 0.68).opacity(0.24), radius: 40, x: 0, y: 16)
                .scaleEffect(orbScale)
                .animation(.linear(duration: 0.016), value: orbScale)
        }
        .frame(width: 200, height: 300)
        .onChange(of: isAnimating) { oldValue, newValue in
            if newValue && !oldValue {
                startBreathing()
            } else if !newValue && oldValue {
                stopBreathing()
            }
        }
        .onDisappear {
            stopBreathing()
        }
    }

    private func startBreathing() {
        // Reset state
        currentBreath = 1
        currentPhase = .inhale
        phaseStartTime = Date()

        // Start animation timer
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateAnimation()
        }
    }

    private func stopBreathing() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateAnimation() {
        guard let startTime = phaseStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let phaseDuration: TimeInterval

        switch currentPhase {
        case .inhale:
            phaseDuration = challenge.inhaleDuration
        case .hold:
            phaseDuration = challenge.holdDuration
        case .exhale:
            phaseDuration = challenge.exhaleDuration
        }

        // Update progress
        phaseProgress = min(elapsed / phaseDuration, 1.0)

        // Update countdown
        countdownSeconds = max(1, Int(ceil(phaseDuration - elapsed)))

        // Check if phase is complete
        if elapsed >= phaseDuration {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch currentPhase {
        case .inhale:
            currentPhase = .hold
        case .hold:
            currentPhase = .exhale
        case .exhale:
            // Breath cycle complete
            if currentBreath >= challenge.totalBreaths {
                // Challenge complete!
                stopBreathing()
                onComplete()
                return
            } else {
                // Move to next breath
                currentBreath += 1
                currentPhase = .inhale
            }
        }

        // Reset phase timer
        phaseStartTime = Date()
        phaseProgress = 0
    }
}

// MARK: - Breathing Challenge Content

struct BreathingChallengeContent: View {
    let challenge: BreathingChallenge
    @Binding var currentBreath: Int
    @Binding var currentPhase: BreathingPhase
    @Binding var phaseProgress: Double
    @Binding var isAnimating: Bool
    let onComplete: () -> Void

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

    var body: some View {
        VStack(spacing: 16) {
            // Breathing instruction
            if isAnimating {
                VStack(spacing: 4) {
                    Text(currentPhase.label)
                        .font(.instrumentSerif(30))
                        .foregroundColor(Color(red: 0.46, green: 0.52, blue: 0.49))
                        .transition(.opacity)
                        .id(currentPhase) // Force view update on phase change

                    Text("\(phaseCountdown)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .tracking(0.56)
                        .foregroundColor(Color(red: 0.66, green: 0.74, blue: 0.70))
                        .monospacedDigit()
                }
            } else {
                VStack(spacing: 4) {
                    Text("Begin")
                        .font(.instrumentSerif(26))
                        .foregroundColor(Color(red: 0.46, green: 0.52, blue: 0.49))

                    Text("Tap to start")
                        .font(.inter(11))
                        .tracking(1.76)
                        .textCase(.uppercase)
                        .foregroundColor(.focusMuted)
                }
            }

            // Breathing orb
            BreathingOrbView(
                challenge: challenge,
                currentBreath: $currentBreath,
                currentPhase: $currentPhase,
                phaseProgress: $phaseProgress,
                isAnimating: $isAnimating,
                onComplete: onComplete
            )
            .onTapGesture {
                if !isAnimating {
                    isAnimating = true
                }
            }

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
        }
        .onAppear {
            // Auto-start breathing in the actual challenge (not the test)
            if !isAnimating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = true
                }
            }
        }
    }
}

#Preview("Breathing Challenge") {
    VStack {
        BreathingChallengeContent(
            challenge: BreathingChallenge(),
            currentBreath: .constant(1),
            currentPhase: .constant(.inhale),
            phaseProgress: .constant(0),
            isAnimating: .constant(false),
            onComplete: {}
        )
    }
    .background(Color.focusBg)
}
