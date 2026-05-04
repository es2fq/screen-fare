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

    private var selectedMinutes: Int {
        Int(selectedDuration / 60)
    }

    private var durationDisplay: (value: String, unit: String) {
        if selectedMinutes < 60 {
            return ("\(selectedMinutes)", "min")
        } else if selectedMinutes == 60 {
            return ("1", "hr")
        } else {
            let hours = selectedMinutes / 60
            let mins = selectedMinutes % 60
            return ("\(hours)", mins > 0 ? "h \(mins)m" : "hr")
        }
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 5, onBack: {})

                Spacer()
                    .frame(height: 24)

                // Title
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How long should")
                            .font(.instrumentSerif(32))
                            .foregroundColor(.focusInk)
                        Spacer()
                    }

                    HStack {
                        Text("the door ")
                            .font(.instrumentSerif(32))
                            .foregroundColor(.focusInk)
                        + Text("stay open?")
                            .font(.instrumentSerif(32, italic: true))
                            .foregroundColor(.focusInk)
                        Spacer()
                    }
                }

                // Description
                Text("After you solve the problem, the app unlocks for this much time before re-locking.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                    .frame(height: 18)

                // Big duration display card
                VStack(spacing: 28) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(durationDisplay.value)
                            .font(.instrumentSerif(88))
                            .foregroundColor(.focusInk)
                            .monospacedDigit()

                        Text(durationDisplay.unit)
                            .font(.instrumentSerif(22, italic: true))
                            .foregroundColor(.focusMuted)
                    }

                    VStack(spacing: 6) {
                        Slider(
                            value: $selectedDuration,
                            in: 60...7200, // 1 min to 2 hours
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
                }
                .padding(.horizontal, 22)
                .padding(.top, 36)
                .padding(.bottom, 28)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.focusLine, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.focusCard)
                        )
                )

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([2, 5, 15, 30, 60], id: \.self) { preset in
                        Button(action: {
                            selectedDuration = TimeInterval(preset * 60)
                        }) {
                            Text(preset < 60 ? "\(preset)m" : "\(preset/60)h")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(selectedMinutes == preset ? .white : .focusInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedMinutes == preset ? Color.focusInk : Color.focusLine, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedMinutes == preset ? Color.focusInk : Color.focusCard)
                                        )
                                )
                        }
                    }
                }
                .padding(.top, 14)

                Spacer()

                // Primary button
                PrimaryButton(title: "Continue", action: onContinue)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
            }
        }
    }
}

#Preview {
    OnboardingTimeWindowView(selectedDuration: .constant(300), onContinue: {})
}
