//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Erik Song on 5/3/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in the extension's Info.plist file.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield as needed for applications.
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.shield"),
            title: ShieldConfiguration.Label(
                text: "App Blocked",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete a challenge to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock with Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }

    override func configuration(shielding applicationCategory: ApplicationCategory) -> ShieldConfiguration {
        // Customize the shield as needed for application categories.
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.shield"),
            title: ShieldConfiguration.Label(
                text: "Category Blocked",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete a challenge to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock with Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.shield"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete a challenge to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock with Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }
}
