//
//  Typography.swift
//  Screen Fare
//
//  Unified typography system for the entire app
//  Matches the Anthropic design specifications exactly
//

import SwiftUI

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
