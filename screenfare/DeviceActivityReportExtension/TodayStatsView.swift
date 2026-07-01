//
//  TodayStatsView.swift
//  DeviceActivityReportExtension
//
//  Minimal view showing today's blocked app time for Today card StatPill
//

import SwiftUI

struct TodayStatsView: View {
    let config: TodayStatsConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatMinutes(config.blockedMinutes))
                .font(.custom("InstrumentSerif-Regular", size: 26))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
