//
//  StrictModeDetailView.swift
//  Screen Fare
//
//  Strict Mode settings detail screen
//

import SwiftUI

struct StrictModeDetailView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var showGate: ChallengeGateData?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Intro note
            IntroNote(text: "The fare only works if you can't skip it. Strict Mode puts a fare in front of the moves that quietly undo your blocks — so a moment of weakness costs more than a tap.")

            // Main toggle
            AppCard {
                ToggleRow(
                    icon: SettIcon(path: "M5 9h12v9H5zM8 9V6a3 3 0 016 0v3", viewBox: "22 22"),
                    label: "Strict Mode",
                    sub: settings.strictModeEnabled ? "On — the protections below are active" : "Off — anything can be changed freely",
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
            }

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
                .padding(.horizontal, 2)
                .padding(.top, 14)
                .padding(.bottom, 4)
            }

            // Protection settings
            SectionTitle(text: "Require a fare before")

            AppCard {
                VStack(spacing: 0) {
                    ToggleRow(
                        icon: SettIcon(path: "M11 5v6l3 3", circle: "11,11,7.5"),
                        label: "Turning Screen Fare off",
                        sub: "Also covers pausing protection",
                        value: Binding(
                            get: { settings.strictProtectOff },
                            set: { newValue in
                                if !newValue && settings.strictModeEnabled {
                                    showGate = ChallengeGateData(
                                        title: "Stop guarding the off switch",
                                        onPass: {
                                            settings.strictProtectOff = false
                                        }
                                    )
                                } else {
                                    settings.strictProtectOff = newValue
                                }
                            }
                        ),
                        disabled: !settings.strictModeEnabled
                    )

                    ToggleRow(
                        icon: SettIcon(path: "M5 7h12M5 15h12M9 4l-2 14M15 4l-2 14"),
                        label: "Removing blocked apps",
                        sub: "Editing or clearing your blocklist",
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
                        label: "Shortening the schedule",
                        sub: "Cutting your scheduled blocking hours",
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
                        disabled: !settings.strictModeEnabled,
                        last: true
                    )
                }
            }

            FootNote(text: "Loosening any of these while Strict Mode is on asks for a fare first — on purpose.")

            Spacer()
                .frame(height: 12)
        }
    }
}
