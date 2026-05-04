//
//  OnboardingWelcomeView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Welcome to\nScreenFare")
                    .font(.system(size: 38, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Stay focused by blocking distracting apps")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                FeatureRow(icon: "app.badge", text: "Block distracting apps")
                FeatureRow(icon: "brain", text: "Solve challenges to unlock")
                FeatureRow(icon: "clock", text: "Temporary access")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
