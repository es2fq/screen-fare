//
//  LaunchAnimationView.swift
//  Screen Fare
//
//  Launch animation: "pay the fare, then pass."
//  Exact recreation of the HTML/CSS animation
//

import SwiftUI

// MARK: - Constants

// Using the app's accent color (focusAccent) for consistency
private let LA_TERRA = Color(hex: "D8764A") // App's focusAccent color
private let LA_TERRA_HOT = Color(hex: "E8967A") // Lighter version for glow
private let LA_CREAM = Color(hex: "E9E5DE")
private let LA_APPBG = Color(hex: "F5F2ED")
private let LA_MUTED = Color(hex: "8B8680")
private let LA_INK = Color(hex: "1A1A1A")

private let LA_TITLE_DROP: CGFloat = 80

// Token geometry (scaled from 1024 art canvas to 116px coin)
private let ICON_SIZE: CGFloat = 116
private let COIN_DISC_D: CGFloat = 75.4 // 664 * (116/1024)
private let GROOVE_D: CGFloat = 68 // 600 * (116/1024)
private let GROOVE_W: CGFloat = 1.6 // 14 * (116/1024)
private let CUT_W: CGFloat = 19.9 // 176 * (116/1024)
private let CUT_H: CGFloat = 28.5 // 252 * (116/1024)
private let CUT_RX: CGFloat = 5.2 // 46 * (116/1024)
private let IND_W: CGFloat = 7.0 // 62 * (116/1024)
private let IND_H: CGFloat = 1.4 // 12 * (116/1024)
private let IND_BOTTOM: CGFloat = 2.7 // 24 * (116/1024)
private let TILE_R: CGFloat = 26.1 // 230 * (116/1024)

private let SLOT_Y: CGFloat = 140

// MARK: - Timeline

private struct AnimationDurations {
    let slotFadeIn: TimeInterval = 0.3  // Slot fade-in delay before coin drops
    let arrive: TimeInterval
    let settle: TimeInterval
    let become: TimeInterval
    let holdIcon: TimeInterval
    let pay: TimeInterval
    let expand: TimeInterval
    let shift: TimeInterval
    let reveal: TimeInterval

    var becomeAt: TimeInterval { slotFadeIn + arrive + settle }
    var payAt: TimeInterval { slotFadeIn + arrive + settle + become + holdIcon }
    var expandAt: TimeInterval { slotFadeIn + arrive + settle + become + holdIcon + pay }
    var shiftAt: TimeInterval { slotFadeIn + arrive + settle + become + holdIcon + pay + expand }
    var revealAt: TimeInterval { slotFadeIn + arrive + settle + become + holdIcon + pay + expand + shift }

    static func timeline(speed: Double = 1.0) -> AnimationDurations {
        let s: (Double) -> TimeInterval = { $0 / speed }
        return AnimationDurations(
            arrive: s(0.660),
            settle: s(0.220),
            become: s(0.380),
            holdIcon: s(0.100),  // Very brief 0.1s pause before tap
            pay: s(0.520),
            expand: s(0.320),    // Much faster expansion
            shift: s(0.780),
            reveal: s(0.480)
        )
    }
}

// MARK: - Animation Phases

private enum LaunchPhase: Int {
    case arrive = 0
    case become = 1
    case paying = 2
    case expanding = 3
    case warming = 4
    case welcome = 5
}

// MARK: - Slot Entrance Animation
// Exact keyframes from HTML with proper easing per segment:
// 0%:   translateY(-340px) rotateZ(-300deg) - cubic-bezier(.4,0,.7,.5)
// 60%:  translateY(9px) rotateZ(0deg)       - ease-out starts
// 78%:  translateY(-6px) rotateZ(0deg)      - ease-out continues
// 100%: translateY(0) rotateZ(0deg)         - ease-out continues

private struct SlotEntranceModifier: ViewModifier {
    let duration: TimeInterval
    let phase: LaunchPhase

    @State private var yOffset: CGFloat = -340
    @State private var rotation: Angle = .degrees(-300)

