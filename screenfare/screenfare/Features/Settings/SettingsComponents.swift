//
//  SettingsComponents.swift
//  Screen Fare
//
//  Reusable UI components for the Settings screen
//

import SwiftUI

// MARK: - Settings Icon

struct SettIcon: View {
    let path: String?
    let circle: String?
    let viewBox: String
    let systemName: String?

    init(path: String, circle: String? = nil, viewBox: String = "22 22") {
        self.path = path
        self.circle = circle
        self.viewBox = viewBox
        self.systemName = nil
    }

    init(systemName: String) {
        self.path = nil
        self.circle = nil
        self.viewBox = "22 22"
        self.systemName = systemName
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.focusInk.opacity(0.06))
                .frame(width: 32, height: 32)

            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.focusInk)
        }
    }

    // Map path strings to SF Symbols
    private var iconName: String {
        if let systemName = systemName {
            return systemName
        }

        guard let path = path else {
            return "gearshape.fill"
        }

        if path.contains("M5 9h12v9H5") || path.contains("M8 9V6a3 3 0 016 0v3") {
            return "shield.fill"
        } else if path.contains("M6 10a5 5 0 019.6-1.8") {
            return "icloud.fill"
        } else if path.contains("M13 4H6a2 2 0 00-2 2v10") {
            return "rectangle.portrait.and.arrow.right"
        } else if path.contains("M5 6h12M9 6V4h4v2M7 6l1 12h6l1-12") {
            return "trash.fill"
        } else if path.contains("M11 5v6l3 3") {
            return "clock.fill"
        } else if path.contains("M5 7h12M5 15h12M9 4l-2 14") {
            return "app.badge"
        } else if path.contains("M4 11h14M12 5l6 6-6 6") {
            return "calendar"
        } else if path.contains("M4 6h14v9H4zM4 18h14M9 18v2h4v-2") {
            return "tv.fill"
        } else if path.contains("M11 18s-6-4-6-8a3.5 3.5 0 016-2") {
            return "heart.fill"
        } else if path.contains("M11 3v11M6 9l5 5 5-5") {
            return "square.and.arrow.down"
        } else if path.contains("M5 8a6 6 0 1110.5 4M16 5v3h-3") {
            return "arrow.clockwise"
        } else if path.contains("M11 3l7 3v5c0 4-3 7-7 8") {
            return "shield.fill"
        } else if path.contains("M6 3h7l4 4v12H6zM13 3v4h4") {
            return "doc.text.fill"
        } else if path.contains("M11 16v0M8.5 8.5a2.5 2.5 0 014.6 1.3") {
            return "questionmark.circle.fill"
        } else if path.contains("M4 6h14v10H4zM4 7l7 5 7-5") {
            return "envelope.fill"
        } else if path.contains("M11 4l2.5 5 5.5.8-4 4 1 5.5") {
            return "star.fill"
        } else {
            return "gearshape.fill"
        }
    }
}

// MARK: - Status Pill

enum StatusPillTone {
    case on, off, warn

    var backgroundColor: Color {
        switch self {
        case .on: return .focusInk
        case .off: return Color.focusInk.opacity(0.06)
        case .warn: return Color(red: 0.62, green: 0.42, blue: 0.3).opacity(0.14)
        }
    }

    var textColor: Color {
        switch self {
        case .on: return .white
        case .off: return .focusMuted
        case .warn: return Color(red: 0.78, green: 0.42, blue: 0.29)
        }
    }
}

struct StatusPill: View {
    let text: String
    let tone: StatusPillTone

    var body: some View {
        Text(text)
            .font(.inter(11.5, weight: .semibold))
            .foregroundColor(tone.textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(height: 24)
            .background(tone.backgroundColor)
            .cornerRadius(12)
    }
}

// MARK: - Lock Mini Icon

struct LockMini: View {
    var color: Color = .focusMuted
    var size: CGFloat = 11

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
    }
}

// MARK: - Intro Note

struct IntroNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.inter(13.5))
            .foregroundColor(.focusMuted)
            .lineSpacing(3)
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
            .padding(.top, 2)
    }
}

// MARK: - Foot Note

struct FootNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.inter(12.5))
            .foregroundColor(.focusMuted)
            .lineSpacing(2)
            .padding(.horizontal, 4)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }
}

// MARK: - Chevron Icon

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.focusInk.opacity(0.3))
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    var icon: SettIcon? = nil
    let label: String
    var sub: String? = nil
    var right: AnyView? = nil
    var danger: Bool = false
    var last: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    icon
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.inter(15, weight: danger ? .medium : .medium))
                        .foregroundColor(danger ? .focusWarn : .focusInk)

                    if let sub = sub {
                        Text(sub)
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let right = right {
                    right
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.focusCard)
        }
        .buttonStyle(PlainButtonStyle())

        if !last {
            Divider()
        }
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    var icon: SettIcon? = nil
    let label: String
    var sub: String? = nil
    @Binding var value: Bool
    var disabled: Bool = false
    var last: Bool = false
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                icon
                    .opacity(disabled ? 0.45 : 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(.focusInk)
                    .opacity(disabled ? 0.45 : 1)

                if let sub = sub {
                    Text(sub)
                        .font(.inter(12.5))
                        .foregroundColor(.focusMuted)
                        .opacity(disabled ? 0.5 : 1)
                        .lineLimit(2)
                }
            }

            Spacer()

            CustomToggle(isOn: Binding(
                get: { value },
                set: { newValue in
                    if !disabled {
                        value = newValue
                        onChange?(newValue)
                    }
                }
            ))
            .opacity(disabled ? 0.45 : 1)
            .disabled(disabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.focusCard)

        if !last {
            Divider()
        }
    }
}
