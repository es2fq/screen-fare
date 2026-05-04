//
//  OnboardingAppSelectionView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct OnboardingAppSelectionView: View {
    @Binding var selectedApps: FamilyActivitySelection
    @State private var showingPicker = false
    @State private var pickerSelection: FamilyActivitySelection = FamilyActivitySelection()
    let onContinue: () -> Void

    private var hasSelectedApps: Bool {
        !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty
    }

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScreenHeader(currentStep: 3, onBack: {})

                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05, margin: 0 0 8px
                (Text("What pulls you\n")
                    .font(.instrumentSerif(32))
                 + Text("away?")
                    .font(.instrumentSerif(32, italic: true)))
                    .foregroundColor(.focusInk)
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 14.5
                Text("Choose apps and categories Focus will gently restrict.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                // Facepile Card
                HStack(spacing: 10) {
                    if hasSelectedApps {
                        AppFacepile(selectedApps: selectedApps)
                    } else {
                        Text("No apps selected yet")
                            .font(.inter(13))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.focusLine, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.focusCard)
                        )
                )
                .padding(.top, 16)

                Spacer()
                    .frame(height: 24)

                // Select apps button
                Button(action: { showingPicker = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.focusInk.opacity(0.06))
                                .frame(width: 32, height: 32)

                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.focusInk)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(hasSelectedApps ? "Manage apps" : "Add apps")
                                .font(.inter(14.5, weight: .semibold))
                                .foregroundColor(.focusInk)

                            Text(hasSelectedApps ? "\(appCount) selected · tap to manage" : "Browse all apps via Screen Time")
                                .font(.inter(12))
                                .foregroundColor(.focusMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.focusMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.focusLine, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.focusCard)
                            )
                    )
                }

                Spacer()

                // Primary button
                PrimaryButton(title: "Continue", action: onContinue, disabled: !hasSelectedApps)
                    .padding(.bottom, 34)
                    .padding(.top, 14)
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $pickerSelection)
        .onChange(of: showingPicker) { _, isShowing in
            if isShowing {
                // When opening picker, sync from binding
                pickerSelection = selectedApps
            } else {
                // When closing picker, sync to binding
                selectedApps = pickerSelection
            }
        }
    }
}

struct AppFacepile: View {
    let selectedApps: FamilyActivitySelection

    var body: some View {
        HStack(spacing: 8) {
            let appTokens = Array(selectedApps.applicationTokens)
            let categoryTokens = Array(selectedApps.categoryTokens)
            let totalCount = appTokens.count + categoryTokens.count
            let displayCount = min(5, totalCount)
            let remainingCount = totalCount - displayCount

            // Show app icons first (up to 5 total between apps and categories)
            ForEach(0..<displayCount, id: \.self) { index in
                if index < appTokens.count {
                    // Show individual app icon
                    Label(appTokens[index])
                        .labelStyle(.iconOnly)
                        .scaleEffect(2.0)
                        .frame(width: 40, height: 40)
                        .background(Color.focusCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Show category icon
                    let categoryIndex = index - appTokens.count
                    if categoryIndex < categoryTokens.count {
                        Label(categoryTokens[categoryIndex])
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.0)
                            .frame(width: 40, height: 40)
                            .background(Color.focusCard)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Show +N box if there are more than 5 items
            if remainingCount > 0 {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.focusInk.opacity(0.06))
                        .frame(width: 40, height: 40)

                    Text("+\(remainingCount)")
                        .font(.inter(12, weight: .semibold))
                        .foregroundColor(.focusInk)
                }
            }
        }
    }
}

#Preview {
    OnboardingAppSelectionView(selectedApps: .constant(FamilyActivitySelection()), onContinue: {})
}
