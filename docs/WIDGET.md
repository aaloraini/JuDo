# Widget Integration Guide

This document provides comprehensive information about JuDo's WidgetKit integration, including implementation details, user features, and technical considerations.

## Overview

JuDo includes a WidgetKit extension that allows users to view and manage tasks directly from their macOS desktop widgets. The widget supports both medium and large sizes with interactive functionality.

## Widget Configuration

### Widget Metadata

- **Widget Kind**: `"JuDoWidget"`
- **Bundle Name**: `JuDoWidget`
- **Supported Families**: `.systemMedium`, `.systemLarge`
- **Configuration**: Static configuration with timeline provider

### Bundle Structure

```
JuDoWidget/
├── JuDoWidget.swift           # Main widget implementation
├── JuDoWidgetControl.swift    # Control Center widget (template)
├── JuDoWidgetBundle.swift     # Widget bundle configuration
├── Task.swift                 # Shared Task data model
├── Info.plist                 # Widget extension configuration
└── Assets.xcassets/          # Widget assets
```

## Widget Families

### Medium Widget

- **Dimensions**: Variable width, fixed height
- **Task Limit**: Up to 5 tasks displayed
- **Features**: Task completion toggle, quick add button
- **Layout**: Compact header with scrollable task list

### Large Widget

- **Dimensions**: Variable width and height
- **Task Limit**: Up to 8 tasks displayed
- **Features**: Task completion toggle, quick add button
- **Layout**: Expanded header with larger task list

## Data Integration

### App Group Sharing

The widget shares data with the main app through App Group UserDefaults:

```swift
// App Group identifier
let appGroup = "group.com.aloraini.JuDo"

// Shared storage keys
let tasksKey = "tasks"
let hideCompletedKey = "hideCompleted"
```

### Data Loading

```swift
private func loadTasks() -> [Task] {
    guard let data = UserDefaults(suiteName: "group.com.aloraini.JuDo")?.data(forKey: "tasks"),
          let tasks = try? JSONDecoder().decode([Task].self, from: data) else {
        return []
    }
    return tasks.sorted { $0.order < $1.order }
}
```

## Timeline Management

### Timeline Provider

The widget uses a timeline provider to schedule updates:

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let tasks = loadTasks()
    let entry = SimpleEntry(date: Date(), tasks: tasks)
    
    // Request next update in 15 minutes (system controls actual timing)
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
}
```

### Timeline Reload Requests

The main app requests immediate widget updates after data changes:

```swift
private func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
}
```

**Important**: WidgetKit controls the actual timing of widget updates. The app requests reloads, but the system determines when widgets are actually refreshed.

## Interactive Features

### Task Completion Toggle

Users can toggle task completion directly from the widget:

```swift
struct TaskWidgetRow: View {
    let task: Task
    @AppStorage("tasks", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) 
    private var tasksData: Data = Data()
    
    private func toggleTaskCompletion(_ task: Task) {
        guard var tasks = try? JSONDecoder().decode([Task].self, from: tasksData),
              let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].isCompleted.toggle()
        
