//
//  OnboardingTimeWindowView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingTimeWindowView: View {
    @Binding var selectedDuration: TimeInterval
    let onContinue: () -> Void

    // Available durations in minutes: 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
    private let availableDurations: [TimeInterval] = stride(from: 300, through: 3600, by: 300).map { $0 }

    private var selectedMinutes: Int {
        Int(selectedDuration / 60)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                Text("Set Unlock Duration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Choose how long apps stay unlocked after completing a challenge")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Duration display
            VStack(spacing: 12) {
                Text("\(selectedMinutes)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                Text("minutes")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal, 32)

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: $selectedDuration,
                    in: 300...3600,
                    step: 300
                )
                .tint(.blue)
                .padding(.horizontal, 32)

                HStack {
                    Text("5 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("60 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }

            // Helpful hint
            Text(durationHint(for: selectedMinutes))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private func durationHint(for minutes: Int) -> String {
        switch minutes {
        case 5...10:
            return "Perfect for quick tasks"
        case 15...25:
            return "Good for short sessions"
        case 30...40:
            return "Ideal for focused work"
        default:
            return "Great for deep focus sessions"
        }
    }
}

#Preview {
    OnboardingTimeWindowView(selectedDuration: .constant(1800), onContinue: {})
}
