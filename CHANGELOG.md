# Changelog

All notable changes to JuDo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.3] - 2026-07-19

### Added
- Subtasks: any task can be a parent task with its own list of subtasks
- Create a parent task with subtasks directly from the Add flow, or add subtasks later from the task list or detail view
- Expandable subtask lists in the main list with inline add, reorder, and delete
- Progress counter (e.g. 3/5) on parent task rows in the app and widgets
- Completing a parent completes all its subtasks; completing the last subtask auto-completes the parent, in the app and from widget toggles alike
- Search matches subtask titles, surfacing the parent task
- Edit sheet on macOS to change a task's title, priority, due date, and subtasks
- Delete confirmations warn when a task's subtasks will also be deleted

### Fixed
- Store schema migration now runs reliably before CloudKit opens the store, preventing "no such column" fetch failures after an update
- Widget data container is now truly local-only; it previously enabled CloudKit silently via the widget's entitlements

### Technical
- New `Task.parentId` field (one level of hierarchy, synced via CloudKit)
- New `Shared/TaskCompletion.swift` holds master/subtask completion semantics shared by the app and widget AppIntents
- CloudKit schema must be deployed to Production before this build ships to the App Store

## [2.2.2] - 2026-07-11

### Fixed
- Mon purchases are no longer lost if saving to the leaderboard fails: the transaction now stays pending and is retried automatically the next time the Support page opens
- Purchases completing in the background (interrupted purchases, Ask to Buy approvals) now credit Mon correctly instead of being silently discarded
- Purchase errors are now shown on the Support page instead of failing silently
- Joining the leaderboard no longer fails when the iCloud account info hasn't loaded yet

## [2.2.1] - 2026-06-25

### Fixed
- iCloud sync no longer reverts recent changes when CloudKit pushes arrive
- Sync recovers gracefully from an incompatible local store by auto-resetting it
- iOS sync fixed with push notification entitlement and improved CloudKit error logging
- Live sync status monitoring with better error handling; iOS data migration added

### Changed
- Sync optimized: single save per mutation, smarter reordering, foreground status refresh

## [2.2.0] - 2026-06-16

### Added
- iCloud sync status button (cloud icon in toolbar) showing live sync state on macOS and iOS
- Toggle to disable/enable iCloud sync at any time; app falls back to local-only storage until relaunch
- iOS and iPadOS home screen widget (medium and large sizes) with task completion and priority cycling
- Full iPad support with all orientations
- Supporter leaderboard: buy Mon (one-time IAP) to appear on a shared leaderboard with rank tiers

### Changed
- Migrated task storage from App Group UserDefaults to SwiftData with CloudKit private database
- Widget extension is now multiplatform — runs on macOS, iOS, and iPadOS
- Support page redesigned with Mon coin icons and rank display

### Technical
- `ModelContainerFactory` checks `iCloudSyncEnabled` flag at launch to decide CloudKit vs local store
- `JuDoWidgetExtension` target builds for `iphoneos`, `iphonesimulator`, and `macosx`
- `JuDoWidgetControl` (macOS Control Center widget) guarded with `#if os(macOS)` for iOS builds
- Minimum iOS/iPadOS: 17.0

## [2.1.4] - 2026-02-17

### Added
- Priority levels: High, Medium, and Low with visual indicators
- Due dates with overdue and upcoming deadline indicators
- Notes field for adding context to any task
- Sort options: manual order, priority, due date, creation date, or last updated
- Search across task titles and notes

### Changed
- UI polished and production-ready for App Store submission
- Error handling improved across all task operations

### Technical
- Minimum macOS: 15.0 (Sequoia)
- Minimum Xcode: 16.0
- Swift 5.0+

## [2.0.0] - 2026-02-02

### Added
- Task management: add, complete, reorder, and delete tasks
- WidgetKit integration with medium (5 tasks) and large (8 tasks) widget sizes
- Task completion toggling directly from the widget
- Drag and drop reordering
- Hide/show completed tasks toggle
- Keyboard shortcut `Cmd+N` to quickly add a task
- App Group data sharing between the main app and widget
- URL scheme `judo://add` for widget-to-app task creation
- Native macOS design built entirely with SwiftUI
