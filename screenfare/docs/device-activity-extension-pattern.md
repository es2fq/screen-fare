# DeviceActivity Extension Embedding Pattern

## Overview

DeviceActivity extensions run in a separate sandboxed process to access ScreenTime data. We embed these extensions directly in our SwiftUI views to display real-time usage statistics.

**Key Benefits:**
- Privacy-preserving access to ScreenTime data
- Real-time, accurate app usage information
- Native iOS integration

## Extension Setup

### 1. Register a Report Scene

In `DeviceActivityReportExtension.swift`:

```swift
@main
struct ScreenFareReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TodayStatsReport { config in
            TodayStatsView(config: config)
        }
    }
}
```

### 2. Define Context & Scene

In your report file (e.g., `TotalActivityReport.swift`):

```swift
// 1. Extend Context
extension DeviceActivityReport.Context {
    static let todayBlockedAppsUsageTime = Self("Today Blocked Apps Usage Time")
}

// 2. Create Report Scene
struct TodayStatsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .todayBlockedAppsUsageTime
    let content: (TodayStatsConfig) -> TodayStatsView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TodayStatsConfig {
        // Process data and return config
    }
}

// 3. Define Config
struct TodayStatsConfig: Sendable {
    let blockedMinutes: Int
}
```

### 3. Configure Filter

**⚠️ Critical:** Use `.hourly` segments for per-app data access:

```swift
let filter = DeviceActivityFilter(
    segment: .hourly(during: interval),  // ← Enables per-app breakdown
    users: .all,
    devices: .init([.iPhone, .iPad])
)
```

**Why this matters:**
- `.hourly` segments: Full per-app data ✅
- `.daily` segments: Aggregated only, no per-app data ❌

## Accessing App Data

### App Properties

```swift
for await app in category.applications {
    // App token (for matching/filtering)
    let token: ApplicationToken? = app.application.token

    // App name (fallback)
    let name: String? = app.application.localizedDisplayName

    // Usage time
    let duration: TimeInterval = app.totalActivityDuration

    // Opens/pickups
    let pickups: Int = app.numberOfPickups
}
```

### Displaying App Icon & Name

Use FamilyControls `Label` for app icons:

```swift
import FamilyControls

// With token (shows real icon)
if let token = app.token {
    Label(token)
        .labelStyle(.iconOnly)
        .frame(width: 48, height: 48)
        .scaleEffect(1.5)
}

// With token (icon + name)
Label(token)
    .font(.system(size: 14))
```

### Token Matching for Filtering

```swift
// Load user's blocked apps
let selectedAppTokens = Set<ApplicationToken>()
// ... load from UserDefaults

// Check if app is blocked
for await app in category.applications {
    let appToken = app.application.token
    let isBlocked = appToken != nil && selectedAppTokens.contains(appToken!)

    if isBlocked {
        blockedSeconds += app.totalActivityDuration
    }
}
```

## UI Integration

### Embedding in SwiftUI

```swift
DeviceActivityReport(
    DeviceActivityReport.Context("Today Blocked Apps Usage Time"),
    filter: todayStatsFilter
)
```

The extension's view renders **inline** where you place the DeviceActivityReport.

### Transparent Overlay Pattern

Use `ZStack` with transparent overlay for tap handling:

```swift
ZStack {
    VStack(alignment: .leading, spacing: 4) {
        DeviceActivityReport(
            DeviceActivityReport.Context("Today Blocked Apps Usage Time"),
            filter: todayStatsFilter
        )

        Text("Label")
            .font(.inter(11))
    }

    // Transparent overlay allows taps to pass through
    Color.white.opacity(0.001)
        .contentShape(Rectangle())
}
```

**Why?**
- DeviceActivityReport can block tap gestures
- Transparent overlay captures all taps
- User interactions work normally

### Layout Control

```swift
DeviceActivityReport(...)
    .frame(width: 0, height: 0)  // ❌ Won't trigger calculation
    .frame(minHeight: 100)       // ✅ Renders and calculates
    .allowsHitTesting(false)     // Disable interaction if needed
```

## Examples in Our App

### 1. TodayBlockedAppsUsageTime (Minimal)

**Location:** `TodayView.swift:228-244`

**Purpose:** Display just the blocked time number

**Pattern:**
- Simple Text view in extension
- Embedded in StatPill
- ZStack with transparent overlay

```swift
// Extension view
Text(formatMinutes(config.blockedMinutes))
    .font(.custom("InstrumentSerif-Regular", size: 26))
    .monospacedDigit()
```

### 2. ScreenTimeWidget (Compact)

**Location:** `ScreenTimeWidget.swift:18-22`

**Purpose:** Week chart + total time

**Pattern:**
- Embedded report with fixed height
- Transparent overlay for tap handling
- Opens Insights on tap

```swift
DeviceActivityReport(
    DeviceActivityReport.Context("Compact Activity"),
    filter: activityFilter
)
.allowsHitTesting(false)
.frame(minHeight: 100, maxHeight: 100)
```

### 3. InsightsView (Full Report)

**Location:** `InsightsView.swift:71-77`

**Purpose:** Detailed activity breakdown

**Pattern:**
- Large scrollable report (height: 1200)
- Transparent overlay for scroll handling
- Rich data visualization

```swift
DeviceActivityReport(
    DeviceActivityReport.Context("Total Activity"),
    filter: totalActivityFilter
)
.frame(height: 1200)
.allowsHitTesting(false)
```

## Best Practices

1. **Use descriptive context names**: "Today Blocked Apps Usage Time" not "Stats"
2. **Choose correct segment type**: Hourly for per-app data, daily for aggregates
3. **Always use transparent overlay**: Prevents tap blocking issues
4. **Make views Sendable**: Extension runs in separate process
5. **Store minimal data**: Don't cache in UserDefaults if embedding directly
6. **Print debug logs**: Extension logs help debug data flow

## Common Issues

**Problem:** Report shows 0 or no data
- **Fix:** Use `.hourly` segments, not `.daily`

**Problem:** Taps don't work
- **Fix:** Add transparent overlay with `.contentShape(Rectangle())`

**Problem:** Report doesn't render
- **Fix:** Give it a real frame size, not 0x0

**Problem:** Can't access app names/icons
- **Fix:** Use `Label(token)` from FamilyControls, not custom UI
