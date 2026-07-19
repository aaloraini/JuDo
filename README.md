# JuDo

A minimal and elegant task management app for macOS and iOS with WidgetKit integration and iCloud sync.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue?style=flat-square)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue?style=flat-square)
![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

**Mac App Store**: [JuDo: ToDo Widget](https://apps.apple.com/my/app/judo-todo-widget/id6758580110?mt=12)

## Features

- **Simple Task Management**: Add, complete, and delete tasks with a clean interface
- **Subtasks**: Break any task into subtasks with a progress counter; completing the last subtask completes the parent
- **iCloud Sync**: Tasks sync automatically between macOS and iOS via CloudKit, with a sync status button so you can always confirm your tasks are backed up
- **Sync Control**: Toggle iCloud sync on or off at any time from the sync status sheet
- **Drag & Drop Reordering**: Organize tasks by dragging them to new positions
- **Priority Levels**: Mark tasks as High, Medium, or Low priority
- **Due Dates**: Set due dates with overdue and upcoming indicators
- **Notes**: Add notes to any task for extra context
- **Sort Options**: Sort by manual order, priority, due date, creation date, or last updated
- **Hide Completed Tasks**: Focus on active tasks with a toggle option
- **WidgetKit Integration**: View and manage tasks directly from your macOS desktop or iOS/iPadOS home screen widgets
- **iPad Support**: Full native iPad layout with support for all orientations
- **Keyboard Shortcuts**: Quick task creation with `Cmd+N` on macOS
- **Native Design**: Built with SwiftUI for seamless system integration on both platforms
- **Supporter Leaderboard**: Buy Mon to support development and appear on a shared leaderboard across all platforms

## Quick Start

1. Clone the repository
2. Open `JuDo.xcodeproj` in Xcode
3. Select the `JuDo` scheme for macOS or `JuDoiOS` for iPhone/iPad
4. Build and run

## iCloud Sync

JuDo uses SwiftData with CloudKit to sync tasks across all your devices. Sign in to the same iCloud account on your Mac and iPhone/iPad and changes will sync automatically.

Tap the cloud icon in the toolbar to open the sync status sheet, which shows whether your tasks are synced, unavailable, or turned off. You can disable sync entirely from this sheet — the app will fall back to local-only storage until sync is re-enabled and the app is relaunched.

## Widget Support

JuDo includes a home screen / desktop widget available on macOS, iOS, and iPadOS in two sizes:
- **Medium Widget**: Displays up to 5 tasks
- **Large Widget**: Displays up to 8 tasks

Both widgets support:
- Task completion toggling
- Priority cycling
- Hide/show completed tasks preference

## Supporter Leaderboard

JuDo includes an optional supporter leaderboard powered by CloudKit. Buy Mon (one-time IAP) to support development -- the more you contribute, the higher your rank. Set a custom display name and see where you stand across all platforms in real time.

## Requirements

- macOS 15.0+ (Sequoia)
- iOS/iPadOS 17.0+
- Xcode 16.0+
- Swift 5.0+
- iCloud account (for sync)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created by Abdulhakim Aloraini - [@aaloraini](https://github.com/aaloraini)
