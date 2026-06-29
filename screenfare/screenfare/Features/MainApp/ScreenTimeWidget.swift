//
//  ScreenTimeWidget.swift
//  Screen Fare
//
//  Compact screen time card for Today view
//  Uses embedded DeviceActivityReport for real Screen Time data
//

import SwiftUI
import DeviceActivity

struct ScreenTimeWidget: View {
    let onOpen: () -> Void

    var body: some View {
        ZStack {
            // Embed the compact DeviceActivityReport
            DeviceActivityReport(
                DeviceActivityReport.Context("Compact Activity"),
                filter: activityFilter
            )
            .allowsHitTesting(false)  // Disable hit testing so touches pass through
            .frame(minHeight: 100, maxHeight: 100)
            .padding(EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.focusLine, lineWidth: 1)
                    )
            )

            // Transparent overlay to capture all taps
            // Note: Using white.opacity(0.001) instead of .clear because Color.clear doesn't register touches
            Color.white.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.impact()
                    onOpen()
                }
        }
    }

    // MARK: - Activity Filter

    private var activityFilter: DeviceActivityFilter {
        // Get last 7 days for the week chart
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

        let interval = DateInterval(start: weekAgo, end: endOfToday)

        let filter = DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )

        return filter
    }
}

#Preview {
    ScreenTimeWidget(onOpen: {})
        .padding()
        .background(Color.focusBg)
}
