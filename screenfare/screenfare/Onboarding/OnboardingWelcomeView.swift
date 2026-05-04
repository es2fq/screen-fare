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
        OnboardingScreen {
            VStack(spacing: 0) {
                // paddingTop: 80px from design
                Spacer()
                    .frame(height: 80)

                // Brand mark: 64x64, borderRadius: 17.92 (64 * 0.28), left aligned
                BrandMark(size: 64)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Title: fontSize: 44, lineHeight: 1.02, margin: 32px 0 16px
                VStack(alignment: .leading, spacing: 0) {
                    Text("Focus, by")
                        .font(.instrumentSerif(44))
                        .foregroundColor(.focusInk)
                        .tracking(-0.88) // letterSpacing: -0.02em = -0.88px at 44px

                    Text("design.")
                        .font(.instrumentSerif(44, italic: true))
                        .foregroundColor(.focusInk)
                        .tracking(-0.88)
                }
                .lineSpacing(44 * 0.02) // lineHeight 1.02 = 2% extra spacing
                .padding(.top, 32)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 16, lineHeight: 1.5, maxWidth: 300, left aligned
                HStack {
                    Text("Block the apps that pull you in. Open them only after a brief, intentional pause.")
                        .font(.inter(16))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(16 * 0.5) // lineHeight 1.5 = 50% extra spacing
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 300, alignment: .leading)

                    Spacer(minLength: 0)
                }
                .padding(.top, 16)

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
