//
//  DesignSystem.swift
//  screenfare
//
//  Unified design system for the entire app
//  Matches the Anthropic design specifications exactly
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// #F5F2ED - Warm off-white background
    static let focusBg = Color(hex: "F5F2ED")

    /// #1A1A1A - Near-black ink for text and UI elements
    static let focusInk = Color(hex: "1A1A1A")

    /// #8B8680 - Muted text color
    static let focusMuted = Color(hex: "8B8680")

    /// rgba(26,26,26,0.08) - Line/border color
    static let focusLine = Color(hex: "1A1A1A").opacity(0.08)

    /// #FFFFFF - Card background
    static let focusCard = Color.white

    /// oklch(0.62 0.06 145) - Sage accent (converted to RGB)
    static let focusAccent = Color(hex: "88A894")

    /// Accent text color
    static let focusAccentInk = Color.white

    /// oklch(0.585 0.16 28) - Warning color for ending sessions
    static let focusWarn = Color(hex: "C76A4A")

    // MARK: - Transit/Challenge Colors

    /// oklch(0.55 0.1 150) - Green for success states
    static let transitGreen = Color(red: 0.55, green: 0.65, blue: 0.45)

    /// oklch(0.58 0.16 25) - Red for error states
    static let transitRed = Color(red: 0.7, green: 0.4, blue: 0.3)

    /// oklch(0.955 0.03 25) - Soft red background for errors
    static let transitRedSoft = Color(red: 0.97, green: 0.955, blue: 0.95)
}

// MARK: - Typography

extension Font {
    /// Instrument Serif for display text
    static func instrumentSerif(_ size: CGFloat, italic: Bool = false) -> Font {
        return .custom(italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular", size: size)
    }

    /// Inter for UI text
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular: return .custom("Inter_18pt-Regular", size: size)
        case .medium: return .custom("Inter_18pt-Medium", size: size)
        case .semibold: return .custom("Inter_18pt-SemiBold", size: size)
        case .bold: return .custom("Inter_18pt-Bold", size: size)
        default: return .custom("Inter_18pt-Regular", size: size)
        }
    }
}

// MARK: - Shared Components

/// Brand mark component - "f" in italic Instrument Serif
struct BrandMark: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(Color.focusInk)

            Text("f")
                .font(.instrumentSerif(size * 0.62, italic: true))
                .foregroundColor(.white)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// Progress dots showing current step
struct ProgressDots: View {
    let currentStep: Int
    let totalSteps: Int = 7

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index <= currentStep ? Color.focusInk : Color.focusInk.opacity(0.15))
                    .frame(width: index == currentStep ? 18 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.28), value: currentStep)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Primary button matching design specs
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inter(16, weight: .semibold))
                .foregroundColor(disabled ? Color.focusInk.opacity(0.35) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(disabled ? Color.focusInk.opacity(0.15) : Color.focusInk)
                .cornerRadius(16)
        }
        .disabled(disabled)
    }
}

/// Back button for navigation
struct BackButton: View {
    let action: () -> Void
    var hidden: Bool = false

    var body: some View {
        if hidden {
            Color.clear
                .frame(width: 36, height: 36)
                .allowsHitTesting(false)
        } else {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.focusInk)
                    .frame(width: 36, height: 36)
                    .background(Color.focusInk.opacity(0.05))
                    .clipShape(Circle())
            }
        }
    }
}

/// Header with back button and progress dots
struct ScreenHeader: View {
    let currentStep: Int
    let onBack: () -> Void
    var hideBackButton: Bool = false

    var body: some View {
        HStack {
            BackButton(action: onBack, hidden: hideBackButton)
            Spacer()
            ProgressDots(currentStep: currentStep)
            Spacer()
            Color.clear
                .frame(width: 36, height: 36)
        }
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Screen Base

struct OnboardingScreen<Content: View>: View {
    let content: Content
    var padding: Bool = true

    init(padding: Bool = true, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if padding {
                    content
                        .padding(.horizontal, 28)
                } else {
                    content
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Permission Icons

struct PermissionIcon: View {
    enum IconKind {
        case time
        case notification
    }

    let kind: IconKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.focusLine, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.focusCard)
                )
                .frame(width: 76, height: 76)

            // Use SF Symbols instead of manual drawing
            Image(systemName: kind == .time ? "clock" : "bell")
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.focusInk)
        }
    }
}

// MARK: - Permission Bullet Point

struct PermissionBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.focusInk.opacity(0.06))
                    .frame(width: 22, height: 22)

                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.focusInk)
            }

            Text(text)
                .font(.inter(14.5))
                .foregroundColor(.focusInk)
                .lineSpacing(14.5 * 0.45) // lineHeight 1.45 = 45% extra spacing
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Screen Time Permission Prompt Mockup

struct ScreenTimePermissionPrompt: View {
    var body: some View {
        VStack(spacing: 0) {
            // Mock iOS permission dialog
            VStack(spacing: 0) {
                // Title
                Text("\"Screen Fare\" Would Like to Access\nScreen Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                // Description
                Text("Providing \"Screen Fare\" access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 0.5)

                // Buttons
                HStack(spacing: 0) {
                    // Continue button
                    Button(action: {}) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 0.04, green: 0.52, blue: 1.0)) // iOS blue
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .disabled(true)

                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 0.5)

                    // Don't allow button
                    Button(action: {}) {
                        Text("Don't allow")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .disabled(true)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.18)) // iOS dark dialog background
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.04, green: 0.52, blue: 1.0), lineWidth: 3) // Blue highlight
            )
            .padding(.horizontal, 20)

            // Arrow pointing to Continue
            HStack {
                Spacer()
                    .frame(width: 60)

                ArrowShape()
                    .stroke(Color(red: 0.04, green: 0.52, blue: 1.0), lineWidth: 3)
                    .frame(width: 50, height: 50)
                    .padding(.leading, -10)

                Spacer()
            }
            .padding(.top, -8)
        }
    }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Curved arrow pointing up and to the left (to Continue button)
        let startX = rect.maxX
        let startY = rect.maxY
        let endX = rect.minX + 15
        let endY = rect.minY + 10

        // Curve control points
        let control1X = rect.maxX - 10
        let control1Y = rect.maxY - 20
        let control2X = rect.minX + 30
        let control2Y = rect.minY + 30

        path.move(to: CGPoint(x: startX, y: startY))
        path.addCurve(
            to: CGPoint(x: endX, y: endY),
            control1: CGPoint(x: control1X, y: control1Y),
            control2: CGPoint(x: control2X, y: control2Y)
        )

        // Arrowhead
        path.move(to: CGPoint(x: endX, y: endY))
        path.addLine(to: CGPoint(x: endX - 5, y: endY + 10))
        path.move(to: CGPoint(x: endX, y: endY))
        path.addLine(to: CGPoint(x: endX + 10, y: endY + 5))

        return path
    }
}
