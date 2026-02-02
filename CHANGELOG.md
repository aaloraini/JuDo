# Changelog

All notable changes to JuDo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-02

### Added
- Comprehensive project documentation
- WidgetKit integration with medium and large widget support
- App Group data synchronization between main app and widget
- Custom URL scheme (`judo://add`) for widget-to-app communication
- Keyboard shortcut support (`Cmd+N`) for quick task creation
- Hide/show completed tasks functionality
- Drag and drop task reordering
- Native macOS design with SwiftUI
- Task completion toggling from within widgets
- Timeline reload requests for widget updates

### Changed
- Complete rewrite using SwiftUI for modern macOS integration
- Migrated to App Group UserDefaults for data sharing
- Enhanced task data model with UUID identifiers and ordering
- Improved widget refresh mechanism using WidgetCenter

### Security
- App Group entitlements properly configured for data sharing
- No external network dependencies or API calls

### Technical
- Minimum macOS version: 13.0 (Ventura)
- Minimum Xcode version: 14.0
- Swift 5.0+ compatibility
- Widget timeline management with system-scheduled refreshes

## [Unreleased]

### TODO
- Previous version history (pre-2.0.0)
- Migration notes from earlier versions
