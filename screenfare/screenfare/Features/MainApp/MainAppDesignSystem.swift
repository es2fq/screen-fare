//
//  MainAppDesignSystem.swift
//  Screen Fare
//
//  Design system for Screen Fare main app screens
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
                }
            }
            .safeAreaPadding(.top) // Use actual safe area for status bar
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

// MARK: - Empty State

/// Reusable empty state component matching design specs from empty-states.jsx
/// Design: thin-stroke icon in a soft disc, Instrument Serif title, muted explanation
struct EmptyState: View {
    let icon: AnyView
    let title: Text
    let message: String
    var padding: EdgeInsets = EdgeInsets(top: 36, leading: 22, bottom: 36, trailing: 22)

    init(icon: AnyView, title: Text, message: String, padding: EdgeInsets = EdgeInsets(top: 36, leading: 22, bottom: 36, trailing: 22)) {
        self.icon = icon
        self.title = title
        self.message = message
        self.padding = padding
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon in circular background (52pt)
            ZStack {
                Circle()
                    .fill(Color.focusInk.opacity(0.05))
                    .frame(width: 52, height: 52)

                icon
            }
            .padding(.bottom, 16)

            // Title in Instrument Serif (22pt)
            title
                .font(.instrumentSerif(22))
                .foregroundColor(.focusInk)
                .tracking(22 * -0.01) // -0.01em letter-spacing
                .lineSpacing(22 * 0.1) // 1.1 line height
                .padding(.bottom, 7)

            // Body text (13pt, muted)
            Text(message)
                .font(.inter(13))
                .foregroundColor(.focusMuted)
                .lineSpacing(13 * 0.5) // 1.5 line height
                .multilineTextAlignment(.center)
                .frame(maxWidth: 244)
        }
        .frame(maxWidth: .infinity)
        .padding(padding)
    }
}

// MARK: - Empty State Icons

/// Icon collection for empty states - thin stroke, monochrome design
struct EmptyStateIcons {
    /// Clock icon for "Recent" empty state
    static func recent(color: Color = .focusInk) -> AnyView {
        AnyView(
            ZStack {
                // Main clock circle with rotating arrow
                Path { path in
                    // Clock circle
                    path.addArc(
                        center: CGPoint(x: 12, y: 12),
                        radius: 8.5,
                        startAngle: .degrees(230),
                        endAngle: .degrees(590),
                        clockwise: false
                    )
                }
                .stroke(color, lineWidth: 1.6)

                // Arrow head at top left
                Path { path in
                    path.move(to: CGPoint(x: 5.5, y: 3.4))
                    path.addLine(to: CGPoint(x: 5.5, y: 6.6))
                    path.addLine(to: CGPoint(x: 8.7, y: 6.6))
                }
                .stroke(color, lineWidth: 1.6)

                // Clock hands
                Path { path in
                    // Hour hand (pointing up)
                    path.move(to: CGPoint(x: 12, y: 7.5))
                    path.addLine(to: CGPoint(x: 12, y: 12))
                    // Minute hand (pointing to 2 o'clock)
                    path.addLine(to: CGPoint(x: 15, y: 13.8))
                }
                .stroke(color, lineWidth: 1.6)
            }
            .frame(width: 24, height: 24)
        )
    }
}
