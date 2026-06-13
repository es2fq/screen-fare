//
//  BlocksView.swift
//  screenfare
//
//  Manage blocked apps, schedules, and strict mode
//  Design specs: app.jsx → BlocksScreen (lines 280-504)
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct BlocksView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @State private var showingPicker = false
    @State private var isEditing = false
    @State private var showAll = false
    @State private var showingScheduleEditor = false

    private let CAP = 11 // Show at most 11 apps before "show more"

    var body: some View {
        ZStack {
            // MAIN BLOCKS LAYER
            mainBlocksLayer
                .offset(x: showingScheduleEditor ? -90 : 0)
                .brightness(showingScheduleEditor ? -0.03 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: showingScheduleEditor)

            // SCHEDULE EDITOR LAYER
            scheduleEditorLayer
                .offset(x: showingScheduleEditor ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: showingScheduleEditor)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: -6, y: 0)
        }
        .familyActivityPicker(
            isPresented: $showingPicker,
            selection: $blockingManager.selectedApps
        )
        .onChange(of: blockingManager.selectedApps) { oldValue, newValue in
            // When apps/categories are added or removed, reapply blocking if currently active
            if blockingManager.isBlocking {
                blockingManager.applyBlocking()
                print("[BlocksView] 🔄 Selection changed, reapplying shields")
            }
        }
    }

    // MARK: - Main Blocks Layer

    private var mainBlocksLayer: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with title and Add button
                HStack(alignment: .bottom) {
                    Text("Blocks")
                        .font(.instrumentSerif(36))
                        .foregroundColor(.focusInk)

                    Spacer()

                    // Add button
                    Button(action: { showingPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.inter(13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.focusInk)
                        .cornerRadius(17)
                    }
                    .padding(.bottom, 2)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 0) {
                        // Two-card summary row
                        HStack(spacing: 10) {
                            // Apps count card (fixed width)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("APPS")
                                    .font(.inter(11, weight: .semibold))
                                    .foregroundColor(.focusMuted)
                                    .tracking(0.6)

                                Text("\(appCount)")
                                    .font(.instrumentSerif(32))
                                    .foregroundColor(.focusInk)
                            }
                            .frame(width: 100, alignment: .leading)
                            .frame(minHeight: 60) // Match card heights
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.focusLine, lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white)
                                    )
                            )

                            // Schedule card - tappable (expands to fill remaining space)
                            Button(action: { showingScheduleEditor = true }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SCHEDULE")
                                        .font(.inter(11, weight: .semibold))
                                        .foregroundColor(.focusMuted)
                                        .tracking(0.6)

                                    Text(scheduleManager.scheduleSummaryShort())
                                        .font(.instrumentSerif(32, italic: true))
                                        .foregroundColor(.focusInk)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 60) // Match the Apps card height
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.focusLine, lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Color.white)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.bottom, 18)

                        // Blocked apps section
                        BlockedAppsSection(
                            isEditing: $isEditing,
                            showAll: $showAll,
                            showingPicker: $showingPicker,
                            appCount: appCount,
                            cap: CAP
                        )

                        // Schedule section
                        ScheduleSection(scheduleManager: scheduleManager, showingScheduleEditor: $showingScheduleEditor)
                            .padding(.top, 22)

                        // Strict mode section
                        StrictModeSection()
                            .padding(.top, 22)

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Schedule Editor Layer

    private var scheduleEditorLayer: some View {
        ScheduleEditorSheet(
            scheduleManager: scheduleManager,
            onClose: { showingScheduleEditor = false }
        )
    }

    private var appCount: Int {
        blockingManager.selectedApps.applicationTokens.count +
        blockingManager.selectedApps.categoryTokens.count
    }
}

// MARK: - Blocked Apps Section

struct BlockedAppsSection: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @Binding var isEditing: Bool
    @Binding var showAll: Bool
    @Binding var showingPicker: Bool
    let appCount: Int
    let cap: Int

    var body: some View {
        let allApps = Array(blockingManager.selectedApps.applicationTokens)
        let allCategories = Array(blockingManager.selectedApps.categoryTokens)
        let totalItems = allApps.count + allCategories.count
        let overflow = !showAll && totalItems > cap + 1
        let visibleApps = overflow ? Array(allApps.prefix(min(cap, allApps.count))) : allApps
        let remainingCapacity = overflow ? 0 : max(0, cap - allApps.count)
        let visibleCategories = overflow ? [] : Array(allCategories.prefix(remainingCapacity))

        VStack(alignment: .leading, spacing: 0) {
            // Section header with Edit button
            HStack(alignment: .lastTextBaseline) {
                Text("BLOCKED APPS")
                    .font(.inter(11, weight: .semibold))
                    .foregroundColor(.focusMuted)
                    .tracking(0.6)

                Spacer()

                if appCount > 0 {
                    Button(action: { isEditing.toggle() }) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.inter(12.5, weight: .semibold))
                            .foregroundColor(isEditing ? .focusInk : .focusMuted)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            // Content
            if totalItems == 0 {
                // Empty state
                EmptyBlocksState(showingPicker: $showingPicker)
            } else {
                // Icon grid
                AppCard(padding: EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)) {
                    VStack(spacing: 0) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 18) {
                            // Display apps
                            ForEach(visibleApps, id: \.self) { token in
                                AppIconTile(
                                    token: token,
                                    isEditing: isEditing,
                                    onRemove: {
                                        removeApp(token: token)
                                    }
                                )
                            }

                            // Display categories
                            ForEach(visibleCategories, id: \.self) { token in
                                CategoryIconTile(
                                    token: token,
                                    isEditing: isEditing,
                                    onRemove: {
                                        removeCategory(token: token)
                                    }
                                )
                            }

                            // Show more button or Add apps tile
                            if overflow {
                                Button(action: { showAll = true }) {
                                    VStack {
                                        Text("+\(totalItems - cap)")
                                            .font(.instrumentSerif(19))
                                            .foregroundColor(.focusInk)
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(Color.focusInk.opacity(0.05))
                                    .cornerRadius(16)
                                }
                            } else if !isEditing {
                                Button(action: { showingPicker = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18))
                                        .foregroundColor(.focusMuted)
                                        .frame(width: 60, height: 60)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(
                                                    Color.focusInk.opacity(0.2),
                                                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                                                )
                                        )
                                }
                            }
                        }

                        // Show less button
                        if showAll && totalItems > cap + 1 {
                            Button(action: { showAll = false }) {
                                Text("Show less")
                                    .font(.inter(12.5, weight: .semibold))
                                    .foregroundColor(.focusMuted)
                            }
                            .padding(.top, 14)
                        }
                    }
                }
            }
        }
    }

    private func removeApp<T>(token: T) where T: Hashable {
        var updatedSelection = blockingManager.selectedApps
        updatedSelection.applicationTokens.remove(token as! ApplicationToken)
        blockingManager.selectedApps = updatedSelection
    }

    private func removeCategory<T>(token: T) where T: Hashable {
        var updatedSelection = blockingManager.selectedApps
        updatedSelection.categoryTokens.remove(token as! ActivityCategoryToken)
        blockingManager.selectedApps = updatedSelection
    }
}

