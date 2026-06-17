//
//  SettingsModals.swift
//  Screen Fare
//
//  Modal overlays for Settings: Toast, ChallengeGate, ConfirmDialog
//

import SwiftUI

// MARK: - Toast Notification

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

struct SettingsToast: View {
    let toast: ToastData?

    var body: some View {
        if let toast = toast {
            GeometryReader { geometry in
                VStack {
                    Spacer()

                    Text(toast.message)
                        .font(.inter(13.5, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Color.focusInk)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.26), radius: 13, x: 0, y: 8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 50)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 90)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast.id)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Challenge Gate Modal

struct ChallengeGateData: Identifiable {
    let id = UUID()
    let title: String
    let onPass: () -> Void
}

struct ChallengeGate: View {
    let data: ChallengeGateData
    let difficulty: Int

    var body: some View {
        ChallengeView(
            isStrictMode: true,
            onStrictModePass: data.onPass
        )
    }
}

// MARK: - Confirm Dialog

struct ConfirmDialogData: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let confirmLabel: String
    let isDanger: Bool
    let onConfirm: () -> Void
}

struct ConfirmDialog: View {
    let data: ConfirmDialogData
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.5))
                .onTapGesture {
                    dismiss()
                }

            // Dialog card
            VStack(alignment: .leading, spacing: 0) {
                // Title
                HStack(spacing: 0) {
                    Text(data.title)
                        .font(.instrumentSerif(25))
                        .foregroundColor(.focusInk)

                    Text("?")
                        .font(.instrumentSerif(25, italic: true))
                        .foregroundColor(.focusMuted)
                }
                .padding(.bottom, 8)

                // Body
                Text(data.body)
                    .font(.inter(13.5))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(3)
                    .padding(.bottom, 20)

                // Confirm button
                Button(action: {
                    data.onConfirm()
                    dismiss()
                }) {
                    Text(data.confirmLabel)
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(data.isDanger ? Color.focusWarn : Color.focusInk)
                        .cornerRadius(15)
                }

                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(.focusMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 18)
            .background(Color.focusBg)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.22), radius: 25, x: 0, y: 12)
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
