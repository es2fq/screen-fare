//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Renders the screen time insights report
//  Design specs: insights.jsx (lines 166-200)
//

import SwiftUI

struct TotalActivityView: View {
    let config: ActivityConfig

    var body: some View {
        VStack(spacing: 16) {
            // Hero total + week chart card
            heroCard

            // Hourly breakdown chart
            hourlyBreakdownSection

            // Per-app breakdown (if we have app data)
            if !config.topApps.isEmpty {
                perAppSection
            }

            // Activity stats card
            activityStatsCard
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "Screen time" label
            Text("SCREEN TIME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .textCase(.uppercase)

            // Total time + delta
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // Total time in serif
                Text(formatMinutes(config.totalMinutes))
                    .font(.custom("InstrumentSerif-Regular", size: 52))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .fontWeight(.regular)

                // Delta chip
                if config.totalMinutes > 0 && config.previousMinutes > 0 {
                    deltaChip
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Caption
            Text(caption)
                .font(.system(size: 12.5))
                .foregroundColor(Color(white: 0.5))
                .padding(.bottom, 18)

            // Week bars
            WeekBars(data: config.dailyData, height: 116)
        }
        .padding(EdgeInsets(top: 20, leading: 22, bottom: 22, trailing: 22))
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(white: 0.9), lineWidth: 1)
        )
    }

    // MARK: - Hourly Breakdown Section

