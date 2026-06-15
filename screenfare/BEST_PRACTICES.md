# ScreenFare Code Best Practices

This document outlines coding standards and best practices for the ScreenFare project.

## 🏗️ Architecture

### Shared Code Between App & Extensions

**Use the canonical files in `/screenfare/Shared/`:**
- `ScheduleModels.swift` - Schedule logic, models, and shared utilities
  - Contains `UserDefaults.appGroup` helper
  - Contains date/time formatting extensions
  - Automatically copied to extension targets during build

**Never duplicate code between targets.** If extensions need shared code, add it to `/screenfare/Shared/` and copy to extension folders.

### Manager Classes

All manager classes follow the singleton pattern:
```swift
class SomeManager: ObservableObject {
    static let shared = SomeManager()
    private init() { ... }
}
```

**Location**: `/screenfare/Managers/`

**Key Managers**:
- `SettingsManager` - User preferences and settings
- `ScheduleManager` - Blocking schedule logic
- `AppBlockingManager` - Shield application and monitor management
- `StatsManager` - Daily statistics tracking
- `HistoryManager` - Recent activity events

## 🎨 Design System

### Use the Unified Design System

**All views should use:**
- `/screenfare/Features/Onboarding/DesignSystem.swift`

**Color palette** (use these constants):
```swift
Color.focusBg        // Background
Color.focusInk       // Primary text
Color.focusMuted     // Secondary text
Color.focusLine      // Borders
Color.focusCard      // Card backgrounds
Color.focusAccent    // Sage green accent
Color.focusWarn      // Warning/error states

// Challenge-specific
Color.transitGreen   // Success states
Color.transitRed     // Error states
Color.transitRedSoft // Error backgrounds
```

**Typography**:
```swift
.font(.instrumentSerif(36))        // Display text
.font(.instrumentSerif(22, italic: true))  // Italic display
.font(.inter(14, weight: .medium)) // UI text
```

**Never define colors inline.** Always use the design system constants.

## 💾 Data Persistence

### UserDefaults

**Always use the app group helper:**
```swift
// ✅ Correct
UserDefaults.appGroup?.set(value, forKey: "key")

// ❌ Wrong - hardcoded suite name
UserDefaults(suiteName: "group.esong.screenfare.shared")
```

**Never call `.synchronize()`** - it's deprecated and automatic on modern iOS.

**Use standard UserDefaults for app-only data:**
```swift
UserDefaults.standard.set(value, forKey: "app.only.setting")
```

**Use app group for shared data (app + extensions):**
```swift
UserDefaults.appGroup?.set(value, forKey: "shared.setting")
```

## 🕐 Date & Time Formatting

### Use Shared Extensions

**Defined in** `ScheduleModels.swift`:

```swift
// Get today's date string
let today = Date.todayDateString()  // "2026-06-15"

// Format time intervals
let duration: TimeInterval = 1800
duration.formatted()           // "30 min"
duration.formattedTimeSpent()  // "30m"
```

**Never create your own date formatters** - use the shared utilities.

### Time Formatting in ScheduleManager

**For schedule display:**
```swift
ScheduleManager.minToLabel(540)    // "9:00 AM"
ScheduleManager.minToCompact(540)  // "9a"
ScheduleManager.formatDays([1,2,3,4,5])  // "Weekdays"
```

## 📂 File Organization

```
screenfare/
├── Features/           # Feature-based UI components
│   ├── Onboarding/    # Onboarding flow + DesignSystem.swift
│   ├── Challenge/     # Challenge UI and logic
│   ├── MainApp/       # Main app screens (Today, Blocks, Settings)
│   └── Settings/      # Settings detail views
├── Managers/          # Singleton business logic classes
├── Models/            # Data models (Challenges, etc.)
├── Shared/            # Code shared with extensions
│   └── ScheduleModels.swift  # THE source of truth
└── Components/        # Reusable UI components

Extensions/ (separate targets)
├── ShieldActionExtension/
├── ShieldConfigurationExtension/
└── DeviceMonitorActivityExtension/
```

## 🔧 Common Patterns

### Published Properties with Persistence

```swift
@Published var setting: Type {
    didSet {
        UserDefaults.standard.set(setting, forKey: "setting")
        // For extension-shared settings:
        UserDefaults.appGroup?.set(setting, forKey: "setting")
    }
}
```

### Loading Persisted Data

```swift
private init() {
    // Load with fallback to default
    self.setting = UserDefaults.standard.string(forKey: "setting") ?? "default"
}
```

### ObservableObject in Views

```swift
struct SomeView: View {
    @StateObject private var manager = SomeManager.shared
    // Use @StateObject for manager instances
    // Use @ObservedObject when passed from parent
}
```

## 🚫 Anti-Patterns (Don't Do This)

### ❌ Hardcoded App Group Names
```swift
// Wrong
UserDefaults(suiteName: "group.esong.screenfare.shared")

// Right
UserDefaults.appGroup
```

### ❌ Duplicate Code Between Targets
```swift
// Wrong - copying ScheduleModels.swift manually
// Right - use /screenfare/Shared/ as canonical source
```

### ❌ Manual Synchronization
```swift
// Wrong
UserDefaults.appGroup?.synchronize()

// Right - just remove it, happens automatically
UserDefaults.appGroup?.set(value, forKey: "key")
```

### ❌ Inline Colors
```swift
// Wrong
.foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

// Right
.foregroundColor(.focusInk)
```

### ❌ Duplicate Date Formatters
```swift
// Wrong
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"
return formatter.string(from: Date())

// Right
Date.todayDateString()
```

## 🔄 When Adding New Features

1. **Check if shared code exists** - don't reinvent wheels
2. **Use the design system** - maintain visual consistency
3. **Follow the manager pattern** - for business logic
4. **Add to Shared/** - if extensions need access
5. **Update this doc** - if you create new patterns

## 📝 Code Review Checklist

Before committing:
- [ ] No hardcoded app group suite names
- [ ] No `.synchronize()` calls
- [ ] No duplicate date/time formatters
- [ ] Design system colors used (no inline colors)
- [ ] Shared utilities used where applicable
- [ ] No code duplication between app and extensions
- [ ] Build succeeds for all targets

---

**Last Updated**: June 2026
**Maintained By**: Development Team
