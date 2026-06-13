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
