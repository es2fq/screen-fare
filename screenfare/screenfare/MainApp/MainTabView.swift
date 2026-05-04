//
//  MainTabView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    TodayView()
                case 1:
                    BlocksView()
                case 2:
                    ChallengeTabView()
                case 3:
                    SettingsTabView()
                default:
                    TodayView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

/// Custom tab bar matching exact design specs
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Today"),
        ("app.badge", "Blocks"),
        ("brain", "Challenge"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
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
        .padding(.bottom, 28) // paddingBottom: 28px
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
        )
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    MainTabView()
}
