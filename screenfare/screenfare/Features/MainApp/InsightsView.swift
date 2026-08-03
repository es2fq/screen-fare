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
    @State private var isLoading = true
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
                    Text("Insights")
                        .font(.instrumentSerif(34))
                        .foregroundColor(.focusInk)

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
                .padding(.bottom, 12)

                // Segmented control (fixed, not scrollable)
                segmentedControl
                    .padding(.horizontal, 22)
                    .padding(.bottom,  20)

                // Scrollable content
                ScrollView {
                    // Total activity report (unfiltered - ALL apps)
                    // TotalActivityReport will manually separate blocked vs total
                    // Use different context based on selected range
                    ZStack(alignment: .top) {
                        DeviceActivityReport(
                            range == .today ?
                                DeviceActivityReport.Context("Total Activity") :
                                DeviceActivityReport.Context("Total Activity Week"),
                            filter: totalActivityFilter
                        )
                        .id(range) // Force re-creation when range changes
                        .padding(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 22))
                        .frame(height: 1100)
                        .allowsHitTesting(false)
                        .onAppear {
                            // Show loading initially, then hide after a brief delay
                            // (DeviceActivityReport doesn't provide a loading callback)
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isLoading = false
                                }
                            }
                        }
                        .onChange(of: range) { _, _ in
                            // Show loading when switching tabs
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isLoading = false
                                }
                            }
                        }

                        // Loading indicator overlay
                        if isLoading {
                            VStack {
                                Spacer()
                                    .frame(height: 100)

                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.focusAccent)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.focusBg.opacity(0.9))
                            .transition(.opacity)
                        }

                        // Transparent overlay to make scrolling work
                        // Note: Using white.opacity(0.001) instead of .clear because Color.clear doesn't register touches
                        Color.white.opacity(0.001)
                            .contentShape(Rectangle())
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaPadding(.top)
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

    // MARK: - Activity Filters

    // Total activity filter (unfiltered - shows ALL device activity)
    private var totalActivityFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let now = Date()

        if range == .today {
            // Today only - use hourly segments for detailed breakdown
            let interval = calendar.dateInterval(of: .day, for: now)!
            return DeviceActivityFilter(
                segment: .hourly(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        } else {
            // Last 7 days (today + previous 6 days)
            let startOfToday = calendar.startOfDay(for: now)
            let weekAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            let interval = DateInterval(start: weekAgo, end: endOfToday)
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        }
    }

    // Blocked activity filter (filtered to selected apps/categories only)
    private var blockedActivityFilter: DeviceActivityFilter {
        let interval = range == .today ?
            Calendar.current.dateInterval(of: .day, for: Date())! :
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())!

        // Filter to ONLY blocked apps/categories
        let filter = DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: blockingManager.selectedApps.applicationTokens,
            categories: blockingManager.selectedApps.categoryTokens
        )

        return filter
    }
}

#Preview {
    InsightsView(onClose: {})
}
