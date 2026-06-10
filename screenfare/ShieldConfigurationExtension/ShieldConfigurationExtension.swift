//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Erik Song on 5/3/26.
//

import ManagedSettings
import ManagedSettingsUI
import FamilyControls
import UIKit

/// Defines the appearance of the shield shown when blocked apps are accessed
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.shield"),
            title: ShieldConfiguration.Label(
                text: "Take a pause",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Tap to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }
}
