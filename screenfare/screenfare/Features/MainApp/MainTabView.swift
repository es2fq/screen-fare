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
    @State private var challengeViewState: ChallengeViewState = .list
    @State private var challengeSelectedType: ChallengeType = .math
    @State private var blocksScheduleShowing = false
    @State private var blocksStrictModeShowing = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            ZStack {
                if selectedTab == 0 {
                    TodayView()
                }
                if selectedTab == 1 {
                    BlocksView(
                        showingScheduleEditor: $blocksScheduleShowing,
                        showingStrictModeEditor: $blocksStrictModeShowing
                    )
                }
                if selectedTab == 2 {
                    ChallengeTabView(
                        viewState: $challengeViewState,
                        selectedType: $challengeSelectedType
                    )
                }
                if selectedTab == 3 {
                    SettingsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                challengeViewState: $challengeViewState,
                blocksScheduleShowing: $blocksScheduleShowing,
                blocksStrictModeShowing: $blocksStrictModeShowing
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

/// Custom tab bar matching exact design specs
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var challengeViewState: ChallengeViewState
    @Binding var blocksScheduleShowing: Bool
    @Binding var blocksStrictModeShowing: Bool

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
                        if index == 2 && challengeViewState != .list {
                            challengeViewState = .list
                        } else if index == 1 && (blocksScheduleShowing || blocksStrictModeShowing) {
                            blocksScheduleShowing = false
                            blocksStrictModeShowing = false
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
