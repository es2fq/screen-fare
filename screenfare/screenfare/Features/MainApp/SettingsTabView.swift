//
//  SettingsTabView.swift
//  Screen Fare
//
//  App settings and preferences
//

import SwiftUI

enum SettingsDetailScreen {
    // case account
    case permissions
    case dataPrivacy
    case about
}

struct SettingsTabView: View {
    @StateObject private var settings = SettingsManager.shared

    // Navigation state
    @Binding var selectedTab: Int
    @State private var activeDetail: SettingsDetailScreen?
    @State private var dragOffset: CGFloat = 0

    init(selectedTab: Binding<Int> = .constant(3)) {
        _selectedTab = selectedTab
    }

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
                .animation(nil, value: dragOffset) // Don't animate background during drag

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
                difficulty: settings.challengeDifficulty.numericLevel
            )
            .presentationBackground(.clear)
        }
        .onChange(of: showToast) { oldValue, newValue in
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
                VStack(spacing: 0) {
                    // MARK: - Account card (commented out)
                    /*
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
                    */

                    // System section
                    SectionTitle(text: "System")

                    AppCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: SettIcon(path: "M4 6h14v9H4zM4 18h14M9 18v2h4v-2"),
                                label: "Permissions",
                                sub: "Configure permissions",
                                right: AnyView(
                                    HStack(spacing: 8) {
                                        if pendingPermissionsCount > 0 {
                                            StatusPill(text: "\(pendingPermissionsCount) to allow", tone: .warn)
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
                                sub: "No data collected or shared",
                                right: AnyView(Chevron()),
                                action: {
                                    activeDetail = .dataPrivacy
                                }
                            )

                            SettingsRow(
                                icon: SettIcon(path: "M11 16v0M8.5 8.5a2.5 2.5 0 014.6 1.3c0 1.7-2.1 1.9-2.1 3.2", circle: "11,11,8"),
                                label: "About & support",
                                sub: "Version 1.0",
                                right: AnyView(Chevron()),
                                last: true,
                                action: {
                                    activeDetail = .about
                                }
                            )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Spacer()
                        .frame(height: 26)

                    // Tagline
//                    Text("Screen Fare, by design.")
//                        .font(.instrumentSerif(18, italic: true))
//                        .foregroundColor(.focusMuted)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.bottom, 24)
                }
        }
    }

    // MARK: - Detail Panels Layer

    private var detailPanelsLayer: some View {
        ZStack {
            // MARK: - Account detail (commented out)
            /*
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
            .offset(x: activeDetail == .account ? dragOffset : UIScreen.main.bounds.width)
            .shadow(color: Color.black.opacity(activeDetail == .account ? 0.06 : 0), radius: 15, x: -6, y: 0)
            .opacity(selectedTab == 3 ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .animation(.interactiveSpring(), value: dragOffset)
            .swipeBackGesture(isActive: activeDetail == .account, dragOffset: $dragOffset, onDismiss: { activeDetail = nil })
            */

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
            .offset(x: activeDetail == .permissions ? dragOffset : UIScreen.main.bounds.width)
            .shadow(color: Color.black.opacity(activeDetail == .permissions ? 0.06 : 0), radius: 15, x: -6, y: 0)
            .opacity(selectedTab == 3 ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .animation(.interactiveSpring(), value: dragOffset)
            .swipeBackGesture(isActive: activeDetail == .permissions, dragOffset: $dragOffset, onDismiss: { activeDetail = nil })

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
            .offset(x: activeDetail == .dataPrivacy ? dragOffset : UIScreen.main.bounds.width)
            .shadow(color: Color.black.opacity(activeDetail == .dataPrivacy ? 0.06 : 0), radius: 15, x: -6, y: 0)
            .opacity(selectedTab == 3 ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .animation(.interactiveSpring(), value: dragOffset)
            .swipeBackGesture(isActive: activeDetail == .dataPrivacy, dragOffset: $dragOffset, onDismiss: { activeDetail = nil })

            // About detail
            DetailPanel(
                title: "About",
                onBack: { activeDetail = nil }
            ) {
                AboutDetailView(showToast: $showToast)
            }
            .offset(x: activeDetail == .about ? dragOffset : UIScreen.main.bounds.width)
            .shadow(color: Color.black.opacity(activeDetail == .about ? 0.06 : 0), radius: 15, x: -6, y: 0)
            .opacity(selectedTab == 3 ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.88), value: activeDetail)
            .animation(.interactiveSpring(), value: dragOffset)
            .swipeBackGesture(isActive: activeDetail == .about, dragOffset: $dragOffset, onDismiss: { activeDetail = nil })
        }
    }

    private var permissionsSummary: String {
        let screenTime = settings.screenTimePermission == .granted ? "on" : "off"
        let notifications = settings.notificationPermission == .granted ? "on" : "off"
        return "Screen Time \(screenTime) · Notifications \(notifications)"
    }

    private var pendingPermissionsCount: Int {
        var count = 0
        if settings.screenTimePermission != .granted { count += 1 }
        if settings.notificationPermission != .granted { count += 1 }
        // TODO: Re-enable once we have a step challenge
        // if settings.healthPermission != .granted { count += 1 }
        return count
    }
}

#Preview {
    SettingsTabView()
}
