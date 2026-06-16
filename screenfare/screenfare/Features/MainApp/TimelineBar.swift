//
//  TimelineBar.swift
//  Screen Fare
//
//  24-hour timeline visualization for blocking schedules
//

import SwiftUI

struct TimelineBar: View {
    let windows: [BlockingWindow]
    let allday: Bool
    var height: CGFloat = 40
    var showLabels: Bool = true
    var showNow: Bool = true

    private let ticks = [0, 360, 720, 1080, 1440]
    private let tickLabels = ["12a", "6a", "12p", "6p", "12a"]

    var body: some View {
        VStack(spacing: 0) {
            // Timeline bar
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.focusInk.opacity(0.05))
                    .frame(height: height)

                // Hour gridlines
                GeometryReader { geometry in
                    ForEach(ticks.dropFirst().dropLast(), id: \.self) { tick in
                        Rectangle()
                            .fill(Color.focusInk.opacity(0.06))
                            .frame(width: 1, height: height)
                            .offset(x: CGFloat(tick) / 1440 * geometry.size.width)
                    }
                }
                .frame(height: height)

                // Active segments
                GeometryReader { geometry in
                    ForEach(Array(segmentGroups.enumerated()), id: \.offset) { groupIndex, segments in
                        ForEach(Array(segments.enumerated()), id: \.offset) { segIndex, segment in
                            let (start, end) = segment
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.focusInk)
                                .frame(
                                    width: max(3, CGFloat(end - start) / 1440 * geometry.size.width),
                                    height: height - 8
                                )
                                .offset(
                                    x: CGFloat(start) / 1440 * geometry.size.width,
                                    y: 4
                                )
                        }
                    }
                }
                .frame(height: height)

                // Current time marker
                if showNow {
                    GeometryReader { geometry in
                        let now = Date()
                        let calendar = Calendar.current
                        let nowMin = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

                        Rectangle()
                            .fill(Color.focusAccent)
                            .frame(width: 2)
                            .offset(x: CGFloat(nowMin) / 1440 * geometry.size.width - 1, y: -2)
                            .shadow(color: Color.focusBg.opacity(0.6), radius: 2)
                    }
                    .frame(height: height + 4)
                }
            }
            .frame(height: height)

            // Time labels
            if showLabels {
                HStack {
                    ForEach(0..<tickLabels.count, id: \.self) { i in
                        if i == 0 {
                            Text(tickLabels[i])
                                .font(.system(size: 9.5))
                                .foregroundColor(.focusMuted)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if i == tickLabels.count - 1 {
                            Text(tickLabels[i])
                                .font(.system(size: 9.5))
                                .foregroundColor(.focusMuted)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Text(tickLabels[i])
                                .font(.system(size: 9.5))
                                .foregroundColor(.focusMuted)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    // Compute segments for each window (handles overnight wrapping)
    private var segmentGroups: [[(Int, Int)]] {
        if allday {
            return [[(0, 1440)]]
        }

        return windows.map { window in
            let start = ((window.start % 1440) + 1440) % 1440
            var end = ((window.end % 1440) + 1440) % 1440

            if end <= start {
                // Overnight wrap
                end += 1440
            }

            if end <= 1440 {
                return [(start, end)]
            } else {
                // Split into two segments
                return [(start, 1440), (0, end - 1440)]
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // All day
        VStack(alignment: .leading, spacing: 8) {
            Text("All day")
                .font(.caption)
                .foregroundColor(.secondary)
            TimelineBar(windows: [], allday: true, height: 40)
        }

        // Single window
        VStack(alignment: .leading, spacing: 8) {
            Text("9 AM - 5 PM")
                .font(.caption)
                .foregroundColor(.secondary)
            TimelineBar(
                windows: [BlockingWindow(start: 9 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5])],
                allday: false,
                height: 40
            )
        }

        // Multiple windows
        VStack(alignment: .leading, spacing: 8) {
            Text("Multiple windows")
                .font(.caption)
                .foregroundColor(.secondary)
            TimelineBar(
                windows: [
                    BlockingWindow(start: 9 * 60, end: 12 * 60, days: [1, 2, 3, 4, 5]),
                    BlockingWindow(start: 13 * 60, end: 17 * 60, days: [1, 2, 3, 4, 5]),
                    BlockingWindow(start: 20 * 60, end: 23 * 60, days: [0, 1, 2, 3, 4, 5, 6])
                ],
                allday: false,
                height: 40
            )
        }

        // Overnight window
        VStack(alignment: .leading, spacing: 8) {
            Text("Overnight (10 PM - 2 AM)")
                .font(.caption)
                .foregroundColor(.secondary)
            TimelineBar(
                windows: [BlockingWindow(start: 22 * 60, end: 2 * 60, days: [0, 1, 2, 3, 4, 5, 6])],
                allday: false,
                height: 40
            )
        }
    }
    .padding()
    .background(Color.focusBg)
}
