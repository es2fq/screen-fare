//
//  MainTabView.swift
//  Screen Fare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

// View state for challenge tab navigation
enum ChallengeViewState {
    case list
    case config
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    // Track drill-in state for tabs
    @State private var todayHistoryShowing = false
    @State private var challengeViewState: ChallengeViewState = .list
    @State private var challengeSelectedType: ChallengeType = .math
    @State private var blocksScheduleShowing = false
    @State private var blocksStrictModeShowing = false
    @State private var settingsActiveDetail: SettingsDetailScreen? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content with fade animations
            ZStack {
                // Tab 0: Today
                TodayView(showingHistoryView: $todayHistoryShowing, selectedTab: $selectedTab)
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .zIndex(selectedTab == 0 ? 1 : 0)

                // Tab 1: Blocks
                BlocksView(
                    selectedTab: $selectedTab,
                    showingScheduleEditor: $blocksScheduleShowing,
                    showingStrictModeEditor: $blocksStrictModeShowing
                )
                .opacity(selectedTab == 1 ? 1 : 0)
                .zIndex(selectedTab == 1 ? 1 : 0)

                // Tab 2: Fare/Challenges
                ChallengeTabView(
                    selectedTab: $selectedTab,
                    viewState: $challengeViewState,
                    selectedType: $challengeSelectedType
                )
                .opacity(selectedTab == 2 ? 1 : 0)
                .zIndex(selectedTab == 2 ? 1 : 0)

                // Tab 3: Settings
                SettingsTabView(selectedTab: $selectedTab, activeDetail: $settingsActiveDetail)
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .zIndex(selectedTab == 3 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.focusBg)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)

            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                todayHistoryShowing: $todayHistoryShowing,
                challengeViewState: $challengeViewState,
                blocksScheduleShowing: $blocksScheduleShowing,
                blocksStrictModeShowing: $blocksStrictModeShowing,
                settingsActiveDetail: $settingsActiveDetail
            )
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { oldValue, newValue in
            // Dismiss all drill-in views when switching tabs
            todayHistoryShowing = false
            blocksScheduleShowing = false
            blocksStrictModeShowing = false
            challengeViewState = .list
            settingsActiveDetail = nil
        }
    }
}

/// Custom tab bar matching exact design specs
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var todayHistoryShowing: Bool
    @Binding var challengeViewState: ChallengeViewState
    @Binding var blocksScheduleShowing: Bool
    @Binding var blocksStrictModeShowing: Bool
    @Binding var settingsActiveDetail: SettingsDetailScreen?

    private let tabs: [(icon: String, label: String)] = [
        ("clock", "Today"),
        ("shield", "Blocks"),
        ("ticket", "Fare"),
        ("gearshape", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    if selectedTab == index {
                        // Dismiss drill-in views when tapping active tab
                        if index == 0 && todayHistoryShowing {
                            todayHistoryShowing = false
                        } else if index == 1 && (blocksScheduleShowing || blocksStrictModeShowing) {
                            blocksScheduleShowing = false
                            blocksStrictModeShowing = false
                        } else if index == 2 && challengeViewState != .list {
                            challengeViewState = .list
                        } else if index == 3 && settingsActiveDetail != nil {
                            settingsActiveDetail = nil
                        }
                    } else {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 3) {
                        // Icon: 22x22px
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? .focusInk : .focusMuted)
                            .frame(width: 22, height: 22)

                        // Label: fontSize: 10.5px
                        Text(tabs[index].label)
                            .font(.inter(10.5))
                            .foregroundColor(selectedTab == index ? .focusInk : .focusMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.top, 8) // paddingTop: 8px
        .background(
            // background: rgba(245,242,237,0.92) with blur
            Color.focusBg.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(
                    // borderTop: 1px solid rgba(26,26,26,0.08)
                    Rectangle()
                        .fill(Color.focusLine)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// Environment key for selected tab
struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int>? = nil
}

extension EnvironmentValues {
    var selectedTab: Binding<Int>? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0))
}
