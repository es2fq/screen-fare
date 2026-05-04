//
//  OnboardingDesignSystem.swift
//  screenfare
//
//  Design system for Focus NUX flow
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

    var body: some View {
        HStack {
            BackButton(action: onBack)
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