    func body(content: Content) -> some View {
        content
            .rotationEffect(rotation)
            .offset(y: phase == .arrive ? yOffset : 0)
            .onAppear {
                if phase == .arrive {
                    let slotFadeInDelay: TimeInterval = 0.3

                    // Wait for slot to fade in, then start coin drop
                    // Segment 1 (0% → 60%): Fall with acceleration
                    DispatchQueue.main.asyncAfter(deadline: .now() + slotFadeInDelay) {
                        withAnimation(.timingCurve(0.4, 0, 0.7, 0.5, duration: duration * 0.6)) {
                            yOffset = 9
                            rotation = .zero
                        }
                    }

                    // Segment 2 (60% → 78%): Bounce up with ease-out
                    DispatchQueue.main.asyncAfter(deadline: .now() + slotFadeInDelay + duration * 0.6) {
                        withAnimation(.easeOut(duration: duration * 0.18)) {
                            yOffset = -6
                        }
                    }

                    // Segment 3 (78% → 100%): Settle down with ease-out
                    DispatchQueue.main.asyncAfter(deadline: .now() + slotFadeInDelay + duration * 0.78) {
                        withAnimation(.easeOut(duration: duration * 0.22)) {
                            yOffset = 0
                        }
                    }
                }
            }
    }
}

// MARK: - Tap Press Animation
// Exact keyframes from HTML:
// 0%:   scale(1)    translateY(0)
// 26%:  scale(0.93) translateY(3px)
// 52%:  scale(1.05) translateY(-2px)
// 100%: scale(1)    translateY(0)

private struct TapPressModifier: ViewModifier {
    let paying: Bool
    let duration: TimeInterval
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(animationScale)
            .offset(y: animationOffset)
            .onChange(of: paying) { _, isPaying in
                if isPaying {
                    // Manually animate through keyframes
                    // 0% -> 26%: scale to 0.93, offset to 3
                    withAnimation(.linear(duration: duration * 0.26)) {
                        animationScale = 0.93
                        animationOffset = 3
                    }

                    // 26% -> 52%: scale to 1.05, offset to -2
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.26) {
                        withAnimation(.linear(duration: duration * 0.26)) {
                            animationScale = 1.05
                            animationOffset = -2
                        }
                    }

                    // 52% -> 100%: scale to 1.0, offset to 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.52) {
                        withAnimation(.linear(duration: duration * 0.48)) {
                            animationScale = 1.0
                            animationOffset = 0
                        }
                    }
                }
            }
    }
}

// Note: Tile is now rendered directly in LaunchCoin to match HTML's position: absolute, inset: 0 behavior
// Note: Ripples removed to focus on tap animation

// MARK: - Slot Component

private struct SlotView: View {
    let phase: LaunchPhase
    let dur: AnimationDurations
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: SLOT_Y - 14)

            Rectangle()
                .fill(LA_INK)
                .frame(width: 120, height: 14)
                .cornerRadius(7)
                .shadow(color: Color.black.opacity(0.55), radius: 1.5, y: 1.5)

            Spacer()
        }
        .opacity(opacity)
        .onAppear {
            // Fade in at the start
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }

            // Fade out after coin lands (at end of arrive duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + dur.arrive) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Coin Component

private struct LaunchCoin: View {
    let size: CGFloat
    let entrance: String
    let dur: AnimationDurations
    let ripple: Bool
    let glow: Bool
    let hasIcon: Bool
    let paying: Bool
    let phase: LaunchPhase

    @State private var tileScale: CGFloat = 0.5
    @State private var tileOpacity: Double = 0

