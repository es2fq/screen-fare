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
                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05
                (Text("How long should\nthe door ")
                    .font(.instrumentSerif(32))
                 + Text("stay open?")
                    .font(.instrumentSerif(32, italic: true)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 14.5
                Text("After you solve the problem, the app unlocks for this much time before re-locking.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 18)

                // Big duration display card: borderRadius: 18, padding: 36px 22px 28px
                VStack(spacing: 28) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        // Duration number: fontSize: 88, lineHeight: 1
                        Text(durationDisplay.value)
                            .font(.instrumentSerif(88))
                            .foregroundColor(.focusInk)
                            .lineSpacing(0) // lineHeight 1 = no extra spacing
                            .monospacedDigit()

                        // Unit: fontSize: 22, italic
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
