# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This is a native Xcode project (no SPM dependencies, no CocoaPods). You may need to set `DEVELOPER_DIR` in this shell:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Build macOS app:
```bash
xcodebuild -scheme JuDo -destination 'platform=macOS' build
```

Build iOS app (pick a simulator name from `xcodebuild -scheme JuDoiOS -showdestinations`):
```bash
xcodebuild -scheme JuDoiOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Run tests:
```bash
xcodebuild -scheme JuDo test -destination 'platform=macOS'
```

There is no linter configured for this project. SourceKit/LSP diagnostics in this environment are often stale or incorrect; always verify with `xcodebuild` for real build results.

## Architecture

### Targets

| Target | Platform | Entry point | Description |
|--------|----------|-------------|-------------|
| `JuDo` | macOS 15.0+ | `JuDo/JuDoApp.swift` | macOS app |
| `JuDoiOS` | iOS/iPadOS 17.0+ | `iOS/JuDoiOSApp.swift` | iOS/iPad app |
| `JuDoWidgetExtension` | macOS + iOS | `JuDoWidget/JuDoWidgetBundle.swift` | WidgetKit extension (multiplatform) |
| `JuDoTests` | macOS | `JuDoTests/` | Unit tests |
| `JuDoUITests` | macOS | `JuDoUITests/` | UI tests |

Only the `JuDo` scheme is shared (`.xcscheme` file exists). The `JuDoiOS` scheme is user-local.

### Directory layout

- **`Shared/`** - Code used by both macOS and iOS targets: data model (`Task.swift`), `TaskManager`, `TaskCompletion`, `ModelContainerFactory`, `SyncManager`, `StoreManager`, `LeaderboardManager`, `SupportView`, `SyncStatusView`, enums (`Priority`, `TaskSortOption`, `MonTier`)
- **`JuDo/`** - macOS-only: `ContentView.swift` (main UI), `DataMigration.swift`, `ErrorHandling.swift`
- **`iOS/`** - iOS-only: `TaskListView.swift`, `AddTaskView.swift`, `TaskDetailView.swift`, `TaskRowView.swift`
- **`JuDoWidget/`** - Widget extension: timeline provider, widget views, `AppIntent` actions

### Data flow

`Task` is a `@Model` (SwiftData). `ModelContainerFactory.make()` creates the container at app launch, choosing between CloudKit-backed or local-only based on the `iCloudSyncEnabled` UserDefaults flag. The container is injected into `TaskManager` (an `ObservableObject` that owns a `ModelContext` and publishes task arrays). Both platform entry points (`JuDoApp`, `JuDoiOSApp`) create the container and pass it down.

The widget uses `ModelContainerFactory.makeWidget()` which is always local-only (no CloudKit overhead). It reads/writes the same SQLite file in the App Group container.

Tasks support one level of hierarchy via `Task.parentId` (a plain `UUID?`, not a SwiftData relationship, for CloudKit compatibility). `TaskManager.topLevelTasks` is orphan-tolerant: a child whose parent record hasn't synced yet shows as top-level until the parent arrives. `TaskCompletion` (in `Shared/`) holds the master/subtask completion semantics (toggling a master drives its children; completing the last child auto-completes the master) and is used by both `TaskManager` and the widget's `ToggleTaskIntent` so all entry points behave identically.

### CloudKit / iCloud sync

- CloudKit container: `iCloud.com.aloraini.JuDo` (private database for tasks, public database for leaderboard)
- App Group: `group.com.aloraini.JuDo` (shared UserDefaults + SQLite store between app and widget)
- Sync toggle stored in: `UserDefaults(suiteName: "group.com.aloraini.JuDo")["iCloudSyncEnabled"]`
- `SyncManager` checks `CKContainer.accountStatus()` for UI display only
- `TaskManager` observes `.NSPersistentStoreRemoteChange` to reload tasks when CloudKit pushes arrive
- Schema changes must be deployed from Development to Production in the [CloudKit Dashboard](https://icloud.developer.apple.com) before App Store builds can sync

### In-App Purchase / Leaderboard

`StoreManager` handles StoreKit 2 purchases of "Mon" consumable tiers (defined in `MonTier`). `LeaderboardManager` reads/writes `Supporter` records in CloudKit's **public** database. `BadWordFilter` validates display names. `SupportView` is the cross-platform UI for both.

### Cross-platform patterns

Platform-specific code uses `#if os(macOS)` / `#else` blocks within shared files (see `SyncStatusView`, `SupportView`). `JuDoWidgetControl.swift` (macOS Control Center widget) is entirely wrapped in `#if os(macOS)` because `ControlWidget` APIs are unavailable on iOS with the current deployment target.

### Swift concurrency note

`StoreManager` uses `_Concurrency.Task` (fully qualified) to avoid collision with the SwiftData `Task` model class. This disambiguation is required anywhere both `Swift.Task` and the app's `Task` model are in scope.