        if let data = try? JSONEncoder().encode(tasks) {
            tasksData = data
            WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
        }
    }
}
```

### Quick Add Functionality

The widget includes a quick add button that opens the main app:

```swift
Link(destination: URL(string: "judo://add")!) {
    Image(systemName: "plus")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.secondary)
        .frame(width: 24, height: 24)
        .background(
            Circle()
                .fill(Color.secondary.opacity(0.1))
        )
}
```

### URL Scheme Handling

The main app handles the custom URL scheme:

```swift
private func handleURL(_ url: URL) {
    if url.scheme == "judo" && url.host == "add" {
        NotificationCenter.default.post(name: .addTaskFromWidget, object: nil)
    }
}
```

## Widget UI Implementation

### View Architecture

The widget uses a family-specific view architecture:

```swift
struct JuDoWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            JuDoMediumWidgetView(tasks: entry.tasks)
        case .systemLarge:
            JuDoLargeWidgetView(tasks: entry.tasks)
        default:
            JuDoMediumWidgetView(tasks: entry.tasks)
        }
    }
}
```

### Styling and Design

- **Container Background**: `.ultraThinMaterial` (macOS 14+) or `.thinMaterial`
- **Native Styling**: System colors and fonts
- **Visual Hierarchy**: Clear header with task list separation
- **Interactive Elements**: Tappable completion buttons

## Performance Considerations

### Data Efficiency

- **Minimal Timeline Data**: Only essential task information in timeline entries
- **Efficient Decoding**: Single JSON decode operation per timeline update
- **Lazy Loading**: Tasks loaded on-demand from UserDefaults

### Memory Management

- **Lightweight Views**: Simple SwiftUI views with minimal state
- **No Long-Lived Objects**: Views recreated per timeline update
- **Efficient Updates**: Targeted `@AppStorage` property updates

## Testing Widget Functionality

### Manual Testing

1. **Add Widget to Desktop**:
   - Right-click desktop → Edit Widgets
   - Find "JuDo Tasks"
   - Add to desktop

2. **Test Data Sync**:
   - Add tasks in main app
   - Verify widget updates
   - Toggle completion in widget
   - Verify changes in main app

3. **Test Timeline**:
   - Make changes in main app
   - Observe widget update timing
   - Test quick add functionality

### Automated Testing

```swift
// Widget timeline testing
func testWidgetTimelineReload() {
    let taskManager = TaskManager()
    taskManager.addTask(title: "Test Task")
    
    // Verify timeline reload is called
    // This would require mocking WidgetCenter
}
```

## Debugging Widget Issues

### Common Issues

1. **Widget Not Updating**:
   - Check App Group configuration
   - Verify timeline reload requests
   - Review Console.app for widget errors

2. **Data Not Syncing**:
   - Verify App Group UserDefaults access
   - Check JSON encoding/decoding
   - Ensure consistent data model

3. **Widget Not Appearing**:
   - Verify widget extension build
   - Check bundle configuration
   - Restart widget system (restart Mac)

### Debug Tools

- **Console.app**: Filter for "JuDoWidget" messages
- **Xcode Debugger**: Attach to widget extension process
- **UserDefaults Inspection**: Check App Group data directly

## Control Center Widget

### Template Implementation

The project includes a Control Center widget template (`JuDoWidgetControl.swift`):

```swift
struct JuDoWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "hkem.JuDo.JuDoWidget",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value,
                action: StartTimerIntent()
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}
```

**Note**: This is template code and not currently integrated with the main task management functionality.

## Future Widget Enhancements

### Potential Features

1. **Additional Widget Sizes**: Small widget support
2. **Task Reminders**: Time-based task notifications
3. **Task Categories**: Grouped task display
4. **Widget Configuration**: User preferences in widget gallery
5. **Siri Integration**: Voice task management

### Technical Improvements

1. **Background Updates**: Background app refresh for better sync
2. **CloudKit Integration**: Cross-device widget synchronization
3. **Performance Optimization**: Faster timeline updates
4. **Enhanced Interactivity**: More widget-based actions

## Best Practices

### Widget Development

1. **Minimal Timeline Data**: Keep timeline entries lightweight
2. **Efficient Updates**: Request reloads only when necessary
3. **Graceful Degradation**: Handle data loading errors gracefully
4. **Consistent Styling**: Match system design guidelines
5. **Battery Efficiency**: Avoid frequent background updates

### Data Management

1. **Atomic Updates**: Ensure data consistency during updates
2. **Error Handling**: Graceful fallback for corrupted data
3. **Performance**: Optimize JSON encoding/decoding
4. **Security**: Validate data from shared storage

This widget implementation provides a seamless extension of JuDo's task management capabilities to the macOS desktop, enhancing user productivity through convenient at-a-glance access to tasks.
