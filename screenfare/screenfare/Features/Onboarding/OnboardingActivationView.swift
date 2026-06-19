//
//  OnboardingActivationView.swift
//  Screen Fare
//
//  Created by Claude on 6/19/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

/// The activation animation screen that plays after the user taps "Activate".
/// Shows a scanning/sealing animation that stamps each selected app with a lock badge.
struct OnboardingActivationView: View {
    let selectedApps: FamilyActivitySelection
    let duration: TimeInterval
    let onComplete: () -> Void

    // Animation phases: 0 = gather, 1 = sealing, 2 = confirmed
    @State private var phase: Int = 0
    @State private var reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled

    private var appCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }

    private var durationFormatted: String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }

    // Get array of items to display (max 9)
    private var displayItems: [(id: String, view: AnyView)] {
        var items: [(id: String, view: AnyView)] = []

        // Add category tokens
        let sortedCategories = selectedApps.categoryTokens.sorted(by: { $0.hashValue < $1.hashValue })
        for (index, token) in sortedCategories.prefix(9).enumerated() {
            items.append((
                id: "cat-\(index)",
                view: AnyView(
                    Label(token)
                        .labelStyle(.iconOnly)
                        .scaleEffect(1.5)
                        .frame(width: 56, height: 56)
                )
            ))
        }

        // Add app tokens (up to 9 total)
        let remaining = 9 - items.count
        let sortedApps = selectedApps.applicationTokens.sorted(by: { $0.hashValue < $1.hashValue })
        for (index, token) in sortedApps.prefix(remaining).enumerated() {
            items.append((
                id: "app-\(index)",
                view: AnyView(
                    Label(token)
                        .labelStyle(.iconOnly)
                        .scaleEffect(1.5)
                        .frame(width: 56, height: 56)
                )
            ))
        }

        return items
    }

    private var extraCount: Int {
        max(0, appCount - displayItems.count)
    }

    private var columnCount: Int {
        displayItems.count <= 4 ? displayItems.count : 3
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 18)

                // Status / headline — crossfades from "arming" to "on"
                ZStack {
                    // Arming state
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.focusAccent)
                                .frame(width: 7, height: 7)
                                .opacity(phase < 2 && !reduceMotion ? 1 : 0)
                                .modifier(PulseModifier(isAnimating: phase < 2 && !reduceMotion))

                            Text("RAISING THE GATE")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(.focusMuted)
                                .tracking(11 * 0.18)
                        }

                        (Text("Sealing your apps")
                            .font(.instrumentSerif(34))
                         + Text("\nbehind a ")
                            .font(.instrumentSerif(34))
                         + Text("fare.")
                            .font(.instrumentSerif(34, italic: true)))
                            .foregroundColor(.focusInk)
                            .lineSpacing(34 * 0.05)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(phase < 2 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.32), value: phase)

                    // Confirmed state
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.focusAccent)
                                .frame(width: 7, height: 7)

                            Text("SCREEN FARE IS ON")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(.focusMuted)
                                .tracking(11 * 0.18)
                        }

                        (Text("The gate is ")
                            .font(.instrumentSerif(34))
                         + Text("up.")
                            .font(.instrumentSerif(34, italic: true)))
                            .foregroundColor(.focusInk)
                            .lineSpacing(34 * 0.05)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(phase >= 2 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.38).delay(0.12), value: phase)
                }
                .frame(minHeight: 132)
                .padding(.bottom, 20)

                // App grid with scanning animation
                Spacer()

                AppGridView(
                    items: displayItems,
                    extraCount: extraCount,
                    columns: columnCount,
                    isSealing: phase >= 1,
                    reduceMotion: reduceMotion
                )

                Spacer()

                // Footer spacer
                Spacer()
                    .frame(height: 104)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        if reduceMotion {
            // Skip to final phase immediately, then transition to main app
            phase = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        } else {
            // Phase 0 → 1: Gather complete, start sealing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
                withAnimation {
                    phase = 1
                }
            }

            // Phase 1 → 2: Sealing complete, show confirmed
            let sealDuration = 0.52 + Double(displayItems.count) * 0.12 + 0.36
            DispatchQueue.main.asyncAfter(deadline: .now() + sealDuration) {
                withAnimation {
                    phase = 2
                }

                // Auto-transition to main app after showing confirmation
                DispatchQueue.main.asyncAfter(deadline: .now() + sealDuration + 1.0) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - App Grid View

struct AppGridView: View {
    let items: [(id: String, view: AnyView)]
    let extraCount: Int
    let columns: Int
    let isSealing: Bool
    let reduceMotion: Bool

    private let tileSize: CGFloat = 84
    private let spacing: CGFloat = 16

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(tileSize), spacing: spacing), count: columns)
    }

    var body: some View {
        ZStack {
            // Sweeping seal light (only during sealing phase)
            if isSealing && !reduceMotion {
                SweepingLightView(
                    itemCount: items.count,
                    columns: columns,
                    tileSize: tileSize,
                    spacing: spacing
                )
            }

            // App grid
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    AppTileView(
                        content: item.view,
                        index: index,
                        isSealed: isSealing,
                        reduceMotion: reduceMotion
                    )
                }

                // Extra count tile
                if extraCount > 0 {
                    ExtraTileView(
                        count: extraCount,
                        index: items.count,
                        reduceMotion: reduceMotion
                    )
                }
            }
        }
    }
}

