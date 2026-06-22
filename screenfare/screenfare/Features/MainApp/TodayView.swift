//
//  TodayView.swift
//  Screen Fare
//
//  Main "Today" tab - pixel-perfect implementation from handoff
//  Design specs: app.jsx → HomeScreen (lines 149-273)
//

import SwiftUI
import FamilyControls
import ManagedSettings
import Combine

struct TodayView: View {
    @StateObject private var blockingManager = AppBlockingManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var statsManager = StatsManager.shared
    @State private var currentTime = Date()

    // Strict mode gate
    @State private var showGate: ChallengeGateData?
    @State private var lockShakeCount = 0

    @State private var timerCancellable: AnyCancellable?

    // History view state
    @Binding var showingHistoryView: Bool
    @State private var dragOffset: CGFloat = 0

    // Tab navigation
    @Binding var selectedTab: Int

    init(showingHistoryView: Binding<Bool> = .constant(false), selectedTab: Binding<Int> = .constant(0)) {
        _showingHistoryView = showingHistoryView
        _selectedTab = selectedTab
    }

    // Check if there are any non-expired unlocks
    private var hasActiveUnlocks: Bool {
        let hasActiveApps = blockingManager.temporaryUnlocks.contains { $0.value > currentTime }
        let hasActiveCategories = blockingManager.temporaryCategoryUnlocks.contains { $0.value > currentTime }
        return hasActiveApps || hasActiveCategories
    }

