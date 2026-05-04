//
//  MainTabView.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AppsView()
                .tabItem {
                    Label("Apps", systemImage: "app.badge")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.primary)
    }
}

#Preview {
    MainTabView()
}
