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
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                Text("Choose Apps to Block")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Select which apps you want to require a challenge before opening")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                if hasSelectedApps {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("\(appCount) app\(appCount == 1 ? "" : "s") selected")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("You can always change this later in settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No apps selected yet")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("Tap the button below to choose apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showingPicker = true
                } label: {
                    Label(hasSelectedApps ? "Change Selection" : "Select Apps", systemImage: "plus.app")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(hasSelectedApps ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasSelectedApps ? Color.blue : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                .disabled(!hasSelectedApps)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selectedApps)
    }
}

#Preview {
    OnboardingAppSelectionView(selectedApps: .constant(FamilyActivitySelection()), onContinue: {})
}
