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
    let onContinue: () -> Void

    private var hasSelectedApps: Bool {
        !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty
    }

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Choose Apps")
                    .font(.system(size: 34, weight: .bold))

                if hasSelectedApps {
                    AppFacepile(selectedApps: selectedApps)
                        .padding(.top, 8)

                    Text("\(appCount) app\(appCount == 1 ? "" : "s") selected")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Select apps to block")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }

            Spacer()

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
                .padding(.horizontal, 32)

                if hasSelectedApps {
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 16)
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selectedApps)
    }
}

struct AppFacepile: View {
    let selectedApps: FamilyActivitySelection

    private var totalCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    var body: some View {
        HStack(spacing: -12) {
            // Show up to 5 app icons
            ForEach(Array(selectedApps.applicationTokens.prefix(5)), id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color(UIColor.systemBackground)))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
            }

            // Show overflow count if more than 5
            if totalCount > 5 {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text("+\(totalCount - 5)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
                .overlay(
                    Circle()
                        .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                )
            }
        }
    }
}

#Preview {
    OnboardingAppSelectionView(selectedApps: .constant(FamilyActivitySelection()), onContinue: {})
}
