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
    @State private var hasAdvanced = false
    @State private var isVisible = false
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hourglass")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Screen Time Access")
                    .font(.system(size: 34, weight: .bold))

                Text("Required to block and manage apps")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                PermissionReason(icon: "shield.fill", text: "Block apps when you need focus")
                PermissionReason(icon: "lock.fill", text: "Require challenges before opening")
                PermissionReason(icon: "hand.raised.fill", text: "Your data stays on your device")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                Task {
                    try? await blockingManager.requestAuthorization()
                }
            } label: {
                Text("Enable Screen Time Access")
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
        .onChange(of: blockingManager.isAuthorized) { isAuthorized in
            if isAuthorized && !hasAdvanced && isVisible {
                hasAdvanced = true
                onContinue()
            }
        }
        .onAppear {
            isVisible = true
            // Skip this screen if already authorized
            if blockingManager.isAuthorized && !hasAdvanced {
                hasAdvanced = true
                onContinue()
            }
        }
        .onDisappear {
            isVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Re-check authorization when returning from Settings (only if this view is visible)
            if isVisible && blockingManager.isAuthorized && !hasAdvanced {
                hasAdvanced = true
                onContinue()
            }
        }
    }
}

struct PermissionReason: View {
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
    OnboardingScreenTimeView(onContinue: {})
}
