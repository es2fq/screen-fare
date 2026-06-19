//
//  StrictModeEditorSheet.swift
//  Screen Fare
//
//  Drill-in view for configuring Strict Mode protections
//

import SwiftUI

struct StrictModeEditorSheet: View {
    @ObservedObject var settings: SettingsManager
    let onClose: () -> Void

    // Challenge gate
    @State private var showGate: ChallengeGateData?

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button header
                HStack(spacing: 0) {
                    Button(action: onClose) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Blocks")
                                .font(.inter(17, weight: .medium))
                        }
                        .foregroundColor(.focusInk)
                        .padding(.vertical, 10)
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 4)

                // Large title
                Text("Strict Mode")
                    .font(.instrumentSerif(34))
                    .foregroundColor(.focusInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Intro note
                        IntroNote(text: "Strict Mode puts a fare in front of the moves that quietly undo your blocks — so a moment of weakness costs more than a tap.")
                            .padding(.horizontal, 22)

                        // Main toggle
                        AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                            ToggleRow(
                                icon: SettIcon(path: "M5 9h12v9H5zM8 9V6a3 3 0 016 0v3", viewBox: "22 22"),
                                label: "Strict Mode",
                                sub: "Turning Screen Fare on/off",
                                value: Binding(
                                    get: { settings.strictModeEnabled },
                                    set: { newValue in
                                        if !newValue {
                                            // Turning OFF requires gate
                                            showGate = ChallengeGateData(
                                                title: "Turning off Strict Mode",
                                                onPass: {
                                                    settings.strictModeEnabled = false
                                                }
                                            )
                                        } else {
                                            settings.strictModeEnabled = true
                                        }
                                    }
                                ),
                                last: true
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.horizontal, 22)

                        // Warning when off
                        if !settings.strictModeEnabled {
                            HStack(alignment: .top, spacing: 9) {
                                LockMini()
                                    .padding(.top, 1)

                                Text("While Strict Mode is off, these protections are paused. Turn it on to make undoing a block take effort.")
                                    .font(.inter(12.5))
                                    .foregroundColor(.focusMuted)
                                    .lineSpacing(2)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.focusInk.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.focusLine, lineWidth: 1)
                            )
                            .cornerRadius(14)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 4)
                        }

                        // Protection settings section
                        Text("REQUIRE A FARE BEFORE")
                            .font(.inter(11, weight: .semibold))
                            .foregroundColor(.focusMuted)
                            .tracking(0.6)
                            .padding(.horizontal, 26)
                            .padding(.top, 22)
                            .padding(.bottom, 10)

                        AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                            VStack(spacing: 0) {
                                ToggleRow(
                                    icon: SettIcon(path: "M5 9h12v9H5zM8 9V6a3 3 0 016 0v3", viewBox: "22 22"),
                                    label: "Blocklist",
                                    sub: "Adding or removing apps",
                                    value: Binding(
                                        get: { settings.strictProtectRemove },
                                        set: { newValue in
                                            if !newValue && settings.strictModeEnabled {
                                                showGate = ChallengeGateData(
                                                    title: "Stop guarding the blocklist",
                                                    onPass: {
                                                        settings.strictProtectRemove = false
                                                    }
                                                )
                                            } else {
                                                settings.strictProtectRemove = newValue
                                            }
                                        }
                                    ),
                                    disabled: !settings.strictModeEnabled
                                )

                                ToggleRow(
                                    icon: SettIcon(path: "M4 11h14M12 5l6 6-6 6"),
                                    label: "Schedule",
                                    sub: "Editing scheduled hours",
                                    value: Binding(
                                        get: { settings.strictProtectShorten },
                                        set: { newValue in
                                            if !newValue && settings.strictModeEnabled {
                                                showGate = ChallengeGateData(
                                                    title: "Stop guarding your schedule",
                                                    onPass: {
                                                        settings.strictProtectShorten = false
                                                    }
                                                )
                                            } else {
                                                settings.strictProtectShorten = newValue
                                            }
                                        }
                                    ),
                                    disabled: !settings.strictModeEnabled
                                )

                                ToggleRow(
                                    icon: SettIcon(systemName: "ticket"),
                                    label: "Fare",
                                    sub: "Changing type or difficulty",
                                    value: Binding(
                                        get: { settings.strictProtectChallenge },
                                        set: { newValue in
                                            if !newValue && settings.strictModeEnabled {
                                                showGate = ChallengeGateData(
                                                    title: "Stop guarding challenge settings",
                                                    onPass: {
                                                        settings.strictProtectChallenge = false
                                                    }
                                                )
                                            } else {
                                                settings.strictProtectChallenge = newValue
                                            }
                                        }
                                    ),
                                    disabled: !settings.strictModeEnabled,
                                    last: true
                                )
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.horizontal, 22)

                        FootNote(text: "Loosening any of these while Strict Mode is on asks for a fare first — on purpose.")
                            .padding(.horizontal, 22)

                        Spacer()
                            .frame(height: 24)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
        .sheet(item: $showGate) { data in
            ChallengeGate(
                data: data,
                difficulty: settings.challengeDifficulty.numericLevel
            )
            .presentationBackground(.clear)
        }
    }
}

#Preview {
    StrictModeEditorSheet(
        settings: SettingsManager.shared,
        onClose: {}
    )
}
