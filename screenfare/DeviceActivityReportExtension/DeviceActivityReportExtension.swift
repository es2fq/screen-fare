//
//  DeviceActivityReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created by Erik Song on 6/28/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ScreenFareReportExtension: DeviceActivityReportExtension {
    nonisolated var body: some DeviceActivityReportScene {
        // Full insights report (unfiltered - manually separates total vs blocked)
        TotalActivityReport { totalActivity in
            TotalActivityView(config: totalActivity)
        }

        // Compact widget report
        CompactActivityReport { compactActivity in
            CompactActivityView(config: compactActivity)
        }
    }
}
