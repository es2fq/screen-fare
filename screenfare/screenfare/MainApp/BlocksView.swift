//
//  BlocksView.swift
//  screenfare
//
//  Manage blocked apps, schedules, and strict mode
//

import SwiftUI
import FamilyControls

struct BlocksView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @State private var showingPicker = false

    var body: some View {
        AppScreen(title: "Blocks") {
            VStack(spacing: 18) {
                // Manage apps card
                AppCard {
                    Button(action: { showingPicker = true }) {
                        HStack(spacing: 14) {
                            // Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.focusInk.opacity(0.06))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "app.badge.checkmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(.focusInk)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manage apps")
                                    .font(.inter(15, weight: .semibold))
                                    .foregroundColor(.focusInk)

                                Text("\(appCount) app\(appCount == 1 ? "" : "s") blocked")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.focusMuted)
                        }
                    }
                }
                .familyActivityPicker(
                    isPresented: $showingPicker,
                    selection: $blockingManager.selectedApps
                )

                // App list
                if hasSelectedApps {
                    SectionTitle(text: "Blocked apps")

                    AppCard {
                        VStack(spacing: 14) {
                            ForEach(Array(blockingManager.selectedApps.applicationTokens).indices, id: \.self) { index in
                                let tokens = Array(blockingManager.selectedApps.applicationTokens)
                                let token = tokens[index]

                                HStack(spacing: 12) {
                                    Label(token)
                                        .labelStyle(.iconOnly)
                                        .frame(width: 44, height: 44)
                                        .background(Color.focusCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 11))

                                    Label(token)
                                        .labelStyle(.titleOnly)
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(.focusInk)

                                    Spacer()

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.focusAccent)
                                }
                                .padding(.vertical, 4)

                                if index < tokens.count - 1 {
                                    Divider().background(Color.focusLine)
                                }
                            }
                        }
                    }
                }

                // Schedule section
                SectionTitle(text: "Schedule")

                AppCard {
                    VStack(spacing: 14) {
                        // All day option
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("All day")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk)

                                Text("Block apps 24/7")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .tint(Color.focusAccent)
                        }

                        Divider().background(Color.focusLine)

                        // Custom schedule (disabled state)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom schedule")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk.opacity(0.5))

                                Text("Coming soon")
                                    .font(.inter(13))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()
                        }
                    }
                }

                // Strict mode section
                SectionTitle(text: "Strict mode")

                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Challenge required")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(.focusInk)

                            Text("Solve math problems to unlock")
                                .font(.inter(13))
                                .foregroundColor(.focusMuted)
                        }

                        Spacer()

                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Color.focusAccent)
                    }
                }
            }
        }
    }

    private var hasSelectedApps: Bool {
        !blockingManager.selectedApps.applicationTokens.isEmpty
    }

    private var appCount: Int {
        blockingManager.selectedApps.applicationTokens.count +
        blockingManager.selectedApps.categoryTokens.count
    }
}

#Preview {
    BlocksView()
}