// MARK: - App Tile View

struct AppTileView: View {
    let content: AnyView
    let index: Int
    let isSealed: Bool
    let reduceMotion: Bool

    @State private var isVisible: Bool = false

    private let tileSize: CGFloat = 84

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.focusCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.focusLine, lineWidth: 1)
                )
                .shadow(color: isSealed ? Color.focusAccent : Color.black.opacity(0.06),
                        radius: isSealed ? 0 : 3,
                        x: 0,
                        y: isSealed ? 0 : 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.focusAccent, lineWidth: isSealed ? 2 : 0)
                )

            content
                .opacity(isSealed ? 0.5 : 1)

            // Lock seal badge (appears during sealing)
            if isSealed {
                SealBadgeView()
                    .offset(x: tileSize / 2 - 7, y: -tileSize / 2 + 7)
                    .modifier(StampModifier(
                        index: index,
                        reduceMotion: reduceMotion
                    ))
            }
        }
        .frame(width: tileSize, height: tileSize)
        .opacity(isVisible || reduceMotion ? 1 : 0)
        .offset(y: isVisible || reduceMotion ? 0 : 14)
        .scaleEffect(isVisible || reduceMotion ? 1 : 0.92)
        .animation(.interpolatingSpring(stiffness: 280, damping: 20).delay(Double(index) * 0.055), value: isVisible)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                // Trigger tile-in animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Extra Tile View

struct ExtraTileView: View {
    let count: Int
    let index: Int
    let reduceMotion: Bool

    @State private var isVisible: Bool = false

    private let tileSize: CGFloat = 84

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundColor(Color.focusInk.opacity(0.2))
            .background(Color.clear)
            .overlay(
                Text("+\(count)")
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(.focusMuted)
                    .monospacedDigit()
            )
            .frame(width: tileSize, height: tileSize)
            .opacity(isVisible || reduceMotion ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 14)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.92)
            .animation(.interpolatingSpring(stiffness: 280, damping: 20).delay(Double(index) * 0.055), value: isVisible)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isVisible = true
                    }
                }
            }
    }
}

// MARK: - Seal Badge View

struct SealBadgeView: View {
    private let size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.focusAccent)
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.28), radius: 6, x: 0, y: 2)

            // Lock icon using SF Symbol (matches rest of app)
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "E9E5DE"))
        }
    }
}

// MARK: - Sweeping Light View

struct SweepingLightView: View {
    let itemCount: Int
    let columns: Int
    let tileSize: CGFloat
    let spacing: CGFloat

    private var sweepHeight: CGFloat {
        let rows = ceil(Double(itemCount) / Double(columns))
        return rows * tileSize + (rows - 1) * spacing + 24
    }

    private var animationDuration: Double {
        Double(itemCount) * 0.12 + 0.3
    }

    @State private var sweepOffset: CGFloat = -64

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.focusAccent.opacity(0), location: 0),
                .init(color: Color.focusAccent, location: 0.5),
                .init(color: Color.focusAccent.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 64)
        .blur(radius: 7)
        .opacity(0.7)
        .offset(y: sweepOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration)) {
                sweepOffset = sweepHeight
            }
        }
    }
}

// MARK: - Animation Modifiers

struct PulseModifier: ViewModifier {
    let isAnimating: Bool
    @State private var opacity: Double = 0.4

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                if isAnimating {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        opacity = 1.0
                    }
                }
            }
    }
}

struct StampModifier: ViewModifier {
    let index: Int
    let reduceMotion: Bool

    @State private var scale: CGFloat = 1.7
    @State private var rotation: Double = -10
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                if !reduceMotion {
                    let delay = Double(index) * 0.12
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 14).delay(delay)) {
                        scale = 1.0
                        rotation = 0
                    }
                    withAnimation(.easeIn(duration: 0.2).delay(delay)) {
                        opacity = 1.0
                    }
                } else {
                    scale = 1.0
                    rotation = 0
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    OnboardingActivationView(
        selectedApps: FamilyActivitySelection(),
        duration: 300,
        onComplete: {}
    )
}