    var body: some View {
        coinBody
            .frame(width: size, height: size)
            .modifier(TapPressModifier(paying: paying, duration: dur.pay))
            .onChange(of: hasIcon) { _, newValue in
                if newValue {
                    withAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.380)) {
                        tileScale = 1.0
                        tileOpacity = 1.0
                    }
                }
            }
    }

    private var coinBody: some View {
        ZStack {
            // Tile behind everything - matches HTML's position: absolute, inset: 0
            if hasIcon {
                ZStack {
                    RoundedRectangle(cornerRadius: TILE_R)
                        .fill(LA_TERRA)
                        .shadow(color: Color.black.opacity(0.30), radius: 22, y: 18)
                        .shadow(color: Color.black.opacity(0.18), radius: 5, y: 4)

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            Color.white.opacity(0),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TILE_R))
                }
                .frame(width: size, height: size)
                .scaleEffect(tileScale)
                .opacity(tileOpacity)
            }

            // Coin disc with groove
            coinDiscView

            // Phone cutout on top
            phoneCutoutView
        }
        .frame(width: size, height: size)
    }

    private var coinDiscView: some View {
        Circle()
            .fill(LA_CREAM)
            .frame(width: COIN_DISC_D, height: COIN_DISC_D)
            .shadow(
                color: hasIcon ? .clear : Color.black.opacity(0.32),
                radius: hasIcon ? 0 : 19,
                y: hasIcon ? 0 : 16
            )
            .shadow(
                color: hasIcon ? .clear : Color.black.opacity(0.20),
                radius: hasIcon ? 0 : 5,
                y: hasIcon ? 0 : 4
            )
            .overlay(
                Circle()
                    .strokeBorder(LA_TERRA.opacity(0.5), lineWidth: GROOVE_W)
                    .frame(width: GROOVE_D, height: GROOVE_D)
            )
    }

    private var phoneCutoutView: some View {
        RoundedRectangle(cornerRadius: CUT_RX)
            .fill(LA_TERRA)
            .frame(width: CUT_W, height: CUT_H)
            .overlay(
                Capsule()
                    .fill(LA_CREAM)
                    .frame(width: IND_W, height: IND_H)
                    .offset(y: CUT_H / 2 - IND_BOTTOM - IND_H / 2)
            )
            .overlay(
                ZStack {
                    if glow && paying {
                        RadialGradient(
                            colors: [
                                Color(red: 1, green: 247/255, blue: 235/255).opacity(0.95),
                                LA_TERRA_HOT,
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: CUT_W * 0.85
                        )
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)
                        .animation(.easeOut(duration: dur.pay), value: paying)
                    }
                }
            )
    }

    // Glow animation: 0% opacity 0, scale 0.7 → 45% opacity 0.95, scale 1.04 → 100% opacity 0.5, scale 1
    private var glowScale: CGFloat {
        paying ? 1.04 : 0.7
    }

    private var glowOpacity: Double {
        paying ? 0.5 : 0
    }
}

// MARK: - Main Launch Animation View

struct LaunchAnimationView: View {
    let speed: Double
    let entrance: String
    let ripple: Bool
    let glow: Bool
    let landing: Bool
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var phase: LaunchPhase = .arrive
    @State private var titleDown = false

