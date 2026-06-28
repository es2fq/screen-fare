//
//  PaywallView.swift
//  Screen Fare
//
//  Subscription paywall with bottom sheet presentation
//  Design: paywall.jsx → PaywallSheet
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isPurchasing = false
    @State private var showError: String?

    enum SubscriptionPlan {
        case monthly
        case annual

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            }
        }

        var price: String {
            switch self {
            case .monthly: return "$4.99"
            case .annual: return "$49.99"
            }
        }

        var period: String {
            switch self {
            case .monthly: return "/mo"
            case .annual: return "/yr"
            }
        }

        var note: String {
            switch self {
            case .monthly: return "Billed monthly"
            case .annual: return "Just $4.17/mo, billed yearly"
            }
        }

        var badge: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save 17%"
            }
        }
    }

    var body: some View {
        ZStack {
            // Full screen background
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with logo and close button (matching ChallengeView)
                HStack(alignment: .center) {
                    ProMark()

                    Spacer()

                    CloseX {
                        dismiss()
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 44)
                .padding(.bottom, 4)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(minHeight: 20)

                        VStack(alignment: .leading, spacing: 0) {
                            // Title
                            Group {
                                Text("Upgrade your ")
                                    .font(.instrumentSerif(40))
                                + Text("ride.")
                                    .font(.instrumentSerif(40, italic: true))
                            }
                            .foregroundColor(.focusInk)
                            .lineSpacing(1.0)
                            .padding(.bottom, 10)

                            // Subtitle
                            Text("The full fare, for serious focus.")
                                .font(.inter(15))
                                .foregroundColor(.focusMuted)
                                .lineSpacing(6)
                                .padding(.bottom, 20)

                            // Challenge Proof Panel
                            ChallengeProofPanel()
                                .padding(.bottom, 22)

                            // Features
                            VStack(spacing: 18) {
                                FeatureRow(
                                    iconName: "ticket",
                                    title: "Access to all fares",
                                    subtitle: "Every kind of friction — pick what fits the moment."
                                )

                                FeatureRow(
                                    iconName: "calendar",
                                    title: "Custom schedules",
                                    subtitle: "Choose the exact times your apps go quiet."
                                )

                                FeatureRow(
                                    iconName: "lock.fill",
                                    title: "Strict mode",
                                    subtitle: "Stay committed by locking changes behind a fare."
                                )
                            }
                            .padding(.bottom, 20)

                            // Plan selector (segmented toggle)
                            PlanSegmentedControl(selectedPlan: $selectedPlan)
                                .padding(.bottom, 18)

                            // CTA Button
                            TrialButton(
                                plan: selectedPlan,
                                isPurchasing: isPurchasing,
                                action: handlePurchase
                            )

                            // Footer links
                            FooterLinks(onRestore: handleRestore)
                                .padding(.top, 16)
                        }
                        .padding(.horizontal, 22)

                        Spacer()
                            .frame(minHeight: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .alert("Error", isPresented: .constant(showError != nil), actions: {
            Button("OK") {
                showError = nil
            }
        }, message: {
            if let error = showError {
                Text(error)
            }
        })
    }

    // MARK: - Actions

    private func handlePurchase() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                let product: Product?
                switch selectedPlan {
                case .monthly:
                    product = subscriptionManager.monthlyProduct
                case .annual:
                    product = subscriptionManager.annualProduct
                }

                guard let product = product else {
                    showError = "Product not available"
                    return
                }

                let transaction = try await subscriptionManager.purchase(product)

                if transaction != nil {
                    // Purchase successful
                    dismiss()
                }
            } catch {
                showError = error.localizedDescription
            }
        }
    }

    private func handleRestore() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
            } catch {
                showError = error.localizedDescription
            }
        }
    }

}

// MARK: - Components

struct ChallengeProofPanel: View {
    let challenges = [
        ("Typing", "keyboard"),
        ("Memory", "brain.head.profile"),
        ("Breathing", "wind"),
        ("Intent", "bubble.left.fill"),
        ("Patience", "hourglass"),
        ("Walk", "figure.walk")
    ]

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(challenges, id: \.0) { challenge in
                    VStack(spacing: 7) {
                        // Icon container
                        ZStack {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color.focusInk.opacity(0.05))
                                .frame(width: 40, height: 40)

                            Image(systemName: challenge.1)
                                .font(.system(size: 15))
                                .foregroundColor(.focusInk)
                        }

                        // Name
                        Text(challenge.0)
                            .font(.inter(11.5, weight: .medium))
                            .foregroundColor(.focusMuted)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.focusLine, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ProMark: View {
    var body: some View {
        HStack(spacing: 8) {
            // Brand icon
            Image("BrandIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .cornerRadius(7)

            // Text
            HStack(spacing: 0) {
                Text("SCREEN FARE ")
                    .font(.inter(12.5, weight: .semibold))
                    .foregroundColor(.focusMuted)
                    .tracking(1.75)

                Text("PRO")
                    .font(.inter(12.5, weight: .semibold))
                    .foregroundColor(.focusInk)
                    .tracking(1.75)
            }
        }
    }
}


struct FeatureRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.focusInk.opacity(0.05))
                    .frame(width: 34, height: 34)

                Image(systemName: iconName)
                    .font(.system(size: 13.5))
                    .foregroundColor(.focusInk)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.inter(15.5, weight: .semibold))
                    .foregroundColor(.focusInk)

                Text(subtitle)
                    .font(.inter(13))
                    .foregroundColor(.focusMuted)
                    .lineSpacing(1.6)
            }

            Spacer()
        }
    }
}

struct PlanSegmentedControl: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan

    var body: some View {
        HStack(spacing: 4) {
            PlanSegment(
                plan: .annual,
                isSelected: selectedPlan == .annual,
                action: { selectedPlan = .annual }
            )

            PlanSegment(
                plan: .monthly,
                isSelected: selectedPlan == .monthly,
                action: { selectedPlan = .monthly }
            )
        }
        .padding(4)
        .background(Color.focusInk.opacity(0.05))
        .cornerRadius(13)
    }
}

struct PlanSegment: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    Text(plan.displayName)
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(isSelected ? .focusInk : .focusMuted)

                    if let badge = plan.badge {
                        Text(badge)
                            .font(.inter(9.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(red: 0.55, green: 0.65, blue: 0.4))
                            .cornerRadius(5)
                            .tracking(0.2)
                    }
                }

                Text(plan.price + plan.period)
                    .font(.inter(12))
                    .foregroundColor(.focusMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(10)
            .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 3, x: 0, y: 1)
        }
    }
}

struct TrialButton: View {
    let plan: PaywallView.SubscriptionPlan
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Start 7-day free trial")
                        .font(.inter(16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("then \(plan.price)\(plan.period) · cancel anytime")
                        .font(.inter(11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.focusAccent)
            .cornerRadius(16)
        }
        .disabled(isPurchasing)
    }
}

struct FooterLinks: View {
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button(action: onRestore) {
                Text("Restore")
                    .font(.inter(12))
                    .foregroundColor(.focusMuted)
            }

            Text("·")
                .font(.inter(12))
                .foregroundColor(.focusMuted.opacity(0.4))

            Link("Terms", destination: URL(string: "https://screenfare.app/terms")!)
                .font(.inter(12))
                .foregroundColor(.focusMuted)

            Text("·")
                .font(.inter(12))
                .foregroundColor(.focusMuted.opacity(0.4))

            Link("Privacy", destination: URL(string: "https://screenfare.app/privacy")!)
                .font(.inter(12))
                .foregroundColor(.focusMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PaywallView()
}
