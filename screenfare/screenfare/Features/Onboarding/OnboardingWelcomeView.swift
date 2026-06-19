//
//  OnboardingWelcomeView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                // paddingTop: 76px from design
                Spacer()
                    .frame(height: 76)

                // Brand icon: 72x72
                BrandMark(size: 72)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // App name label: fontSize: 11, uppercase, letterSpacing: 0.18em, margin: 34px 0 14px
                Text("SCREEN FARE")
                    .font(.inter(11, weight: .medium))
                    .foregroundColor(.focusMuted)
                    .tracking(11 * 0.18) // letterSpacing: 0.18em
                    .padding(.top, 34)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Title: fontSize: 46, lineHeight: 1.0, margin: 0 0 18px
                (Text("Pay the fare\nto ")
                    .font(.instrumentSerif(46))
                    .foregroundColor(.focusInk)
                 + Text("pass.")
                    .font(.instrumentSerif(46, italic: true))
                    .foregroundColor(.focusAccent))
                    .lineSpacing(46 * 0.0) // lineHeight 1.0 = no extra spacing
                    .tracking(-0.92) // letterSpacing: -0.02em = -0.92px at 46px
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)

                // Description: fontSize: 16, lineHeight: 1.55, maxWidth: 308, margin: 0
                HStack {
                    Text("A gate in front of the apps that pull you in. Clear a short, deliberate pause to get through — so every open is a choice, not a reflex.")
                        .font(.inter(16))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(16 * 0.55) // lineHeight 1.55 = 55% extra spacing
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 308, alignment: .leading)

                    Spacer(minLength: 0)
                }
                .padding(.top, 18)

                Spacer()

                // Primary button: height: 56, borderRadius: 16, paddingBottom: 34
                PrimaryButton(title: "Begin setup", action: onContinue)
                    .padding(.bottom, 34)
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
