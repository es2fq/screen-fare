//
//  OnboardingDifficultyView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct OnboardingDifficultyView: View {
    @Binding var selectedGridSize: Int
    @State private var tilesToMatch: Int
    let onContinue: () -> Void

    init(selectedGridSize: Binding<Int>, onContinue: @escaping () -> Void) {
        self._selectedGridSize = selectedGridSize
        // Set tiles to match based on grid size
        let gridSize = selectedGridSize.wrappedValue
        self._tilesToMatch = State(initialValue: min(gridSize + 1, gridSize * gridSize))
        self.onContinue = onContinue
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                // Title: fontSize: 32, lineHeight: 1.05
                (Text("The ")
                    .font(.instrumentSerif(32))
                    .foregroundColor(.focusInk)
                 + Text("fare")
                    .font(.instrumentSerif(32, italic: true))
                    .foregroundColor(.focusAccent)
                 + Text("\nbefore you scroll.")
                    .font(.instrumentSerif(32))
                    .foregroundColor(.focusInk))
                    .lineSpacing(32 * 0.05) // lineHeight 1.05 = 5% extra spacing
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description: fontSize: 14.5
                Text("Play a memory game to unlock a blocked app. You may change this later.")
                    .font(.inter(14.5))
                    .foregroundColor(.focusMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 22)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Grid size configuration card (matches configuration screen exactly)
                        AppCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Grid size")
                                        .font(.inter(13))
                                        .foregroundColor(.focusMuted)
                                    Spacer()
                                    Text(gridSizeLabel)
                                        .font(.inter(15, weight: .semibold))
                                        .foregroundColor(.focusInk)
                                }

                                CustomSlider(
                                    value: Binding(
                                        get: { Double(selectedGridSize) },
                                        set: { newValue in
                                            let gridSize = Int(newValue)
                                            selectedGridSize = gridSize
                                            tilesToMatch = min(gridSize + 1, gridSize * gridSize)
                                        }
                                    ),
                                    range: 3...7,
                                    step: 1
                                )

                                MemoryTester(gridSize: selectedGridSize, tilesToMatch: tilesToMatch)
                                    .id("\(selectedGridSize)-\(tilesToMatch)")
                            }
                        }
                    }
                }

                Spacer()
                    .frame(height: 14)

                // Primary button
                PrimaryButton(title: "Continue", action: onContinue)
                    .padding(.bottom, 34)
            }
        }
    }

    private var gridSizeLabel: String {
        return "\(selectedGridSize)×\(selectedGridSize)"
    }
}

#Preview {
    OnboardingDifficultyView(selectedGridSize: .constant(4), onContinue: {})
}
