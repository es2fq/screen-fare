//
//  TicketComponents.swift
//  screenfare
//
//  Reusable components for the ticket-themed challenge UI
//  Based on challenge-ticket.jsx from the design handoff
//

import SwiftUI

// MARK: - Colors

extension Color {
    static let transitGreen = Color(red: 0.55, green: 0.65, blue: 0.45) // oklch(0.55 0.1 150)
    static let transitRed = Color(red: 0.7, green: 0.4, blue: 0.3) // oklch(0.58 0.16 25)
    static let transitRedSoft = Color(red: 0.97, green: 0.955, blue: 0.95) // oklch(0.955 0.03 25)
}

// MARK: - Wordmark

struct Wordmark: View {
    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.focusInk)
                    .frame(width: 22, height: 22)

                Text("f")
                    .font(.instrumentSerif(14, italic: true))
                    .foregroundColor(.white)
                    .offset(y: -1)
            }

            Text("SCREEN FARE")
                .font(.inter(11, weight: .semibold))
                .tracking(1.54) // 0.14em letter-spacing
                .foregroundColor(.focusMuted)
        }
    }
}

// MARK: - Close Button

struct CloseX: View {
    let label: String
    let action: () -> Void

    init(label: String = "Not now", action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))

                Text(label)
                    .font(.inter(13, weight: .medium))
            }
            .foregroundColor(.focusMuted)
            .padding(.horizontal, 14)
            .padding(.leading, 10)
            .padding(.vertical, 8)
            .background(Color.focusInk.opacity(0.05))
            .cornerRadius(17)
        }
    }
}

// MARK: - Barcode

struct Barcode: View {
    var tint: Color = Color.focusInk.opacity(0.85)
    var height: CGFloat = 34

    // Pattern from design: "231132113122312113213121223113"
    private let bars = "231132113122312113213121223113"

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, char in
                let width = CGFloat(Int(String(char)) ?? 1)
                let isGap = index % 7 == 6

                Rectangle()
                    .fill(isGap ? Color.clear : tint)
                    .frame(width: width, height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Perforation

struct Perf: View {
    var notchColor: Color = Color.focusBg

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Left notch
                Circle()
                    .fill(notchColor)
                    .frame(width: 22, height: 22)
                    .offset(x: -22, y: -11)

                // Right notch
                Circle()
                    .fill(notchColor)
                    .frame(width: 22, height: 22)
                    .offset(x: geometry.size.width + 22, y: -11)

                // Dashed line
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 2)
                    .background(
                        DashedLine()
                            .stroke(Color.focusLine, style: StrokeStyle(lineWidth: 2, dash: [6, 7]))
                    )
                    .padding(.horizontal, 14)
                    .offset(y: -1)
            }
        }
        .frame(height: 0)
    }
}

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Paid Stamp

struct PaidStamp: View {
    let show: Bool
    @State private var scale: CGFloat = 1.55
    @State private var rotation: Double = -26
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            Text("FARE PAID")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .tracking(1.04) // 0.04em

            Text("SCREEN FARE · TRANSIT")
                .font(.system(size: 8.5, weight: .bold))
                .tracking(1.87) // 0.22em
        }
        .foregroundColor(.transitGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .padding(.bottom, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.transitGreen, lineWidth: 2.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 1.5)
                        .strokeBorder(Color.transitGreen, lineWidth: 1.5)
                )
        )
        .blendMode(.multiply)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .onAppear {
            if show {
                animateStamp()
            }
        }
        .onChange(of: show) { newValue in
            if newValue {
                animateStamp()
            }
        }
    }

    private func animateStamp() {
        // Stamp animation: scale down and rotate with spring
        withAnimation(.timingCurve(0.2, 1.5, 0.35, 1, duration: 0.4)) {
            scale = 1.0
            rotation = -13
            opacity = 1
        }

        // Slight bounce at offset 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                scale = 0.92
                rotation = -12
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.08)) {
                    scale = 1.0
                    rotation = -13
                }
            }
        }
    }
}

// MARK: - Ticket Button

struct TicketBtn: View {
    let title: String
    let action: () -> Void
    let disabled: Bool

    init(_ title: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inter(16, weight: .medium))
                .foregroundColor(disabled ? Color.focusInk.opacity(0.4) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(disabled ? Color.focusInk.opacity(0.12) : Color.focusInk)
                .cornerRadius(16)
        }
        .disabled(disabled)
    }
}

#Preview("Components") {
    VStack(spacing: 30) {
        Wordmark()

        CloseX { }

        Barcode()

        HStack {
            Spacer()
            Perf()
                .frame(width: 300)
            Spacer()
        }

        PaidStamp(show: true)

        TicketBtn("Open Instagram", action: {})

        TicketBtn("Memorizing… 3", disabled: true, action: {})
    }
    .padding()
    .background(Color.focusBg)
}
