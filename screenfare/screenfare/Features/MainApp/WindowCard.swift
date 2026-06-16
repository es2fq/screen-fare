//
//  WindowCard.swift
//  Screen Fare
//
//  Editable blocking window card with expand/collapse
//

import SwiftUI

struct WindowCard: View {
    @Binding var window: BlockingWindow
    let index: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onRemove: () -> Void
    let removable: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header - always visible, fully clickable
            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text(ScheduleManager.minToLabel(window.start))
                                .font(.instrumentSerif(23))
                                .foregroundColor(.focusInk)
                                .monospacedDigit()

                            Text(" – ")
                                .font(.instrumentSerif(23, italic: true))
                                .foregroundColor(.focusMuted)

                            Text(ScheduleManager.minToLabel(window.end))
                                .font(.instrumentSerif(23))
                                .foregroundColor(.focusInk)
                                .monospacedDigit()

                            if isOvernight {
                                Text(" next day")
                                    .font(.instrumentSerif(12, italic: true))
                                    .foregroundColor(.focusMuted)
                                    .padding(.leading, 6)
                            }
                        }

                        Text(ScheduleManager.formatDays(window.days))
                            .font(.inter(12.5))
                            .foregroundColor(.focusMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.focusMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.focusLine)
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    VStack(spacing: 14) {
                        TimeStepper(label: "Starts", value: $window.start)
                        TimeStepper(label: "Ends", value: $window.end)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("On these days")
                                .font(.inter(13.5))
                                .foregroundColor(.focusMuted)

                            DayPicker(days: $window.days)
                        }

                        if removable {
                            Button(action: onRemove) {
                                Text("Remove window")
                                    .font(.inter(13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.88, green: 0.27, blue: 0.18)) // Red
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? Color.focusInk.opacity(0.18) : Color.focusLine, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var isOvernight: Bool {
        let duration = ((window.end - window.start + 1440) % 1440)
        return duration != 0 && window.end <= window.start
    }
}

#Preview {
    VStack(spacing: 20) {
        WindowCard(
            window: .constant(BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5])),
            index: 0,
            isExpanded: false,
            onToggleExpand: {},
            onRemove: {},
            removable: true
        )

        WindowCard(
            window: .constant(BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5])),
            index: 0,
            isExpanded: true,
            onToggleExpand: {},
            onRemove: {},
            removable: true
        )

        WindowCard(
            window: .constant(BlockingWindow(start: 22 * 60, end: 2 * 60, days: [0, 1, 2, 3, 4, 5, 6])),
            index: 1,
            isExpanded: false,
            onToggleExpand: {},
            onRemove: {},
            removable: false
        )
    }
    .padding()
    .background(Color.focusBg)
}
