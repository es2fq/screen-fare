//
//  OnboardingSuccessView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingSuccessView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                }

                Text("Success!")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)

                Text("Your apps are now protected")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "1.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Try opening a blocked app")
                            .fontWeight(.semibold)
                        Text("You'll see a shield screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Image(systemName: "2.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap 'Unlock with Challenge'")
                            .fontWeight(.semibold)
                        Text("This will send you a notification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Image(systemName: "3.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Solve the math problem")
                            .fontWeight(.semibold)
                        Text("Correct answer unlocks your apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onComplete()
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

#Preview {
    OnboardingSuccessView(onComplete: {})
}
