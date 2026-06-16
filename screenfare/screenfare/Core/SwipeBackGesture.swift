//
//  SwipeBackGesture.swift
//  Screen Fare
//
//  Reusable swipe-from-left-edge gesture for dismissing detail panels
//

import SwiftUI

extension View {
    /// Adds an interactive swipe-back gesture that follows the finger as you drag from the left edge
    /// - Parameters:
    ///   - isActive: Whether the gesture should be active
    ///   - dragOffset: Binding to track the current drag position
    ///   - onDismiss: Closure to call when the gesture completes and threshold is exceeded
    /// - Returns: View with gesture attached
    func swipeBackGesture(
        isActive: Bool,
        dragOffset: Binding<CGFloat>,
        onDismiss: @escaping () -> Void
    ) -> some View {
        let gesture = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                // Only respond if gesture started from left edge and dragging right
                if value.startLocation.x < 80 && value.translation.width > 0 {
                    dragOffset.wrappedValue = min(value.translation.width, UIScreen.main.bounds.width)
                }
            }
            .onEnded { value in
                let dragThreshold: CGFloat = 120

                // If dragged past threshold, dismiss the view
                if dragOffset.wrappedValue > dragThreshold {
                    onDismiss()
                }

                // Reset drag offset with animation
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    dragOffset.wrappedValue = 0
                }
            }

        return self.highPriorityGesture(isActive ? gesture : nil)
    }
}
