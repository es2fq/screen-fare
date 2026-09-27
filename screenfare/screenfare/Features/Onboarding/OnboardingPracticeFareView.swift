//
//  OnboardingPracticeFareView.swift
//  Screen Fare
//
//  A practice run of the real fare ticket before anything is blocked
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingPracticeFareView: View {
    let selectedApps: FamilyActivitySelection
    let gridSize: Int
    let duration: TimeInterval
    let onContinue: () -> Void

    private var practice: PracticeFare {
        let appToken = selectedApps.applicationTokens.first
        return PracticeFare(
            memoryGridSize: gridSize,
            memoryTilesToMatch: min(gridSize + 1, gridSize * gridSize),
            unlockDuration: duration,
            appToken: appToken,
            categoryToken: appToken == nil ? selectedApps.categoryTokens.first : nil
        )
    }

    var body: some View {
        OnboardingScreen(padding: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05
                (Text("Try a practice ")
                    .font(.instrumentSerif(32))
                    .foregroundColor(.focusInk)
                 + Text("fare.")
                    .font(.instrumentSerif(32, italic: true))
                    .foregroundColor(.focusAccent))
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                // Description: fontSize: 14.5
                Text("The gate you'll meet at a blocked app.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.horizontal, 28)

                // The real ticket in practice mode; its 22pt inset + 6 lines up with the 28pt margins
                ChallengeView(
                    challengeType: .memory,
                    practice: practice,
                    onPracticeComplete: onContinue
                )
                .padding(.horizontal, 6)
            }
        }
    }
}

#Preview {
    OnboardingPracticeFareView(
        selectedApps: FamilyActivitySelection(),
        gridSize: 4,
        duration: 1800,
        onContinue: {}
    )
}
