# JuDo

A minimal and elegant task management app for macOS with WidgetKit integration.

![JuDo App](https://img.shields.io/badge/macOS-compatible-blue?style=flat-square)
![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## Features

- **Simple Task Management**: Add, complete, and delete tasks with a clean interface
- **Drag & Drop Reordering**: Organize tasks by dragging them to new positions
- **Hide Completed Tasks**: Focus on active tasks with a toggle option
- **WidgetKit Integration**: View and manage tasks directly from your desktop widgets
- **Keyboard Shortcuts**: Quick task creation with `Cmd+N`
- **Native macOS Design**: Built with SwiftUI for seamless system integration
- **App Group Sync**: Shared data between main app and widget extensions

## Quick Start

1. Clone the repository
2. Open `JuDo.xcodeproj` in Xcode
3. Build and run the app

## Widget Support

JuDo includes two widget sizes:
- **Medium Widget**: Displays up to 5 tasks
- **Large Widget**: Displays up to 8 tasks

Both widgets support:
- Task completion toggling
- Quick task addition via URL scheme
- Hide/show completed tasks preference

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 14.0+
- Swift 5.0+

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Building from Source](docs/BUILDING.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Widget Integration](docs/WIDGET.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created by Abdulhakim Aloraini - [@aaloraini](https://github.com/aaloraini)
