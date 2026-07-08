//
//  Colors.swift
//  ScreenFareShared
//
//  Unified color palette for the entire app and extensions
//  Matches the Anthropic design specifications exactly
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// #F5F2ED - Warm off-white background
    public static let focusBg = Color(hex: "F5F2ED")

    /// #1A1A1A - Near-black ink for text and UI elements
    public static let focusInk = Color(hex: "1A1A1A")

    /// #8B8680 - Muted text color
    public static let focusMuted = Color(hex: "8B8680")

    /// rgba(26,26,26,0.08) - Line/border color
    public static let focusLine = Color(hex: "1A1A1A").opacity(0.08)

    /// #FFFFFF - Card background
    public static let focusCard = Color.white

    /// oklch(0.585 0.125 40) - Orange/terracotta accent (converted to RGB)
    public static let focusAccent = Color(hex: "D8764A")

    /// Accent text color
    public static let focusAccentInk = Color.white

    /// oklch(0.585 0.16 28) - Warning color for ending sessions
    public static let focusWarn = Color(hex: "C76A4A")

    // MARK: - Transit/Challenge Colors

    /// oklch(0.55 0.1 150) - Green for success states
    public static let transitGreen = Color(red: 0.55, green: 0.65, blue: 0.45)

    /// oklch(0.58 0.16 25) - Red for error states
    public static let transitRed = Color(red: 0.7, green: 0.4, blue: 0.3)

    /// oklch(0.955 0.03 25) - Soft red background for errors
    public static let transitRedSoft = Color(red: 0.97, green: 0.955, blue: 0.95)
}

// MARK: - Helper Extensions

extension Color {
    public init(hex: String) {
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
