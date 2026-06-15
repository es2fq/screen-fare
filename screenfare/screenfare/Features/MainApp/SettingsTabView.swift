//
//  SettingsTabView.swift
//  screenfare
//
//  App settings and preferences
//

import SwiftUI

enum SettingsDetailScreen {
    case account
    case strictMode
    case permissions
    case dataPrivacy
    case about
}

struct SettingsTabView: View {
    @StateObject private var settings = SettingsManager.shared

    // Navigation state
    @State private var activeDetail: SettingsDetailScreen?

    // Modal state
    @State private var showToast: ToastData?
    @State private var showConfirm: ConfirmDialogData?
    @State private var showGate: ChallengeGateData?

    var body: some View {
        ZStack {
            // Main settings list
            settingsListLayer
                .offset(x: activeDetail != nil ? -90 : 0)
                .brightness(activeDetail != nil ? -0.03 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)

            // Detail panels
            detailPanelsLayer
        }
        .overlay(alignment: .bottom) {
            // Toast notifications
            SettingsToast(toast: showToast)
        }
        .sheet(item: $showConfirm) { data in
            ConfirmDialog(data: data)
                .presentationDetents([.height(280)])
                .presentationBackground(.clear)
        }
        .sheet(item: $showGate) { data in
            ChallengeGate(
                data: data,
                difficulty: Int(settings.challengeDifficulty.rawValue) ?? 3
            )
            .presentationDetents([.height(380)])
            .presentationBackground(.clear)
        }
        .onChange(of: showToast) { newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    showToast = nil
                }
            }
        }
    }

    // MARK: - Settings List Layer

    private var settingsListLayer: some View {
        AppScreen(title: "Settings") {
                VStack(spacing: 18) {
                    // Account card
                    Button(action: { activeDetail = .account }) {
                        AppCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                            HStack(spacing: 14) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(Color.focusAccent)
                                        .frame(width: 52, height: 52)

                                    Text(String(settings.userName.prefix(1).lowercased()))
                                        .font(.instrumentSerif(24, italic: true))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.userName)
                                        .font(.inter(16, weight: .semibold))
                                        .foregroundColor(.focusInk)

                                    Text("\(settings.userEmail) · \(settings.iCloudSyncEnabled ? "Synced" : "Local only")")
                                        .font(.inter(12.5))
                                        .foregroundColor(.focusMuted)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                Chevron()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Protection section
                    SectionTitle(text: "Protection")

                    AppCard {
                        SettingsRow(
                            icon: SettIcon(path: "M5 9h12v9H5zM8 9V6a3 3 0 016 0v3"),
                            label: "Strict Mode",
                            sub: settings.strictModeEnabled ? "Locks the moves that undo your blocks" : "Off — blocks can be changed freely",
                            right: AnyView(Chevron()),
                            last: true,
                            action: {
                                activeDetail = .strictMode
                            }
                        )
                    }

                    // System section
                    SectionTitle(text: "System")

                    AppCard {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: SettIcon(path: "M4 6h14v9H4zM4 18h14M9 18v2h4v-2"),
                                label: "Permissions",
                                sub: permissionsSummary,
                                right: AnyView(
                                    HStack(spacing: 8) {
                                        if settings.healthPermission != .granted {
                                            StatusPill(text: "1 to allow", tone: .warn)
                                        }
                                        Chevron()
                                    }
                                ),
                                action: {
                                    activeDetail = .permissions
                                }
                            )

                            SettingsRow(
                                icon: SettIcon(path: "M11 3v11M6 9l5 5 5-5M4 18h14"),
                                label: "Data & privacy",
                                sub: "Sync, export & reset",
                                right: AnyView(Chevron()),
                                action: {
                                    activeDetail = .dataPrivacy
                                }
                            )

                            SettingsRow(
                                icon: SettIcon(path: "M11 16v0M8.5 8.5a2.5 2.5 0 014.6 1.3c0 1.7-2.1 1.9-2.1 3.2", circle: "11,11,8"),
                                label: "About & support",
                                sub: "Version 1.0 · help · rate",
                                right: AnyView(Chevron()),
                                last: true,
                                action: {
                                    activeDetail = .about
                                }
                            )
                        }
                    }

                    Spacer()
                        .frame(height: 26)

                    // Tagline
                    Text("Screen Fare, by design.")
                        .font(.instrumentSerif(18, italic: true))
                        .foregroundColor(.focusMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 24)
                }
        }
    }

    // MARK: - Detail Panels Layer

    private var detailPanelsLayer: some View {
        ZStack {
            // Account detail
            DetailPanel(
                title: "Account",
                onBack: { activeDetail = nil }
            ) {
                AccountDetailView(
                    settings: settings,
                    showToast: $showToast,
                    showConfirm: $showConfirm
                )
            }
            .offset(x: activeDetail == .account ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .shadow(color: Color.black.opacity(activeDetail == .account ? 0.06 : 0), radius: 15, x: -6, y: 0)

            // Strict Mode detail
            DetailPanel(
                title: "Strict Mode",
                onBack: { activeDetail = nil }
            ) {
                StrictModeDetailView(
                    settings: settings,
                    showGate: $showGate
                )
            }
            .offset(x: activeDetail == .strictMode ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .shadow(color: Color.black.opacity(activeDetail == .strictMode ? 0.06 : 0), radius: 15, x: -6, y: 0)

            // Permissions detail
            DetailPanel(
                title: "Permissions",
                onBack: { activeDetail = nil }
            ) {
                PermissionsDetailView(
                    settings: settings,
                    showToast: $showToast
                )
            }
            .offset(x: activeDetail == .permissions ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .shadow(color: Color.black.opacity(activeDetail == .permissions ? 0.06 : 0), radius: 15, x: -6, y: 0)

            // Data & Privacy detail
            DetailPanel(
                title: "Data & privacy",
                onBack: { activeDetail = nil }
            ) {
                DataPrivacyDetailView(
                    settings: settings,
                    showToast: $showToast,
                    showConfirm: $showConfirm
                )
            }
            .offset(x: activeDetail == .dataPrivacy ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .shadow(color: Color.black.opacity(activeDetail == .dataPrivacy ? 0.06 : 0), radius: 15, x: -6, y: 0)

            // About detail
            DetailPanel(
                title: "About",
                onBack: { activeDetail = nil }
            ) {
                AboutDetailView(showToast: $showToast)
            }
            .offset(x: activeDetail == .about ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .shadow(color: Color.black.opacity(activeDetail == .about ? 0.06 : 0), radius: 15, x: -6, y: 0)
        }
    }

    private var permissionsSummary: String {
        let screenTime = settings.screenTimePermission == .granted ? "on" : "off"
        let health = settings.healthPermission == .granted ? "on" : "off"
        return "Screen Time \(screenTime) · Health \(health)"
    }
}

#Preview {
    SettingsTabView()
}
