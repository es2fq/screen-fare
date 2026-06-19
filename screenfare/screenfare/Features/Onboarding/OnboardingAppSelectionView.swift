//
//  OnboardingAppSelectionView.swift
//  Screen Fare
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
                Text("Pick the apps that pull you in. Screen Fare restricts them through Screen Time.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(14.5 * 0.5) // lineHeight: 1.5
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(height: 14)

                // Content area - fills available space
                if hasSelectedApps {
                    // Selected state
                    VStack(alignment: .leading, spacing: 12) {
                        // Header with count
                        HStack {
                            Text("RESTRICTING")
                                .font(.inter(11, weight: .semibold))
                                .foregroundColor(.focusMuted)
                                .tracking(0.6)

                            Spacer()

                            Text("\(appCount) \(appCount == 1 ? "selection" : "selections")")
                                .font(.inter(13))
                                .foregroundColor(.focusMuted)
                        }

                        // Apps grid - just icons like BlocksView
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 18) {
                            // Display categories first
                            ForEach(orderedCategoryTokens, id: \.self) { token in
                                VStack {
                                    Label(token)
                                        .labelStyle(.iconOnly)
                                        .frame(width: 42, height: 42)
                                        .scaleEffect(1.5)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.focusLine, lineWidth: 1)
                                )
                                .cornerRadius(16)
                            }

                            // Display apps
                            ForEach(orderedAppTokens, id: \.self) { token in
                                VStack {
                                    Label(token)
                                        .labelStyle(.iconOnly)
                                        .frame(width: 42, height: 42)
                                        .scaleEffect(1.5)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.focusLine, lineWidth: 1)
                                )
                                .cornerRadius(16)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.focusCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.focusLine, lineWidth: 1)
                        )

                        // Edit selection button
                        Button(action: { showingPicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))

                                Text("Edit selection")
                                    .font(.inter(14, weight: .semibold))
                            }
                            .foregroundColor(.focusInk)
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    // Empty state - fills available vertical space
                    Button(action: { showingPicker = true }) {
                        VStack(spacing: 16) {
                            Spacer()

                            // App icon preview with real app glyphs
                            HStack(spacing: -10) {
                                // Instagram
                                AppGlyphView(glyph: "IG", color: Color(red: 0.894, green: 0.251, blue: 0.373))

                                // TikTok
                                AppGlyphView(glyph: "TT", color: Color(red: 0.067, green: 0.067, blue: 0.067))

                                // YouTube
                                AppGlyphView(glyph: "YT", color: Color(red: 1.0, green: 0.0, blue: 0.0))
                            }

                            VStack(spacing: 6) {
                                Text("Choose apps")
                                    .font(.inter(17, weight: .semibold))
                                    .foregroundColor(.focusInk)

                                Text("Click to open Screen Time's picker. Choose the apps that distract you the most.")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(13 * 0.5)
                                    .frame(maxWidth: 240)
                            }

                            HStack(spacing: 8) {
                                Text("Open picker")
                                    .font(.inter(14.5, weight: .semibold))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(
                                Capsule()
                                    .fill(Color.focusInk)
                            )

                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.focusCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                                .foregroundColor(Color.focusLine)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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

// App icon glyph matching the HTML design
struct AppGlyphView: View {
    let glyph: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(width: 48, height: 48)

            Text(glyph)
                .font(.inter(19, weight: .bold))
                .foregroundColor(color == Color(red: 1.0, green: 0.988, blue: 0.0) ? .black : .white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.focusCard, lineWidth: 2)
        )
    }
}

#Preview {
    OnboardingAppSelectionView(selectedApps: .constant(FamilyActivitySelection()), onContinue: {})
}
