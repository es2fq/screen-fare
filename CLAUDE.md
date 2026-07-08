## Build Command

```bash
cd /Users/esong/coding/screen-fare/screenfare
xcodebuild -scheme screenfare -sdk iphonesimulator -destination 'platform=iOS Simulator,id=A80CBD32-6EC3-4C11-8D82-7430B8EFA998' clean build
```

## After Making Changes

⚠️ **Always rebuild after modifying code** - especially if you changed:
- `ShieldActionExtension` (handles shield button clicks)
- `ShieldConfigurationExtension` (shield appearance)
- Any extension code

The extensions won't pick up changes until you rebuild the entire app.

---

## Architecture & Best Practices

### Code Organization
- **Shared code** lives in `ScreenFareShared` Swift Package (used by app + extensions)
- **Managers** use focused single-responsibility pattern (e.g., `TemporaryUnlockManager`, `BlockingPersistenceManager`)
- **Design system** centralized in `/screenfare/DesignSystem/` (Colors, Typography, Components)

### When Making Changes
1. **Keep managers focused** - Each manager should have one clear purpose
2. **Delegate, don't duplicate** - Orchestrate through composition (see `AppBlockingManager`)
3. **Use the shared package** - Add shared models/utilities to `ScreenFareShared`, not duplicated files
4. **Extensions need imports** - Always `import ScreenFareShared` in extension code

### Data Persistence
- **App Group**: Use `UserDefaults.appGroup` for data shared between app and extensions
- **Standard**: Use `UserDefaults.standard` for app-only data

### Design System
- Use `Color.focusBg`, `Color.focusInk`, etc. (never inline colors)
- Use `Font.instrumentSerif()` and `Font.inter()` (centralized typography)
- Components in `AppComponents.swift` and `OnboardingComponents.swift`
