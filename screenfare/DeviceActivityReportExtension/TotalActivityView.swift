//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Renders the screen time insights report
//  Design specs: insights.jsx (lines 166-200)
//

import SwiftUI
import FamilyControls
import ManagedSettings

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Shared UserDefaults instance for the app group
    fileprivate static var appGroup: UserDefaults? {
        UserDefaults(suiteName: "group.esong.screenfare.shared")
    }
}

struct TotalActivityView: View {
    let config: ActivityConfig

    // Load blocked app tokens from shared UserDefaults
    private var blockedAppTokens: Set<ApplicationToken> {
        guard let sharedDefaults = UserDefaults.appGroup,
              let data = sharedDefaults.data(forKey: "com.screenfare.selectedApps"),
              let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) else {
            return []
        }
        return tokens
    }

    var body: some View {
        VStack(spacing: 16) {
            // Hero total + week chart card (with stats inside)
            heroCard

            // "What you're limiting" section
            whatYoureLimitingSection

            // Per-app breakdown (if we have app data)
            if !config.topApps.isEmpty {
                perAppSection
            }

            // Spacer to push content to top
            Spacer()
        }
        .padding(.bottom, 20) // Bottom padding for last item
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "Total screen time" label
            Text("TOTAL SCREEN TIME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .textCase(.uppercase)

            // Total time
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // Total time in serif
                if config.totalMinutes > 0 {
                    Text(formatMinutes(config.totalMinutes))
                        .font(.custom("InstrumentSerif-Regular", size: 52))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .fontWeight(.regular)
                } else {
                    // Show placeholder when no data
                    Text("--")
                        .font(.custom("InstrumentSerif-Regular", size: 52))
                        .foregroundColor(Color(white: 0.8))
                        .fontWeight(.regular)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Caption
            Text(caption)
                .font(.system(size: 12.5))
                .foregroundColor(Color(white: 0.5))
                .padding(.bottom, 18)

            // Show hourly chart for today, week bars for week view
            if config.isWeekView {
                WeekBars(data: config.dailyData, height: 116)
            } else {
                HourlyChart(data: config.hourlyData)
            }

            // Divider
            Divider()
                .background(Color(white: 0.9))
                .padding(.vertical, 18)

            // Stats strip (inside hero card)
            HStack(spacing: 0) {
                ForEach(Array(heroStatItems.enumerated()), id: \.offset) { index, stat in
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
        }
        .padding(EdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22))
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )
        )
    }

    // MARK: - What You're Limiting Section

    private var whatYoureLimitingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            Text("WHAT YOU'RE LIMITING")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .padding(.horizontal, 4)

            // BlockedShare card - shows blocked time as percentage of total
            blockedShareCard
        }
    }

    private var blockedShareCard: some View {
        let blockedMinutes = config.blockedMinutes
        let totalMinutes = max(1, config.totalMinutes) // Avoid division by zero
        let percentage = totalMinutes > 0 ? min(100, Int(Double(blockedMinutes) / Double(totalMinutes) * 100)) : 0
        let remainingMinutes = max(0, totalMinutes - blockedMinutes)

        return VStack(alignment: .leading, spacing: 13) {
            // Header: time + percentage
            HStack(alignment: .firstTextBaseline) {
                // "23m on blocked apps" in accent color + muted
                HStack(spacing: 0) {
                    Text(formatMinutes(blockedMinutes))
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundColor(.focusAccent)

                    Text(" on blocked apps")
                        .font(.system(size: 14.5))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                // Large percentage
                Text("\(percentage)%")
                    .font(.custom("InstrumentSerif-Regular", size: 22))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background (everything else)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.92))
                        .frame(height: 10)

                    // Foreground (blocked apps)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.focusAccent)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100.0, height: 10)
                }
            }
            .frame(height: 10)

            // Legend
            HStack {
                // Blocked apps
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.focusAccent)
                        .frame(width: 7, height: 7)

                    Text("Blocked apps")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                // Everything else
                Text("Everything else · \(formatMinutes(remainingMinutes))")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )
        )
    }


    // MARK: - Per-App Section

    private var perAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            Text(config.isWeekView ? "MOST USED · THIS WEEK" : "MOST USED · TODAY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.12 * 11)
                .padding(.horizontal, 4)

            // App rows
            VStack(spacing: 0) {
                ForEach(Array(config.topApps.enumerated()), id: \.element.id) { index, appData in
                    let isBlocked = appData.token.map { blockedAppTokens.contains($0) } ?? false
                    AppUsageRow(
                        token: appData.token,
                        app: appData.app,
                        minutes: appData.minutes,
                        maxMinutes: config.topApps.first?.minutes ?? 1,
                        isLast: index == config.topApps.count - 1,
                        isBlocked: isBlocked
                    )
                }
            }
            .padding(EdgeInsets(top: 2, leading: 18, bottom: 2, trailing: 18))
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(white: 0.9), lineWidth: 1)
                    )
            )
        }
    }


    // MARK: - Helpers

    private var caption: String {
        config.isWeekView
            ? "This week · last 7 days"
            : "Today so far"
    }

    // Stats for hero card (total device stats)
    private var heroStatItems: [(value: String, label: String)] {
        if config.isWeekView {
            return [
                (value: "\(config.stats.opens * 7)", label: "Apps opened"),  // Weekly pickups estimate
                (value: config.stats.longestSessionMinutes.map { formatMinutes($0) } ?? "—", label: "Longest session"),
                (value: formatMinutes(config.totalMinutes / 7), label: "Daily avg")
            ]
        } else {
            return [
                (value: "\(config.stats.opens)", label: "Apps opened"),
                (value: config.stats.longestSessionMinutes.map { formatMinutes($0) } ?? "—", label: "Longest session"),
                (value: formatTime(config.stats.firstPickupTime), label: "First pickup")
            ]
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

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let time = formatter.string(from: date)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let period = hour < 12 ? "am" : "pm"

        return "\(time)\(period)"
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
                        .foregroundColor(.focusAccent)
                        .frame(height: 15)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize()
                        .monospacedDigit()

                    // Bar
                    let barHeight = max(5, CGFloat(day.minutes) / CGFloat(maxMinutes) * (height - 30))
                    RoundedRectangle(cornerRadius: 7)
                        .fill(day.isToday ? Color.focusAccent : Color(white: 0.86))
                        .frame(width: 30, height: barHeight)

                    // Day label
                    Text(day.dayLabel)
                        .font(.system(size: 11, weight: day.isToday ? .semibold : .medium))
                        .foregroundColor(day.isToday ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(white: 0.5))
                        .lineLimit(1)
                        .fixedSize()
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
    let token: ApplicationToken?
    let app: Application
    let minutes: Int
    let maxMinutes: Int
    let isLast: Bool
    let isBlocked: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                // Icon: Use Label with token if available, else generic icon
                ZStack(alignment: .topTrailing) {
                    if let token = token {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .frame(width: 48, height: 48)
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.gray)
                            .frame(width: 48, height: 48)
                    }

                    // Lock badge for blocked apps
                    if isBlocked {
                        LockBadgeView()
                            .offset(x: 4, y: -4)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    // Name: Always use the Application's localizedDisplayName directly
                    HStack {
                        Text(app.localizedDisplayName ?? "App")
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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
                            .fill(isCurrentHour ? Color.focusAccent : Color(white: 0.88))
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
                            .lineLimit(1)
                            .fixedSize()
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

// MARK: - Lock Badge View

struct LockBadgeView: View {
    private let size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.focusAccent)
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.28), radius: 4, x: 0, y: 1)

            // Lock icon using SF Symbol (matches NUX flow)
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "E9E5DE"))
        }
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
        totalMinutes: 208,
        blockedMinutes: 23,
        dailyData: [
            DayData(dayLabel: "M", minutes: 224, isToday: false),
            DayData(dayLabel: "T", minutes: 251, isToday: false),
            DayData(dayLabel: "W", minutes: 198, isToday: false),
            DayData(dayLabel: "T", minutes: 212, isToday: false),
            DayData(dayLabel: "F", minutes: 246, isToday: false),
            DayData(dayLabel: "S", minutes: 44, isToday: false),
            DayData(dayLabel: "S", minutes: 23, isToday: true)
        ],
        hourlyData: mockHourlyData,
        topApps: [],  // Can't create mock ApplicationTokens for preview
        stats: ActivityStats(
            opens: 11,
            blockedOpens: 8,
            perDay: 12,
            busiest: "Mon",
            firstPickupTime: Calendar.current.date(bySettingHour: 7, minute: 21, second: 0, of: Date()),
            firstBlockedOpenTime: Calendar.current.date(bySettingHour: 8, minute: 42, second: 0, of: Date()),
            longestSessionMinutes: 22
        ),
        isWeekView: false
    )

    TotalActivityView(config: mockConfig)
        .padding()
        .background(Color(red: 0.91, green: 0.89, blue: 0.87))
}
