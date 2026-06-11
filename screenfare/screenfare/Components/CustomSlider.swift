//
//  CustomSlider.swift
//  screenfare
//
//  Custom slider component using pure SwiftUI DragGesture
//  Supports any range and step size, with snap-while-dragging behavior
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    // Customizable colors
    var trackColor: Color = Color.focusLine
    var activeTrackColor: Color = Color.focusInk
    var thumbColor: Color = .white
    var thumbBorderColor: Color = Color(white: 0.9)

    // Sizing
    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 4

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - thumbSize
            let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = CGFloat(progress) * trackWidth

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(trackColor)
                    .frame(height: trackHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, thumbSize / 2)

                // Active track (filled portion)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(activeTrackColor)
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)
                    .padding(.leading, thumbSize / 2)

                // Thumb
                Circle()
                    .fill(thumbColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(thumbBorderColor, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                    .offset(x: thumbX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true

                                // Calculate new value based on drag position
                                let newX = max(0, min(trackWidth, gesture.location.x - thumbSize / 2))
                                let newProgress = Double(newX / trackWidth)
                                let rawValue = range.lowerBound + newProgress * (range.upperBound - range.lowerBound)

                                // Snap to nearest step
                                let steppedValue = round(rawValue / step) * step
                                let clampedValue = min(max(steppedValue, range.lowerBound), range.upperBound)

                                if clampedValue != value {
                                    value = clampedValue
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
        }
        .frame(height: thumbSize)
    }
}

#Preview {
    VStack(spacing: 40) {
        VStack {
            Text("Difficulty: \(Int(5))")
            CustomSlider(value: .constant(2), range: 0...4, step: 1)
        }

        VStack {
            Text("Duration: \(Int(30)) min")
            CustomSlider(value: .constant(30), range: 1...120, step: 1)
        }
    }
    .padding(40)
}
