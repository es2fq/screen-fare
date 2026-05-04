//
//  OnboardingSummaryView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct OnboardingSummaryView: View {
    let selectedApps: FamilyActivitySelection
    let difficulty: ChallengeDifficulty
    let duration: TimeInterval
    let onComplete: () -> Void

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    private var durationMinutes: Int {
        Int(duration / 60)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)

                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Review your settings below and tap Start to begin")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Summary cards
            VStack(spacing: 16) {
                SummaryCard(
                    icon: "app.badge",
                    title: "Blocked Apps",
                    value: "\(appCount) app\(appCount == 1 ? "" : "s")"
                )

                SummaryCard(
                    icon: "brain.head.profile",
                    title: "Challenge Difficulty",
                    value: difficulty.rawValue
                )

                SummaryCard(
                    icon: "clock.fill",
                    title: "Unlock Duration",
                    value: "\(durationMinutes) minutes"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 8) {
                Text("These settings can be changed anytime in the Settings tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    onComplete()
                } label: {
                    Text("Start Blocking")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingSummaryView(
        selectedApps: FamilyActivitySelection(),
        difficulty: .medium,
        duration: 1800,
        onComplete: {}
    )
}
