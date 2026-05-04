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
                Spacer()
                    .frame(height: 80)

                // Brand mark
                BrandMark(size: 64)

                // Title
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Focus, by")
                            .font(.instrumentSerif(44))
                            .foregroundColor(.focusInk)
                            .lineSpacing(-2)
                        Spacer()
                    }

                    HStack {
                        Text("design.")
                            .font(.instrumentSerif(44, italic: true))
                            .foregroundColor(.focusInk)
                            .lineSpacing(-2)
                        Spacer()
                    }
                }
                .padding(.top, 32)

                // Description
                Text("Block the apps that pull you in. Open them only after a brief, intentional pause.")
                    .font(.inter(16))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                    .frame(maxWidth: 300, alignment: .leading)

                Spacer()

                // Primary button
                PrimaryButton(title: "Begin setup", action: onContinue)
                    .padding(.bottom, 34)
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
