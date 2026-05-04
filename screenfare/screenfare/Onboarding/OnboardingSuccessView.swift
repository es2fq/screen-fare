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
        OnboardingScreen {
            VStack(spacing: 0) {
                Spacer()

                // Checkmark icon
                ZStack {
                    Circle()
                        .fill(Color.focusInk)
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 28)

                // Title
                VStack(alignment: .center, spacing: 12) {
                    Text("Focus is ")
                        .font(.instrumentSerif(40))
                        .foregroundColor(.focusInk)
                    + Text("on.")
                        .font(.instrumentSerif(40, italic: true))
                        .foregroundColor(.focusInk)

                    Text("Your settings are active. Open a blocked app to try it out.")
                        .font(.inter(15))
                        .foregroundColor(.focusMuted)
                        .lineSpacing(7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                Spacer()

                // Primary button
                PrimaryButton(title: "Done", action: onComplete)
                    .padding(.bottom, 34)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    OnboardingSuccessView(onComplete: {})
}
