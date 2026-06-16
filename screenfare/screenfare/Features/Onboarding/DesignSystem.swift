//
//  DesignSystem.swift
//  Screen Fare
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

/// Brand mark component - Screen Fare app icon
struct BrandMark: View {
    var size: CGFloat = 56

    var body: some View {
        Image("BrandIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
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

// MARK: - Shared Permission Prompt Component

struct PermissionPrompt: View {
    let title: String
    let description: String
    let leftButtonText: String
    let rightButtonText: String
    let rightButtonIsBlue: Bool
    let arrowLabel: String
    let arrowOffset: CGFloat
    var onTap: (() -> Void)?
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 14) {
            // iOS permission alert with highlight ring
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(1))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Description
                    Text(description)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.62))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

                // Pill buttons
                HStack(spacing: 10) {
                    // Left button
                    Text(leftButtonText)
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "3A3A3C"))
                        .cornerRadius(999)

                    // Right button
                    Text(rightButtonText)
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(rightButtonIsBlue ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color(hex: "3A3A3C"))
                        .cornerRadius(999)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: 320)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(hex: "BF7F5F"), lineWidth: 2.5)
                    .padding(-8)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                        onTap?()
                    }
            )

            // Clean straight arrow pointing up + label
            VStack(spacing: 6) {
                // Straight arrow (SVG-like path)
                ZStack {
                    // Vertical line
                    Rectangle()
                        .fill(Color(hex: "BF7F5F"))
                        .frame(width: 3.5, height: 46)
                        .offset(y: 3)

                    // Arrowhead
                    ArrowHead()
                        .fill(Color(hex: "BF7F5F"))
                        .frame(width: 24, height: 18)
                        .offset(y: -20)
                }
                .frame(height: 52)
                .padding(.top, 2)

                // Label
                Text(arrowLabel)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(hex: "BF7F5F"))
                    .tracking(0.01)
            }
            .offset(x: arrowOffset)
        }
    }
}

// MARK: - Screen Time Permission Prompt Mockup

struct ScreenTimePermissionPrompt: View {
    var onTap: (() -> Void)?

    var body: some View {
        PermissionPrompt(
            title: "\u{201C}Screen Fare\u{201D} Would Like to Access Screen Time",
            description: "Providing \u{201C}Screen Fare\u{201D} access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.",
            leftButtonText: "Continue",
            rightButtonText: "Don't Allow",
            rightButtonIsBlue: true,
            arrowLabel: "Tap \"Continue\" to allow",
            arrowOffset: -70,
            onTap: onTap
        )
    }
}

// MARK: - Notification Permission Prompt Mockup

struct NotificationPermissionPrompt: View {
    var onTap: (() -> Void)?

    var body: some View {
        PermissionPrompt(
            title: "\u{201C}Screen Fare\u{201D} Would Like to Send You Notifications",
            description: "Notifications may include alerts, sounds, and icon badges. These can be configured in Settings.",
            leftButtonText: "Don't Allow",
            rightButtonText: "Allow",
            rightButtonIsBlue: false,
            arrowLabel: "Tap \"Allow\" to enable",
            arrowOffset: 75,
            onTap: onTap
        )
    }
}

// MARK: - Settings Screen Mockup for Denied Notifications

struct SettingsScreenMockup: View {
    var onTap: (() -> Void)?
    @State private var isPressed = false

    var body: some View {
        // Settings screen mockup
        VStack(spacing: 0) {
            // Header
            Text("Allow Screen Fare to Access")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "8B8680"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                // Search row
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 29, height: 29)
                        .background(Color(hex: "48484A"))
                        .cornerRadius(7)

                    Text("Search")
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(hex: "2C2C2E"))

                // Notifications row
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 29, height: 29)
                        .background(Color(hex: "FF3B30"))
                        .cornerRadius(7)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Text("Off")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(hex: "2C2C2E"))

                // Cellular Data row
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 29, height: 29)
                        .background(Color(hex: "34C759"))
                        .cornerRadius(7)

                    Text("Cellular Data")
                        .font(.system(size: 17))
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .disabled(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(hex: "2C2C2E"))
            }
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .overlay(
                // Border overlay around notifications row only
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "BF7F5F"), lineWidth: 2.5)
                    .frame(height: 51)
                    .offset(y: -8)
                    .padding(.horizontal, 16)
            )
        }
        .frame(maxWidth: 340)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(20)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    onTap?()
                }
        )
    }
}

// MARK: - Arrow Head Shape

struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Triangle arrowhead pointing up
        let centerX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY
        let leftX = rect.minX
        let rightX = rect.maxX

        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: leftX, y: bottomY))
        path.addLine(to: CGPoint(x: rightX, y: bottomY))
        path.closeSubpath()

        return path
    }
}
