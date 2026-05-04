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
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Welcome to ScreenFare")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Take control of your screen time and stay focused on what matters")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(icon: "app.badge", title: "Block Distracting Apps", description: "Choose which apps require a challenge")
                FeatureRow(icon: "brain", title: "Solve Challenges", description: "Complete math problems to unlock apps")
                FeatureRow(icon: "clock", title: "Temporary Access", description: "Apps relock after your chosen time")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Get Started")
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