// MARK: - App Icon Tile

struct AppIconTile: View {
    let token: Any
    let isEditing: Bool
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if let token = token as? ApplicationToken {
                    Label(token)
                        .labelStyle(.iconOnly)
                        .frame(width: 42, height: 42)
                        .scaleEffect(1.5)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.focusLine, lineWidth: 1)
            )
            .cornerRadius(16)
            .scaleEffect(isEditing ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isEditing)

            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.focusInk)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Category Icon Tile

struct CategoryIconTile: View {
    let token: Any
    let isEditing: Bool
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if let token = token as? ActivityCategoryToken {
                    Label(token)
                        .labelStyle(.iconOnly)
                        .frame(width: 42, height: 42)
                        .scaleEffect(1.5)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.focusLine, lineWidth: 1)
            )
            .cornerRadius(16)
            .scaleEffect(isEditing ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isEditing)

            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.focusInk)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyBlocksState: View {
    @Binding var showingPicker: Bool

    var body: some View {
        AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: "app.dashed")
                    .font(.system(size: 42))
                    .foregroundColor(.focusMuted.opacity(0.4))
                    .padding(.top, 32)

                // Title
                (Text("Nothing blocked ")
                    .font(.inter(15, weight: .medium))
                 + Text("yet.")
                    .font(.instrumentSerif(15, italic: true)))
                    .foregroundColor(.focusInk)

                // Body
                Text("Add the apps that pull you in. They'll ask for a fare before they open.")
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                // Add apps button
                Button(action: { showingPicker = true }) {
                    HStack(spacing: 7) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Add apps")
                            .font(.inter(14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Color.focusInk)
                    .cornerRadius(21)
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Schedule Section

struct ScheduleSection: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var showingScheduleEditor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("SCHEDULE")
                .font(.inter(11, weight: .semibold))
                .foregroundColor(.focusMuted)
                .tracking(0.6)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            Button(action: { showingScheduleEditor = true }) {
                AppCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16)) {
                    VStack(spacing: 14) {
                        // Mode info header
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scheduleManager.schedule.mode == .allday ? "Active all day" : "Scheduled hours")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk)

                                Text(scheduleManager.schedule.mode == .allday ? "Every hour, every day" : "\(scheduleManager.schedule.windows.count) \(scheduleManager.schedule.windows.count == 1 ? "window" : "windows")")
                                    .font(.inter(12.5))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.focusMuted)
                        }

                        // Timeline
                        TimelineBar(
                            windows: scheduleManager.schedule.windows,
                            allday: scheduleManager.schedule.mode == .allday,
                            height: 34,
                            showLabels: true,
                            showNow: true
                        )

                        // Window details (only for scheduled mode)
                        if scheduleManager.schedule.mode == .scheduled {
                            VStack(spacing: 8) {
                                ForEach(scheduleManager.schedule.windows) { window in
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text("\(minToLabel(window.start)) – \(minToLabel(window.end))")
                                            .font(.inter(13.5))
                                            .foregroundColor(.focusInk)
                                            .monospacedDigit()

                                        Spacer()

                                        Text(formatDays(window.days))
                                            .font(.inter(12))
                                            .foregroundColor(.focusMuted)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Strict Mode Section

struct StrictModeSection: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("STRICT MODE")
                .font(.inter(11, weight: .semibold))
                .foregroundColor(.focusMuted)
                .tracking(0.6)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            AppCard(padding: EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.focusInk.opacity(0.06))
                            .frame(width: 32, height: 32)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.focusInk)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock changes")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(.focusInk)

                        Text("Require challenge to remove apps")
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()

                    CustomToggle(
                        isOn: $settings.strictModeEnabled,
                        trackColorOn: .focusInk
                    )
                }
                .padding(.vertical, 14)
            }
        }
    }
}

#Preview {
    BlocksView()
}
