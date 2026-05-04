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
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)

                Text("All Set!")
                    .font(.system(size: 34, weight: .bold))

                Text("Review your settings")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Summary cards
            VStack(spacing: 12) {
                SummaryRow(
                    icon: "app.badge",
                    title: "Apps",
                    value: "\(appCount)"
                )

                SummaryRow(
                    icon: "brain.head.profile",
                    title: "Difficulty",
                    value: difficulty.rawValue
                )

                SummaryRow(
                    icon: "clock.fill",
                    title: "Duration",
                    value: "\(durationMinutes) min"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

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

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 28)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
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