    private var hourlyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            Text("HOURLY BREAKDOWN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .padding(.horizontal, 4)

            // Hourly chart
            VStack(spacing: 0) {
                HourlyChart(data: config.hourlyData)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(white: 0.9), lineWidth: 1)
            )
        }
    }

    // MARK: - Per-App Section

    private var perAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            Text("MOST USED TODAY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .padding(.horizontal, 4)

            // App rows
            VStack(spacing: 0) {
                ForEach(Array(config.topApps.enumerated()), id: \.element.id) { index, app in
                    AppUsageRow(
                        appName: app.name,
                        minutes: app.minutes,
                        maxMinutes: config.topApps.first?.minutes ?? 1,
                        isLast: index == config.topApps.count - 1
                    )
                }
            }
            .padding(EdgeInsets(top: 2, leading: 18, bottom: 2, trailing: 18))
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(white: 0.9), lineWidth: 1)
            )
        }
    }

    // MARK: - Activity Stats Card

    private var activityStatsCard: some View {
        HStack(spacing: 0) {
            ForEach(Array(statItems.enumerated()), id: \.offset) { index, stat in
                VStack(alignment: .leading, spacing: 6) {
                    Text(stat.value)
                        .font(.custom("InstrumentSerif-Regular", size: 28))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text(stat.label)
                        .font(.system(size: 10.5))
                        .foregroundColor(Color(white: 0.5))
                        .tracking(0.02 * 10.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(white: 0.9), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var deltaChip: some View {
        let delta = calculateDelta()
        let isDown = delta > 0
        let color = isDown ? Color.orange : Color(white: 0.5)

        return HStack(spacing: 4) {
            // Arrow
            Image(systemName: isDown ? "arrow.down" : "arrow.up")
                .font(.system(size: 11, weight: .semibold))

            Text("\(abs(delta))%")
                .font(.system(size: 12.5, weight: .semibold))
        }
        .foregroundColor(color)
    }

    private func calculateDelta() -> Int {
        guard config.previousMinutes > 0 else { return 0 }
        return Int((1.0 - Double(config.totalMinutes) / Double(config.previousMinutes)) * 100)
    }

    private var caption: String {
        "Today so far · vs yesterday"
    }

    private var statItems: [(value: String, label: String)] {
        [
            (value: "\(config.stats.opens)", label: "Opens"),
            (value: "8:42", label: "First open"),
            (value: formatMinutes(config.topApps.first?.minutes ?? 0), label: "Longest")
        ]
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

// MARK: - Week Bars Component

struct WeekBars: View {
    let data: [DayData]
    let height: CGFloat

    var body: some View {
        let maxMinutes = data.map { $0.minutes }.max() ?? 1

        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 0) {
                    // Time label (only for today)
                    Text(day.isToday ? formatMinutes(day.minutes) : "")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(height: 15)
                        .monospacedDigit()

                    // Bar
                    let barHeight = max(5, CGFloat(day.minutes) / CGFloat(maxMinutes) * (height - 30))
                    RoundedRectangle(cornerRadius: 7)
                        .fill(day.isToday ? Color.orange : Color(white: 0.86))
                        .frame(width: 30, height: barHeight)

                    // Day label
                    Text(day.dayLabel)
                        .font(.system(size: 11, weight: day.isToday ? .semibold : .medium))
                        .foregroundColor(day.isToday ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(white: 0.5))
                        .padding(.top, 7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

// MARK: - App Usage Row Component

struct AppUsageRow: View {
    let appName: String
    let minutes: Int
    let maxMinutes: Int
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 13) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.94))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 7) {
                    // App name + time
                    HStack {
                        Text(appName)
                            .font(.system(size: 14.5, weight: .medium))
                            .lineLimit(1)

                        Spacer()

                        Text(formatMinutes(minutes))
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                            .monospacedDigit()
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(white: 0.95))
                                .frame(height: 5)

                            let percentage = CGFloat(minutes) / CGFloat(max(1, maxMinutes))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                                .frame(width: max(geometry.size.width * 0.07, geometry.size.width * percentage), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .background(Color(white: 0.9))
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

// MARK: - Hourly Chart Component

struct HourlyChart: View {
    let data: [HourData]

    var body: some View {
        let maxMinutes = data.map { $0.minutes }.max() ?? 1
        let currentHour = Calendar.current.component(.hour, from: Date())

        VStack(spacing: 8) {
            // Chart bars
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data) { hourData in
                    let isCurrentHour = hourData.hour == currentHour
                    let barHeight = maxMinutes > 0 ? max(2, CGFloat(hourData.minutes) / CGFloat(maxMinutes) * 80) : 2

                    VStack(spacing: 2) {
                        // Bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isCurrentHour ? Color.orange : Color(white: 0.88))
                            .frame(height: barHeight)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)

            // Hour labels (show every 3 hours)
            HStack(spacing: 0) {
                ForEach(data) { hourData in
                    if hourData.hour % 3 == 0 {
                        Text(formatHour(hourData.hour))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}

// MARK: - Preview

#Preview {
    let mockHourlyData: [HourData] = (0..<24).map { hour in
        // Mock some usage pattern
        let minutes: Int
        if hour >= 7 && hour <= 23 {
            minutes = Int.random(in: 5...30)
        } else {
            minutes = Int.random(in: 0...5)
        }
        return HourData(id: hour, hour: hour, minutes: minutes)
    }

    let mockConfig = ActivityConfig(
        totalMinutes: 23,
        previousMinutes: 44,
        dailyData: [
            DayData(dayLabel: "M", minutes: 72, isToday: false),
            DayData(dayLabel: "T", minutes: 64, isToday: false),
            DayData(dayLabel: "W", minutes: 48, isToday: false),
            DayData(dayLabel: "T", minutes: 51, isToday: false),
            DayData(dayLabel: "F", minutes: 39, isToday: false),
            DayData(dayLabel: "S", minutes: 44, isToday: false),
            DayData(dayLabel: "S", minutes: 23, isToday: true)
        ],
        hourlyData: mockHourlyData,
        topApps: [
            AppData(id: "1", name: "Instagram", minutes: 9),
            AppData(id: "2", name: "TikTok", minutes: 6),
            AppData(id: "3", name: "YouTube", minutes: 5),
            AppData(id: "4", name: "Reddit", minutes: 3)
        ],
        stats: ActivityStats(opens: 11, perDay: 12, busiest: "Mon")
    )

    TotalActivityView(config: mockConfig)
        .padding()
        .background(Color(red: 0.91, green: 0.89, blue: 0.87))
}
