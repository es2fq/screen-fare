//
//  MainAppDesignSystem.swift
//  screenfare
//
//  Design system for Focus main app screens
//  Matches the Anthropic design specifications exactly
//

import SwiftUI

// MARK: - App Shell Components

/// Standard app screen with large title
struct AppScreen<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Large title: padding: 12px 22px 16px, fontSize: 36px
                Text(title)
                    .font(.instrumentSerif(36))
                    .foregroundColor(.focusInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // Content: padding: 0 22px
                ScrollView {
                    content
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                }
            }
            .padding(.top, 60) // paddingTop: 60px
            .padding(.bottom, 90) // paddingBottom: 90px (with tab bar)
        }
    }
}

/// Standard card component
struct AppCard<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)

    init(padding: EdgeInsets = EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18), @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.focusLine, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.focusCard)
                    )
            )
    }
}

// MARK: - Section Title

struct SectionTitle: View {
    let text: String

    var body: some View {
        // fontSize: 11px, uppercase, letterSpacing: 0.12em
        Text(text.uppercased())
            .font(.inter(11, weight: .medium))
            .foregroundColor(.focusMuted)
            .tracking(11 * 0.12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
