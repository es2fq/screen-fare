//
//  AppsView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI
import FamilyControls

struct AppsView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !blockingManager.isAuthorized {
                    // Authorization needed
                    VStack(spacing: 20) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 70))
                            .foregroundColor(.blue.opacity(0.7))

                        Text("Screen Time Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("ScreenFare needs Screen Time permission to block apps and help you stay focused")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button {
                            Task {
                                try? await blockingManager.requestAuthorization()
                            }
                        } label: {
                            Text("Grant Permission")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    }
                    .padding(.top, 60)
                } else {
                    // Authorized - show app selection
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "app.badge.checkmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue.opacity(0.7))

                                Text("Blocked Apps")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                if hasSelectedApps {
                                    Text("\(appCount) app\(appCount == 1 ? "" : "s") selected")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No apps blocked yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 20)

                            // Action buttons
                            VStack(spacing: 12) {
                                Button {
                                    showingPicker = true
                                } label: {
                                    Label(hasSelectedApps ? "Edit Selection" : "Select Apps", systemImage: "plus.app")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }

                                if hasSelectedApps {
                                    Button {
                                        blockingManager.applyBlocking()
                                    } label: {
                                        Label("Apply Blocking", systemImage: "shield.fill")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(12)
                                    }

                                    Button {
                                        blockingManager.removeBlocking()
                                        blockingManager.selectedApps = FamilyActivitySelection()
                                    } label: {
                                        Label("Clear All", systemImage: "trash")
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Info card
                            if hasSelectedApps {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("How it works", systemImage: "info.circle")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("When you try to open a blocked app, you'll see a shield screen. Tap the unlock button to open ScreenFare and complete a challenge.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Apps")
            .familyActivityPicker(
                isPresented: $showingPicker,
                selection: $blockingManager.selectedApps
            )
        }
    }

    private var hasSelectedApps: Bool {
        !blockingManager.selectedApps.applicationTokens.isEmpty ||
        !blockingManager.selectedApps.categoryTokens.isEmpty
    }

    private var appCount: Int {
        blockingManager.selectedApps.applicationTokens.count +
        blockingManager.selectedApps.categoryTokens.count
    }
}

#Preview {
    AppsView()
}