    private var dur: AnimationDurations {
        AnimationDurations.timeline(speed: speed)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LA_CREAM
                    .ignoresSafeArea()

                // Fare slot
                if entrance == "slot" && phase == .arrive {
                    SlotView(phase: phase, dur: dur)
                }

                // Coin → icon (clipped above slot during entrance)
                // HTML: clipPath: inset(140px 0 0 0) - clips top 140px, shows everything below
                if phase.rawValue < LaunchPhase.warming.rawValue {
                    ZStack {
                        // Coin with clipping for slot entrance
                        ZStack {
                            LaunchCoin(
                                size: ICON_SIZE,
                                entrance: entrance,
                                dur: dur,
                                ripple: false, // Ripples rendered separately outside mask
                                glow: glow,
                                hasIcon: phase.rawValue >= LaunchPhase.become.rawValue,
                                paying: phase == .paying,
                                phase: phase
                            )
                            .modifier(SlotEntranceModifier(duration: dur.arrive, phase: phase))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .mask(
                            // Clip top 140px during slot entrance (only show area below slot)
                            Rectangle()
                                .padding(.top, (entrance == "slot" && phase == .arrive) ? SLOT_Y : 0)
                        )
                    }
                    .opacity(phase == .expanding ? 0 : 1)
                    .animation(.easeOut(duration: dur.expand * 0.45).delay(0), value: phase)
                }

                // "SCREEN FARE" wordmark - matches launch screen exactly
                Text("S C R E E N   F A R E")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(titleDown ? LA_MUTED : LA_INK)
                    .scaleEffect(titleDown ? 0.44 : 1.0)
                    .offset(y: titleDown ? LA_TITLE_DROP : 0)
                    .opacity(phase.rawValue >= LaunchPhase.expanding.rawValue ? 0 : 1)
                    .animation(.timingCurve(0.4, 0, 0.25, 1, duration: dur.arrive), value: titleDown)
                    .animation(.easeOut(duration: 0.24), value: phase)

                // The phone screen panel
                screenPanel(size: geometry.size)

                // Completion trigger
                if phase == .welcome {
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onComplete()
                            }
                        }
                }
            }
        }
        .onAppear {
            if reduceMotion {
                phase = landing ? .welcome : .warming
                titleDown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onComplete()
                }
            } else {
                startAnimationSequence()
            }
        }
    }

    private func screenPanel(size: CGSize) -> some View {
        let grown = phase.rawValue >= LaunchPhase.expanding.rawValue
        // Use full screen dimensions including safe areas when expanded
        let fullScreenSize = UIScreen.main.bounds.size
        let width: CGFloat = grown ? fullScreenSize.width : CUT_W
        let height: CGFloat = grown ? fullScreenSize.height : CUT_H
        let cornerRadius: CGFloat = grown ? 46 : CUT_RX
        let homeBarWidth: CGFloat = grown ? 139 : IND_W
        let homeBarHeight: CGFloat = grown ? 5 : IND_H
        let homeBarBottom: CGFloat = grown ? 9 : IND_BOTTOM

        return ZStack {
            // Panel background - stays orange during expansion, changes after
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(phase.rawValue >= LaunchPhase.warming.rawValue ? LA_APPBG : LA_TERRA)
                .frame(width: width, height: height)
                .overlay(
                    // Power-on flash during expansion
                    ZStack {
                        if phase == .expanding && glow {
                            RadialGradient(
                                colors: [
                                    Color(red: 1, green: 247/255, blue: 235/255).opacity(0.9),
                                    Color(red: 1, green: 247/255, blue: 235/255).opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: min(width, height) * 0.6
                            )
                            .opacity(0)
                            .animation(.easeOut(duration: 0.520), value: phase)
                        }
                    }
                )

            // Home indicator bar
            Capsule()
                .fill(LA_CREAM)
                .frame(width: homeBarWidth, height: homeBarHeight)
                .offset(y: height / 2 - homeBarBottom - homeBarHeight / 2)
                .opacity(phase.rawValue >= LaunchPhase.warming.rawValue ? 0 : 0.92)
        }
        .opacity(phase.rawValue >= LaunchPhase.paying.rawValue ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: phase.rawValue >= LaunchPhase.paying.rawValue)
        .animation(.timingCurve(0.85, 0, 0.95, 1.0, duration: dur.expand), value: grown)  // Very fast, aggressive expansion
        .animation(.easeInOut(duration: dur.shift), value: phase.rawValue >= LaunchPhase.warming.rawValue)
    }

    private func startAnimationSequence() {
        // Drop title early
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            titleDown = true
        }

        // Phase transitions
        DispatchQueue.main.asyncAfter(deadline: .now() + dur.becomeAt) {
            withAnimation { phase = .become }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dur.payAt) {
            withAnimation { phase = .paying }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dur.expandAt) {
            withAnimation { phase = .expanding }
        }

        // Skip warming phase - go directly to app after expansion
        if landing {
            DispatchQueue.main.asyncAfter(deadline: .now() + dur.revealAt) {
                withAnimation { phase = .welcome }
            }
        } else {
            // Transition to app immediately after expansion completes
            DispatchQueue.main.asyncAfter(deadline: .now() + dur.expandAt + dur.expand) {
                onComplete()
            }
        }
    }
}

// MARK: - Static Launch Screen

struct StaticLaunchScreen: View {
    var body: some View {
        ZStack {
            LA_CREAM.ignoresSafeArea()

            Text("S C R E E N   F A R E")
                .font(.system(size: 25, weight: .medium))
                .foregroundColor(LA_INK)
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchAnimationView(
        speed: 1.0,
        entrance: "slot",
        ripple: true,
        glow: true,
        landing: true
    ) {
        print("Animation complete")
    }
}
