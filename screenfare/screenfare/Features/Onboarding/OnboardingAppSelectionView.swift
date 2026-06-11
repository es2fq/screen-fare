//
//  OnboardingAppSelectionView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingAppSelectionView: View {
    @Binding var selectedApps: FamilyActivitySelection
    @State private var showingPicker = false
    @State private var pickerSelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var orderedAppTokens: [ApplicationToken] = []
    @State private var orderedCategoryTokens: [ActivityCategoryToken] = []
    let onContinue: () -> Void

    private var hasSelectedApps: Bool {
        !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty
    }

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    private func updateOrderedSelections() {
        let newAppTokens = Set(pickerSelection.applicationTokens)
        let newCategoryTokens = Set(pickerSelection.categoryTokens)

        // Remove deselected tokens
        orderedAppTokens.removeAll { !newAppTokens.contains($0) }
        orderedCategoryTokens.removeAll { !newCategoryTokens.contains($0) }

        // Add newly selected tokens to the end
        let existingAppTokens = Set(orderedAppTokens)
        let existingCategoryTokens = Set(orderedCategoryTokens)

        for token in newAppTokens {
            if !existingAppTokens.contains(token) {
                orderedAppTokens.append(token)
            }
        }

        for token in newCategoryTokens {
            if !existingCategoryTokens.contains(token) {
                orderedCategoryTokens.append(token)
            }
        }
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
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
                
                Spacer().frame(height: 8)

                // Description: fontSize: 14.5
                Text("Choose apps and categories Focus will gently restrict.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                
                Spacer().frame(height: 8)

                // Facepile Card
                Group {
                    if hasSelectedApps {
                        AppFacepile(
                            orderedAppTokens: orderedAppTokens,
                            orderedCategoryTokens: orderedCategoryTokens,
                            totalCount: appCount
                        )
                    } else {
                        Text("No apps selected yet")
                            .font(.inter(13))
                            .foregroundColor(.focusMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                }
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
                // When closing picker, update ordered arrays and sync to binding
                updateOrderedSelections()
                selectedApps = pickerSelection
            }
        }
    }
}

struct AppFacepile: View {
    let orderedAppTokens: [ApplicationToken]
    let orderedCategoryTokens: [ActivityCategoryToken]
    let totalCount: Int

    var body: some View {
        HStack {
            Spacer()

            HStack(spacing: 10) {
                let remainingCount = max(0, totalCount - 5)

                // Show individual app icons (up to 5)
                ForEach(Array(orderedAppTokens.prefix(min(5, orderedAppTokens.count)).enumerated()), id: \.element) { index, token in
                    Label(token)
                        .labelStyle(.iconOnly)
                        .scaleEffect(2.0)
                        .frame(width: 40, height: 40)
                        .background(Color.focusCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Show category icons (only if we have room left after apps)
                if orderedAppTokens.count < 5 {
                    let categoryLimit = 5 - orderedAppTokens.count
                    ForEach(Array(orderedCategoryTokens.prefix(categoryLimit).enumerated()), id: \.element) { index, token in
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.0)
                            .frame(width: 40, height: 40)
                            .background(Color.focusCard)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Show +N box if there are more than 5 items total
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
            }.frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OnboardingAppSelectionView(selectedApps: .constant(FamilyActivitySelection()), onContinue: {})
}
