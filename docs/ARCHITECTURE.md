# Architecture Overview

This document describes the technical architecture of JuDo, including data flow, component interactions, and design decisions.

## High-Level Architecture

JuDo follows a modular architecture with clear separation between the main application and widget extension, connected through App Group data sharing.

```
┌─────────────────┐    App Group     ┌─────────────────┐
│   JuDo App      │ ◄──────────────► │  JuDoWidget     │
│                 │   UserDefaults   │                 │
│ • SwiftUI UI    │                  │ • WidgetKit UI  │
│ • TaskManager   │                  │ • Timeline      │
│ • URL Scheme    │                  │ • Interactive   │
└─────────────────┘                  └─────────────────┘
```

## Core Components

### 1. Data Model (`Task.swift`)

```swift
struct Task: Codable, Identifiable {
    let id: UUID          // Unique identifier
    var title: String     // Task content
    var isCompleted: Bool // Completion state
    var order: Int        // Display order
}
```

**Key Design Decisions**:
- **UUID-based identification** prevents conflicts during sync
- **Codable protocol** enables JSON serialization for storage
- **Order field** maintains user-defined task sequence
- **Shared model** duplicated in both targets for independence

### 2. Data Management (`TaskManager.swift`)

```swift
class TaskManager: ObservableObject {
    @AppStorage("tasks", store: UserDefaults(suiteName: "group.com.aloraini.JuDo"))
    private var tasksData: Data = Data()
    @Published var tasks: [Task] = []
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo"))
    var hideCompleted: Bool = false
}
```

**Responsibilities**:
- **CRUD operations** for task management
- **Data persistence** via App Group UserDefaults
- **Widget timeline reloads** after data changes
- **Task filtering** based on completion status
- **Order management** during drag-and-drop operations

### 3. User Interface (`ContentView.swift`)

**Architecture Pattern**: MVVM (Model-View-ViewModel)

```swift
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    // UI components and user interactions
}
```

**Key Features**:
- **SwiftUI-based** declarative UI
- **Reactive updates** through `@Published` properties
- **Sheet-based** task addition interface
- **Native macOS styling** with visual effects
- **Keyboard shortcuts** integration

### 4. Widget Extension (`JuDoWidget.swift`)

**Widget Configuration**:
- **Kind**: `"JuDoWidget"`
- **Supported Families**: `.systemMedium`, `.systemLarge`
- **Timeline Provider**: System-scheduled with reload requests

**Timeline Management**:
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let tasks = loadTasks()
    let entry = SimpleEntry(date: Date(), tasks: tasks)
    
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
}
```

## Data Flow

### 1. Task Creation Flow

```
User Input → ContentView.addTask() → TaskManager.addTask() 
→ UserDefaults Save → Widget Timeline Reload → Widget UI Update
```

### 2. Task Completion Flow (Widget)

```
Widget Tap → TaskWidgetRow.toggleTaskCompletion() 
→ UserDefaults Update → Widget Timeline Reload → Widget UI Update
```

### 3. App ↔ Widget Communication

**Widget → App**:
- **URL Scheme**: `judo://add`
- **Handled by**: `JuDoApp.handleURL()`
- **Triggers**: NotificationCenter broadcast to show add task sheet

**App → Widget**:
- **Shared Storage**: App Group UserDefaults
- **Timeline Reload**: `WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")`
- **System Control**: WidgetKit determines actual refresh timing

## Data Storage Architecture

### App Group UserDefaults

**Configuration**:
- **Group Identifier**: `group.com.aloraini.JuDo`
- **Storage Keys**:
  - `"tasks"`: JSON-encoded `[Task]` array
  - `"hideCompleted"`: Boolean preference

**Data Format**:
```json
{
  "tasks": "[{\"id\":\"...\",\"title\":\"Sample\",\"isCompleted\":false,\"order\":0}]",
  "hideCompleted": false
}
```

### Data Synchronization

**Consistency Mechanisms**:
1. **Single Source of Truth**: App Group UserDefaults
2. **Atomic Updates**: JSON encoding/decoding ensures data integrity
3. **Timeline Reloads**: Immediate widget updates after data changes
4. **Shared Model**: Identical `Task` struct in both targets

## Security Architecture

### Entitlements

**Main App (`JuDo.entitlements`)**:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aloraini.JuDo</string>
</array>
```

**Widget Extension (`JuDoWidgetExtension.entitlements`)**:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aloraini.JuDo</string>
</array>
```

### Security Considerations

- **Sandboxed Environment**: Both app and widget run in separate sandboxes
- **App Group Isolation**: Data shared only between authorized targets
- **No Network Dependencies**: All data stored locally
- **URL Scheme Validation**: Custom scheme handling with validation

## WidgetKit Integration

### Timeline Management

**Refresh Strategy**:
- **System-Scheduled**: WidgetKit controls when widgets update
- **Requested Reloads**: App requests immediate updates after data changes
- **Fallback Policy**: 15-minute maximum refresh interval

**Widget Families**:
- **Medium**: Up to 5 tasks, compact layout
- **Large**: Up to 8 tasks, expanded layout

### Interactive Widgets

**Interactive Features**:
- **Task Completion Toggle**: Direct widget interaction
- **Quick Add**: URL scheme to open app with add task sheet
- **Preference Sync**: Hide/show completed tasks preference

## Performance Considerations

### Data Loading

- **Lazy Loading**: Tasks loaded on-demand from UserDefaults
- **Efficient Decoding**: Single JSON decode operation
- **Memory Management**: `@StateObject` for proper lifecycle

### UI Performance

- **SwiftUI Optimizations**: List view with efficient updates
- **Minimal Re-renders**: Targeted `@Published` property updates
- **Native Controls**: System-optimized UI components

### Widget Performance

- **Timeline Efficiency**: Minimal data in timeline entries
- **Background Processing**: Widget updates in background
- **Resource Management**: Lightweight widget views

## Error Handling

### Data Corruption

```swift
private func loadTasks() {
    guard !tasksData.isEmpty else {
        tasks = []
        return
    }
    
    do {
        tasks = try JSONDecoder().decode([Task].self, from: tasksData)
    } catch {
        print("Error loading tasks: \(error)")
        tasks = [] // Reset to empty state
    }
}
```

### Widget Timeline Errors

- **Graceful Degradation**: Empty task list on errors
- **Retry Mechanism**: System handles failed timeline updates
- **Error Logging**: Console logging for debugging

## Future Architecture Considerations

### Potential Enhancements

1. **CloudKit Integration**: For cross-device synchronization
2. **Core Data Migration**: For more complex data relationships
3. **Background Tasks**: For scheduled task reminders
4. **Shortcuts Integration**: For Siri task management

### Scalability

- **Current Design**: Suitable for personal task management
- **Task Limits**: No explicit limits, performance degrades with 1000+ tasks
- **Storage**: Local-only, limited by device storage

## Testing Architecture

### Unit Tests (`JuDoTests`)

- **TaskManager Tests**: CRUD operations validation
- **Data Model Tests**: Task serialization/deserialization
- **Business Logic Tests**: Task ordering and filtering

### UI Tests (`JuDoUITests`)

- **User Interaction Tests**: Task creation, completion, deletion
- **Widget Integration Tests**: Cross-component data flow
- **Accessibility Tests**: VoiceOver and keyboard navigation

This architecture provides a solid foundation for a reliable, maintainable task management application with seamless widget integration.
