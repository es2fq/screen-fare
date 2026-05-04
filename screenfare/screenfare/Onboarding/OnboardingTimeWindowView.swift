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
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Unlock Duration")
                    .font(.system(size: 34, weight: .bold))

                // Duration display
                VStack(spacing: 8) {
                    Text("\(selectedMinutes)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    Text("minutes")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 32)
            }

            // Slider
            VStack(spacing: 12) {
                Slider(
                    value: $selectedDuration,
                    in: 300...3600,
                    step: 300
                )
                .tint(.blue)
                .padding(.horizontal, 32)

                HStack {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }

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

}

#Preview {
    OnboardingTimeWindowView(selectedDuration: .constant(1800), onContinue: {})
}
