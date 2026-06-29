//
//  InsightsView.swift
//  Screen Fare
//
//  Full-screen insights view showing screen time stats
//  Design specs: insights.jsx → InsightsScreen (lines 122-202)
//

import SwiftUI
import DeviceActivity
import FamilyControls

struct InsightsView: View {
    let onClose: () -> Void
    @State private var range: TimeRange = .today
    @StateObject private var blockingManager = AppBlockingManager.shared

    enum TimeRange: String {
        case today = "Today"
        case week = "This week"
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack(spacing: 0) {
                    Button(action: onClose) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Today")
                                .font(.inter(15))
                        }
                        .foregroundColor(.focusInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // Title
                HStack {
                    (Text("Insights")
                        .font(.instrumentSerif(34))
                     + Text(".")
                        .font(.instrumentSerif(34, italic: true))
                        .foregroundColor(.focusMuted))
                    .foregroundColor(.focusInk)

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
                .padding(.bottom, 12)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Segmented control
                        segmentedControl
                            .padding(.horizontal, 22)

                        // DeviceActivityReport - embedded here
                        // The system will render the actual values
                        DeviceActivityReport(
                            DeviceActivityReport.Context("Total Activity"),
                            filter: activityFilter
                        )
                        .padding(.horizontal, 22)
                        .padding(.top, 16)

                        // Privacy note
                        reportNote
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        Spacer().frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: 3) {
            ForEach([TimeRange.today, TimeRange.week], id: \.self) { option in
                Button(action: {
                    HapticManager.shared.impact()
                    range = option
                }) {
                    Text(option.rawValue)
                        .font(.inter(13, weight: .semibold))
                        .foregroundColor(range == option ? .focusInk : .focusMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 33)
                        .background(range == option ? Color.white : Color.clear)
                        .cornerRadius(10)
                        .shadow(color: range == option ? Color.black.opacity(0.10) : Color.clear, radius: 1, y: 1)
                }
            }
        }
        .padding(3)
        .background(Color.focusInk.opacity(0.05))
        .cornerRadius(13)
    }

    // MARK: - Activity Filter

    private var activityFilter: DeviceActivityFilter {
        // Use hourly segments for more detailed breakdown
        let interval = range == .today ?
            Calendar.current.dateInterval(of: .day, for: Date())! :
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())!

        let filter = DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )

        return filter
    }

    // MARK: - Privacy Note

    private var reportNote: some View {
        HStack(alignment: .top, spacing: 9) {
            // Shield icon
            Image(systemName: "shield")
                .font(.system(size: 15))
                .foregroundColor(.focusMuted)
                .padding(.top, 1)

            Text("Measured by iOS Screen Time for all apps on your device. Screen Fare styles this view — it never reads the numbers behind it.")
                .font(.inter(11.5))
                .foregroundColor(.focusMuted)
                .lineSpacing(11.5 * 0.45)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    InsightsView(onClose: {})
}
