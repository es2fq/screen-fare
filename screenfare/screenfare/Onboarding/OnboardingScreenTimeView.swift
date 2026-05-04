//
//  OnboardingScreenTimeView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct OnboardingScreenTimeView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                Text("Screen Time Permission")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("ScreenFare needs access to Screen Time to block and manage your apps")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                PermissionReasonRow(icon: "shield.fill", text: "Block distracting apps when you need to focus")
                PermissionReasonRow(icon: "lock.fill", text: "Require challenges before apps can be opened")
                PermissionReasonRow(icon: "checkmark.shield.fill", text: "Your data stays private and secure on your device")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                Task {
                    try? await blockingManager.requestAuthorization()
                }
            } label: {
                Text(blockingManager.isAuthorized ? "Permission Granted ✓" : "Enable Screen Time Permission")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(blockingManager.isAuthorized ? Color.green : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(blockingManager.isAuthorized)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .onChange(of: blockingManager.isAuthorized) { isAuthorized in
            if isAuthorized {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
        }
    }
}

struct PermissionReasonRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OnboardingScreenTimeView(onContinue: {})
}
