//
//  ColorExtensions.swift
//  DeviceActivityReportExtension
//
//  Shared color definitions for the extension
//

import SwiftUI

extension Color {
    /// #D8764A - Orange/terracotta accent (matches main app focusAccent)
    static let focusAccent = Color(red: 0xD8 / 255.0, green: 0x76 / 255.0, blue: 0x4A / 255.0)

    /// Initializer from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0
        )
    }
}