    var body: some View {
        ZStack {
            // MAIN TODAY LAYER
            mainTodayLayer
                .offset(x: showingHistoryView ? -90 : 0)
                .brightness(showingHistoryView ? -0.03 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: showingHistoryView)
                .animation(nil, value: dragOffset) // Don't animate background during drag

            // HISTORY VIEW LAYER
            historyLayer
                .offset(x: showingHistoryView ? dragOffset : UIScreen.main.bounds.width)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: -6, y: 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.88), value: showingHistoryView)
                .animation(.interactiveSpring(), value: dragOffset)
                .swipeBackGesture(isActive: showingHistoryView, dragOffset: $dragOffset, onDismiss: {
                    showingHistoryView = false
                })
        }
        .onAppear {
            // Start timer for updating current time
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    currentTime = Date()
                }

            // Clean up any expired unlocks when user views Today tab
            blockingManager.cleanupExpiredUnlocks()
            // Load any pending history events from shield extension
            historyManager.loadPendingEvents()
        }
        .onChange(of: hasActiveUnlocks) { oldValue, newValue in
            // Only cleanup when unlocks transition from active to none
            if oldValue && !newValue {
                blockingManager.cleanupExpiredUnlocks()
            }
        }
        .onDisappear {
            // Cancel timer to prevent memory leak
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Also load pending events when app comes to foreground
            historyManager.loadPendingEvents()
        }
        .sheet(item: $showGate) { data in
            ChallengeGate(
                data: data,
                difficulty: settings.challengeDifficulty.numericLevel
            )
            .presentationBackground(.clear)
        }
    }

    // MARK: - Main Today Layer

    private var mainTodayLayer: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header with title and date
                HStack(alignment: .bottom) {
                    (Text("Today")
                        .font(.instrumentSerif(36))
                     + Text(".")
                        .font(.instrumentSerif(36, italic: true))
                        .foregroundColor(.focusMuted))
                    .foregroundColor(.focusInk)

                    Spacer()

                    Text(formattedDate)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView {
            VStack(spacing: 0) {
                // Status hero card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(blockingManager.isBlocking ? Color.focusAccent.opacity(0.07) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(blockingManager.isBlocking ? Color.focusAccent.opacity(0.32) : Color.focusLine, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 0) {
                        // Top row: "Screen Fare is on/off" + Toggle
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 7) {
                                    // Accent dot - only show when blocking
                                    if blockingManager.isBlocking {
                                        Circle()
                                            .fill(Color.focusAccent)
                                            .frame(width: 7, height: 7)
                                    }

                                    Text("Screen Fare is")
                                        .font(.inter(11))
                                        .foregroundColor(Color.focusInk.opacity(blockingManager.isBlocking ? 0.55 : 0.5))
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                }

                                if blockingManager.isBlocking {
                                    (Text("on")
                                        .font(.instrumentSerif(44))
                                        .foregroundColor(.focusAccent)
                                     + Text(".")
                                        .font(.instrumentSerif(44, italic: true))
                                        .foregroundColor(.focusAccent))
                                } else {
                                    Text("off")
                                        .font(.instrumentSerif(44, italic: true))
                                        .foregroundColor(.focusInk)
                                }
                            }

                            Spacer()

                            // Lock icon (strict mode protection) + Toggle
                            HStack(spacing: 9) {
                                // Lock icon - only show when strict mode guards the off switch
                                if settings.strictModeEnabled && settings.strictProtectOff && blockingManager.isBlocking {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.focusInk.opacity(0.5))
                                        .modifier(ShakeModifier(trigger: lockShakeCount))
                                }

                                // Custom toggle switch
                                CustomToggleWithColors(
                                    isOn: Binding(
                                        get: { blockingManager.isBlocking },
                                        set: { _ in }
                                    ),
                                    onToggle: { newValue in
                                        if newValue {
                                            blockingManager.applyBlocking()
                                        } else {
                                            handleTurnOffBlocking()
                                        }
                                    },
                                    trackColorOn: .focusInk,
                                    trackColorOff: Color.focusInk.opacity(0.15)
                                )
                            }
                        }

                        // Stats row
                        HStack(spacing: 0) {
                            StatPill(value: statsManager.blocksToday, label: "Blocks", textColor: .focusInk)
                            StatPill(value: statsManager.faresPaid, label: "Fares paid", textColor: .focusInk)
                            StatPill(value: statsManager.timeSpent, label: "On blocked apps", textColor: .focusInk)
                        }
                        .padding(.top, 22)
                        .overlay(
                            Rectangle()
                                .fill(Color.focusInk.opacity(blockingManager.isBlocking ? 0.08 : 0.08))
                                .frame(height: 1),
                            alignment: .top
                        )
                    }
                    .padding(22)
                    .padding(.bottom, 2)
                }

                // Active fare section
                SectionHeader(title: "Active fare")
                    .padding(.top, 22)

                Button(action: {
                    selectedTab = 2
                }) {
                    AppCard(padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.focusAccent)
                                    .frame(width: 36, height: 36)

                                Image(systemName: challengeTypeIcon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(challengeTypeName) · \(difficultyText)")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.focusInk)

                                Text("Unlock for \(settings.unlockDurationText) after solving")
                                    .font(.inter(12.5))
                                    .foregroundColor(.focusMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.focusMuted)
                        }
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.plain)

                // Unlocked now section - show unlocked apps and categories with countdown
                if hasActiveUnlocks {
                    UnlockedNowSection(
                        temporaryUnlocks: blockingManager.temporaryUnlocks,
                        temporaryCategoryUnlocks: blockingManager.temporaryCategoryUnlocks,
                        currentTime: currentTime,
                        onLock: { appData in
                            blockingManager.relockApp(appData: appData)
                        }
                    )
                    .padding(.top, 22)
                }

                // Recent activity section
                HStack(alignment: .lastTextBaseline) {
                    Text("RECENT")
                        .font(.inter(11, weight: .semibold))
                        .foregroundColor(.focusMuted)
                        .tracking(0.6)

                    Spacer()

                    if !historyManager.recentEvents.isEmpty {
                        Button(action: { showingHistoryView = true }) {
                            HStack(spacing: 2) {
                                Text("See all")
                                    .font(.inter(13, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.focusAccent)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 22)
                .padding(.bottom, 10)

                AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                    if historyManager.recentEvents.isEmpty {
                        // Empty state - matches design from empty-states.jsx
                        EmptyState(
                            icon: EmptyStateIcons.recent(),
                            title: Text("Nothing ") + Text("yet").font(.instrumentSerif(22, italic: true)).foregroundColor(.focusAccent),
                            message: "Open or walk away from a blocked app and it'll show up here."
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(historyManager.recentEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                                VStack(spacing: 0) {
                                    RecentActivityRow(
                                        app: event.appTokenData.flatMap { try? JSONDecoder().decode(ApplicationToken.self, from: $0) },
                                        category: event.categoryTokenData.flatMap { try? JSONDecoder().decode(ActivityCategoryToken.self, from: $0) },
                                        action: event.eventType.rawValue,
                                        time: formatTime(event.timestamp),
                                        challengeType: event.challengeType,
                                        duration: event.duration
                                    )

                                    if index < historyManager.recentEvents.prefix(3).count - 1 {
                                        Divider()
                                            .background(Color.focusLine)
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 22)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaPadding(.top)
            .padding(.bottom, 90)
        }
    }

    // MARK: - History Layer

    private var historyLayer: some View {
        HistoryView(onClose: { showingHistoryView = false })
    }

    // MARK: - Strict Mode Protection

    private func handleTurnOffBlocking() {
        // Check if strict mode protection is enabled
        if settings.strictModeEnabled && settings.strictProtectOff {
            // Show challenge gate
            showGate = ChallengeGateData(
                title: "Turning off Screen Fare",
                onPass: {
                    blockingManager.removeBlocking()
                }
            )
        } else {
            // No protection, turn off immediately
            blockingManager.removeBlocking()
        }
    }

    // MARK: - Helpers

    private var challengeTypeName: String {
        switch settings.challengeType {
        case .math: return "Math"
        case .typing: return "Typing"
        case .memory: return "Memory"
        }
    }

    private var challengeTypeIcon: String {
        switch settings.challengeType {
        case .math: return "plus.forwardslash.minus"
        case .typing: return "keyboard"
        case .memory: return "brain.head.profile"
        }
    }

    private var difficultyText: String {
        switch settings.challengeType {
        case .math:
            switch settings.challengeDifficulty {
            case .veryEasy: return "Very Easy"
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            case .veryHard: return "Very Hard"
            }
        case .typing:
            switch settings.typingDifficulty {
            case .shortest: return "Shortest"
            case .short: return "Short"
            case .medium: return "Medium"
            case .long: return "Long"
            case .longest: return "Longest"
            }
        case .memory:
            let gridSize = settings.memoryGridSize
            let tileCount = settings.memoryTilesToMatch
            return "\(gridSize)×\(gridSize) · \(tileCount) tiles"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: currentTime)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

/// Section header with optional action button
struct SectionHeader: View {
    let title: String
    var action: String? = nil

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(.inter(11, weight: .semibold))
                .foregroundColor(.focusMuted)
                .tracking(0.6)
                .textCase(.uppercase)

            Spacer()

            if let action = action {
                Button(action: {}) {
                    Text(action)
                        .font(.inter(12))
                        .foregroundColor(.focusMuted)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 10)
    }
}

/// Stat item for the status card
struct StatPill: View {
    let value: String
    let label: String
    let textColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.instrumentSerif(26))
                .foregroundColor(textColor)
                .monospacedDigit()

            Text(label)
                .font(.inter(11))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Recent activity row
struct RecentActivityRow: View {
    let app: ApplicationToken?
    let category: ActivityCategoryToken?
    let action: String
    let time: String
    let challengeType: String?
    let duration: TimeInterval

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // App or Category icon (34px to match HTML design)
            if let category = category {
                Label(category)
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                    .scaleEffect(1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let app = app {
                Label(app)
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                    .scaleEffect(1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.focusInk.opacity(0.06))
                    .frame(width: 34, height: 34)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Main label: "Fare paid" or "Walked away"
                Text(mainLabel)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(isWalkedAway ? .focusAccent : .focusInk)
                    .lineLimit(1)

                // Subtitle
                Text(subtitle)
                    .font(.inter(12.5))
                    .foregroundColor(.focusMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Time
            Text(time)
                .font(.inter(12))
                .foregroundColor(.focusMuted)
                .monospacedDigit()
        }
        .padding(.vertical, 14)
    }

    private var isWalkedAway: Bool {
        action == "Walked away"
    }

    private var mainLabel: String {
        if action == "Walked away" {
            return "Walked away"
        } else if action == "Challenge started" {
            return "Fare started"
        } else {
            return "Fare paid"
        }
    }

    private var subtitle: String {
        let itemType = category != nil ? "category" : "app"

        if action == "Walked away" {
            return "Closed blocked \(itemType)"
        } else if action == "Challenge started" {
            // Show fare type (e.g., "Math", "Typing", "Memory")
            return challengeType ?? "Fare"
        } else {
            // Format duration for fare paid
            let minutes = Int(duration / 60)
            let durationText: String
            if minutes < 60 {
                durationText = "\(minutes) min"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                if mins == 0 {
                    durationText = "\(hours) hr"
                } else {
                    durationText = "\(hours)h \(mins)m"
                }
            }
            return "Unlocked \(itemType) for \(durationText)"
        }
    }
}

/// Temporary unlock row showing app with countdown timer
struct TemporaryUnlockRow: View {
    let app: ApplicationToken
    let expiryTime: Date
    let currentTime: Date

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // App icon only
            Label(app)
                .labelStyle(.iconOnly)
                .frame(width: 40, height: 40)
                .scaleEffect(1.5)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Countdown text
            Text(formatCountdown(expiryTime: expiryTime, currentTime: currentTime))
                .font(.inter(15, weight: .medium))
                .foregroundColor(.focusInk)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Remaining time
            Text(formatRemainingTime(expiryTime: expiryTime, currentTime: currentTime))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.focusAccent)
        }
        .padding(.vertical, 14)
    }

    private func formatCountdown(expiryTime: Date, currentTime: Date) -> String {
        let remaining = max(0, expiryTime.timeIntervalSince(currentTime))
        if remaining < 60 {
            return "Expires in less than 1 min"
        } else {
            let minutes = Int(remaining / 60)
            return "Expires in \(minutes) min"
        }
    }

    private func formatRemainingTime(expiryTime: Date, currentTime: Date) -> String {
        let remaining = max(0, expiryTime.timeIntervalSince(currentTime))
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Unlocked Now Section - displays live session timers
/// Design specs: unlocked.jsx → UnlockedNow (lines 140-161)
struct UnlockedNowSection: View {
    let temporaryUnlocks: [Data: Date]
    let temporaryCategoryUnlocks: [Data: Date]
    let currentTime: Date
    let onLock: (Data) -> Void

    private var sortedUnlocks: [(key: Data, value: Date)] {
        temporaryUnlocks
            .filter { $0.value > currentTime } // Only show non-expired unlocks
            .sorted(by: { $0.value < $1.value })
    }

    private var sortedCategoryUnlocks: [(key: Data, value: Date)] {
        temporaryCategoryUnlocks
            .filter { $0.value > currentTime } // Only show non-expired unlocks
            .sorted(by: { $0.value < $1.value })
    }

    private var totalCount: Int {
        sortedUnlocks.count + sortedCategoryUnlocks.count
    }

    private var hasWarning: Bool {
        let appWarning = sortedUnlocks.contains { unlock in
            let remaining = max(0, unlock.value.timeIntervalSince(currentTime))
            return remaining <= 60
        }
        let categoryWarning = sortedCategoryUnlocks.contains { unlock in
            let remaining = max(0, unlock.value.timeIntervalSince(currentTime))
            return remaining <= 60
        }
        return appWarning || categoryWarning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with live dot
            HStack(spacing: 8) {
                // Live pulsing dot
                ZStack {
                    Circle()
                        .fill(hasWarning ? Color.focusWarn : Color.focusAccent)
                        .frame(width: 7, height: 7)

                    Circle()
                        .stroke(hasWarning ? Color.focusWarn : Color.focusAccent, lineWidth: 1.5)
                        .frame(width: 15, height: 15)
                        .opacity(0.7)
                        .scaleEffect(1.0)
                        .modifier(PulseAnimation())
                }

                Text("Unlocked now")
                    .font(.inter(11, weight: .semibold))
                    .foregroundColor(.focusMuted)
                    .tracking(0.6)
                    .textCase(.uppercase)

                Spacer()

                Text("\(totalCount) \(totalCount == 1 ? "item" : "items")")
                    .font(.inter(11.5))
                    .foregroundColor(.focusMuted)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 11)

            // Unlocked session cards
            VStack(spacing: 10) {
                // Display unlocked apps
                ForEach(sortedUnlocks, id: \.key) { unlock in
                    if let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: unlock.key) {
                        let duration = AppBlockingManager.shared.unlockDurations[unlock.key] ?? 300
                        UnlockedSessionCard(
                            unlockType: .app(appToken),
                            expiryTime: unlock.value,
                            totalDuration: duration,
                            currentTime: currentTime,
                            onLock: { onLock(unlock.key) }
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                }

                // Display unlocked categories
                ForEach(sortedCategoryUnlocks, id: \.key) { unlock in
                    if let categoryToken = try? JSONDecoder().decode(ActivityCategoryToken.self, from: unlock.key) {
                        let duration = AppBlockingManager.shared.unlockDurations[unlock.key] ?? 300
                        UnlockedSessionCard(
                            unlockType: .category(categoryToken),
                            expiryTime: unlock.value,
                            totalDuration: duration,
                            currentTime: currentTime,
                            onLock: {
                                AppBlockingManager.shared.relockCategory(categoryData: unlock.key)
                            }
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
    }
}

/// Individual unlocked session card - handles both apps and categories
/// Design specs: unlocked.jsx → UnlockedSession (lines 91-137)
struct UnlockedSessionCard: View {
    enum UnlockType {
        case app(ApplicationToken)
        case category(ActivityCategoryToken)
    }

    let unlockType: UnlockType
    let expiryTime: Date
    let totalDuration: TimeInterval
    let currentTime: Date
    let onLock: () -> Void

    @State private var isDismissing = false

    private var remainingSeconds: Int {
        max(0, Int(expiryTime.timeIntervalSince(currentTime)))
    }

    private var isWarning: Bool {
        remainingSeconds <= 60
    }

    private var progress: Double {
        let total = totalDuration
        let remaining = expiryTime.timeIntervalSince(currentTime)
        return max(0, min(1, remaining / total))
    }

    private var isApp: Bool {
        if case .app = unlockType { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // App/Category info row
            HStack(spacing: 14) {
                // Icon - works for both apps and categories
                Group {
                    switch unlockType {
                    case .app(let token):
                        Label(token)
                            .labelStyle(.iconOnly)
                    case .category(let token):
                        Label(token)
                            .labelStyle(.iconOnly)
                    }
                }
                .scaleEffect(1.6)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isWarning ? "Locking soon" : "Open now")
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(isWarning ? .focusWarn : .focusInk)
                        .lineLimit(1)

                    Text(isApp ? "App" : "Category")
                        .font(.inter(12.5, weight: isWarning ? .medium : .regular))
                        .foregroundColor(isWarning ? Color.focusWarn : Color.focusMuted)
                }

                Spacer(minLength: 0)

                // Lock now button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.35)) {
                        isDismissing = true
                    }

                    // Call the actual lock action after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onLock()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Lock now")
                            .font(.inter(12.5, weight: .semibold))
                    }
                    .foregroundColor(isWarning ? .white : .focusInk)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(isWarning ? Color.focusInk : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isWarning ? Color.clear : Color.focusLine, lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .disabled(isDismissing)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Timer and window info
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // Time remaining in serif
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(formatTimeRemaining())
                        .font(.instrumentSerif(31))
                        .foregroundColor(isWarning ? Color.focusWarn : Color.focusInk)
                        .monospacedDigit()
                        .modifier(isWarning ? AnyViewModifier(WarningPulseModifier()) : AnyViewModifier(EmptyModifier()))

                    Text(" left")
                        .font(.instrumentSerif(15, italic: true))
                        .foregroundColor(isWarning ? Color.focusWarn : Color.focusMuted)
                        .padding(.leading, 7)
                }

                Spacer()

                // Window duration
                Text("\(Int(totalDuration / 60)) min window")
                    .font(.inter(10.5))
                    .foregroundColor(.focusMuted)
                    .tracking(0.9)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.focusInk.opacity(0.08))
                        .frame(height: 5)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isWarning ? Color.focusWarn : Color.focusInk)
                        .frame(width: max(0, progress * geometry.size.width), height: 5)
                        .animation(.linear(duration: 1), value: progress)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 16)
            .padding(.top, 11)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isWarning ? Color.focusWarn.opacity(0.22) : Color.focusLine, lineWidth: 1)
        )
        .cornerRadius(18)
        .opacity(isDismissing ? 0 : 1)
        .scaleEffect(isDismissing ? 0.85 : 1)
    }

    private func formatTimeRemaining() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Pulse animation for live dot
struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.6 : 0.55)
            .opacity(isAnimating ? 0 : 0.7)
            .onAppear {
                withAnimation(.easeOut(duration: 1.9).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// Warning pulse for timer
struct WarningPulseModifier: ViewModifier {
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    opacity = 0.5
                }
            }
    }
}

// Helper to wrap modifiers
struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView

    init<M: ViewModifier>(_ modifier: M) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }

    func body(content: Content) -> some View {
        _body(content)
    }
}

struct EmptyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

/// Custom toggle with configurable colors for the Today screen
struct CustomToggleWithColors: View {
    @Binding var isOn: Bool
    let onToggle: (Bool) -> Void
    let trackColorOn: Color
    let trackColorOff: Color
    var thumbColor: Color = .white

    init(isOn: Binding<Bool>, onToggle: @escaping (Bool) -> Void, trackColorOn: Color, trackColorOff: Color, thumbColor: Color = .white) {
        self._isOn = isOn
        self.onToggle = onToggle
        self.trackColorOn = trackColorOn
        self.trackColorOff = trackColorOff
        self.thumbColor = thumbColor
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: 13)
                .fill(isOn ? trackColorOn : trackColorOff)
                .frame(width: 44, height: 26)

            // Thumb
            Circle()
                .fill(thumbColor)
                .frame(width: 22, height: 22)
                .shadow(color: Color.black.opacity(0.18), radius: 1.5, y: 1)
                .offset(x: isOn ? 20 : 2)
                .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.2), value: isOn)
        }
        .frame(width: 44, height: 26)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isOn)
        }
    }
}

/// Flow layout for wrapping app chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    TodayView()
}
