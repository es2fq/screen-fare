//
//  CompactActivityView.swift
//  DeviceActivityReportExtension
//
//  Compact view for Today screen widget
//

import SwiftUI

struct CompactActivityView: View {
    let config: CompactActivityConfig

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Total time + delta
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    // Total time (Instrument Serif Italic to match "Today.")
                    Text(formatMinutes(config.totalMinutes))
                        .font(.custom("InstrumentSerif-Italic", size: 40))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .fixedSize()  // Don't constrain - let it take natural width

                    // Delta chip
                    deltaChip
                }

                Text("screen time today")
                    .font(.custom("Inter_18pt-Regular", size: 12.5))
                    .foregroundColor(Color(white: 0.5))
                    .padding(.top, 7)
            }

            Spacer()

            // Right side: Mini week chart
            miniWeekChart
                .frame(width: 132)
        }
    }

    // MARK: - Delta Chip

    private var deltaChip: some View {
        let delta = calculateDelta()
        let isDown = delta > 0
        let color = isDown ? Color.orange : Color(white: 0.5)

        return HStack(spacing: 4) {
            Image(systemName: isDown ? "arrow.down" : "arrow.up")
                .font(.custom("Inter_18pt-SemiBold", size: 11))

            Text("\(abs(delta))%")
                .font(.custom("Inter_18pt-SemiBold", size: 12.5))
        }
        .foregroundColor(color)
    }

    // MARK: - Mini Week Chart

    private var miniWeekChart: some View {
        let maxMinutes = config.weekMinutes.max() ?? 1

        return HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(config.weekMinutes.enumerated()), id: \.offset) { index, minutes in
                let isToday = index == 6
                VStack(spacing: 4) {
                    // Spacer to push everything down
                    Spacer(minLength: 0)

                    // Bar
                    let barHeight = max(3, CGFloat(minutes) / CGFloat(maxMinutes) * 44)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isToday ? Color.orange : Color(white: 0.86))
                        .frame(height: barHeight)

                    // Day label
                    Text(dayLabel(for: index))
                        .font(.custom(isToday ? "Inter_18pt-SemiBold" : "Inter_18pt-Medium", size: 9))
                        .foregroundColor(isToday ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(white: 0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 68)
    }

    // MARK: - Helpers

    private func calculateDelta() -> Int {
        let today = config.totalMinutes
        let yesterday = config.weekMinutes.count > 1 ? config.weekMinutes[5] : 0

        guard yesterday > 0 else { return 0 }
        return Int((1.0 - Double(today) / Double(yesterday)) * 100)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        guard let date = calendar.date(byAdding: .day, value: -(6 - index), to: today) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    CompactActivityView(config: CompactActivityConfig(
        totalMinutes: 23,
        weekMinutes: [72, 64, 48, 51, 39, 44, 23]
    ))
    .padding()
    .background(Color(red: 0.91, green: 0.89, blue: 0.87))
}
