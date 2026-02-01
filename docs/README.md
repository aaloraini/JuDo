# JuDo - Simple To-Do Widget for macOS

A modern, minimal task management app with a native macOS widget for seamless task tracking from your desktop.

![JuDo App Icon](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgcng9IjIwIiBmaWxsPSIjN2MzYWVkIi8+PGNpcmNsZSBjeD0iMjUiIGN5PSIyNSIgcj0iOCIgZmlsbD0id2hpdGUiLz48Y2lyY2xlIGN4PSIyNSIgY3k9IjUwIiByPSI4IiBmaWxsPSJ3aGl0ZSIvPjxjaXJjbGUgY3g9IjI1IiBjeT0iNzUiIHI9IjgiIGZpbGw9IiM2ZDI4ZDkiLz48cmVjdCB4PSI0MCIgeT0iMjAiIHdpZHRoPSI0MCIgaGVpZ2h0PSI4IiByeD0iNCIgZmlsbD0id2hpdGUiLz48cmVjdCB4PSI0MCIgeT0iNDUiIHdpZHRoPSI0MCIgaGVpZ2h0PSI4IiByeD0iNCIgZmlsbD0id2hpdGUiLz48cmVjdCB4PSI0MCIgeT0iNzAiIHdpZHRoPSI0MCIgaGVpZ2h0PSI4IiByeD0iNCIgZmlsbD0iIzZkMjhkOSIvPjwvc3ZnPg==)

## ✨ Features

- **🖥️ Desktop Widget** - Access tasks directly from macOS Notification Center
- **🔄 Real-time Sync** - Instant updates between app and widget
- **🎯 Drag & Drop** - Easy task organization with reordering
- **👁️ Smart Filtering** - Hide completed tasks to focus on what matters
- **⚡ Quick Actions** - Add, toggle, and manage tasks with minimal clicks
- **🔒 Secure & Private** - All data stored locally using secure App Groups

## 🛠️ Technical Details

Built with modern macOS technologies:

- **SwiftUI** - Modern declarative UI framework
- **WidgetKit** - Native widget integration
- **App Groups** - Secure data sharing between app and widget
- **App Intents** - Interactive widget functionality
- **Actor-based Architecture** - Thread-safe data management

## 📱 System Requirements

- macOS 14.0 or later
- Apple Silicon or Intel Mac

## 🚀 Installation

### Option 1: Download Release
1. Go to the [Releases page](https://github.com/aaloraini/JuDo/releases)
2. Download the latest `.dmg` file
3. Open the file and drag JuDo to your Applications folder
4. Add the widget from Notification Center

### Option 2: Build from Source
```bash
git clone https://github.com/aaloraini/JuDo.git
cd JuDo
open TaskWidgetApp.xcodeproj
# Build and run in Xcode
```

## 📖 Usage

### Adding the Widget
1. Open Notification Center (click the date/time in menu bar)
2. Click "Edit Widgets" at the bottom
3. Find JuDo in the widget list
4. Drag to your preferred size and position

### Managing Tasks
- **Add Tasks**: Use the text field in the main app or the + button in the widget
- **Toggle Completion**: Click the checkbox next to any task
- **Reorder**: Drag tasks in the main app to reorganize
- **Edit**: Double-click any task to edit its title
- **Delete**: Hover over a task and click the trash icon

## 🔧 Development

### Project Structure
```
TaskWidgetApp/
├── TaskWidgetApp/          # Main application
│   ├── ContentView.swift      # Main UI
│   ├── TaskStore.swift        # Data management
│   └── SharedTasks.swift      # Shared data models
├── TaskWidget/             # Widget extension
│   ├── TaskWidget.swift      # Widget implementation
│   └── TaskWidgetBundle.swift
└── TaskWidgetApp.xcodeproj # Xcode project
```

### Key Components

#### DataStore (Actor)
Thread-safe data management using Swift actors:
```swift
actor DataStore {
    func load() -> ([TodoItem], Bool)
    func save(items: [TodoItem], hideCompleted: Bool)
    func addTask(title: String) -> [TodoItem]
    func toggleTask(with id: UUID) -> [TodoItem]
    func reorderTasks(from sourceIndexSet: IndexSet, to destination: Int) -> [TodoItem]
}
```

#### Widget Timeline Provider
Efficient widget updates with smart caching:
```swift
struct Provider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void)
}
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple for SwiftUI and WidgetKit frameworks
- The macOS developer community for inspiration and feedback

## 📞 Support

If you encounter any issues or have suggestions:

1. Check existing [Issues](https://github.com/aaloraini/JuDo/issues)
2. Create a new issue with detailed information
3. Include macOS version and steps to reproduce

---

Made with ❤️ by [Abdulhakim Aloraini](https://github.com/aaloraini)
