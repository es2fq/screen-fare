//
//  screenfareApp.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import SwiftUI

@main
struct screenfareApp: App {
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()

        // Configure slider appearance globally
        configureSliderAppearance()
    }

    private func configureSliderAppearance() {
        let thumbImage = createCircularThumb(radius: 14)
        let appearance = UISlider.appearance()
        appearance.setThumbImage(thumbImage, for: .normal)
        appearance.setThumbImage(thumbImage, for: .highlighted)
    }

    private func createCircularThumb(radius: CGFloat) -> UIImage {
        let size = CGSize(width: radius * 2, height: radius * 2)
        return UIGraphicsImageRenderer(size: size).image { context in
            // Draw white circle
            UIColor.white.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fillEllipse(in: rect)

            // Draw subtle border
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            context.cgContext.setLineWidth(0.5)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 0.25, dy: 0.25))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
        }
    }
}
