//
//  JuDoWidget.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import WidgetKit
import SwiftUI
import AppIntents

enum TaskSortOption: String, CaseIterable {
    case manual = "Manual"
    case priority = "Priority"
    case dueDate = "Due Date"
    case created = "Created"
    case updated = "Updated"
}

enum TaskWidgetSorting {
    static func sort(tasks: [Task], by option: TaskSortOption) -> [Task] {
        switch option {
        case .manual:
            return tasks.sorted { $0.order < $1.order }
        case .priority:
            return tasks.sorted { (a, b) in
                let aPriority = a.priority?.sortValue ?? 0
                let bPriority = b.priority?.sortValue ?? 0
                if aPriority != bPriority {
                    return aPriority > bPriority
                }
                return a.order < b.order
            }
        case .dueDate:
            return tasks.sorted { (a, b) in
                if a.isOverdue && !b.isOverdue { return true }
                if !a.isOverdue && b.isOverdue { return false }

                switch (a.dueDate, b.dueDate) {
                case (nil, nil):
                    return a.order < b.order
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let aDate?, let bDate?):
                    if aDate != bDate {
                        return aDate < bDate
                    }
                    return a.order < b.order
                }
            }
        case .created:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .updated:
            return tasks.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

private enum TahoeWidgetStyle {
    static let accent = Color.accentColor
    static let rowFill = Color.primary.opacity(0.06)
    static let rowBorder = Color.primary.opacity(0.12)
    static let divider = Color.secondary.opacity(0.3)
    static let headerTint = Color.secondary.opacity(0.2)
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self
        }
    }
}

private struct TahoeWidgetHeader: View {
    let title: String
    let subtitle: String
    let addURL: URL

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [TahoeWidgetStyle.accent, TahoeWidgetStyle.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: addURL) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(TahoeWidgetStyle.headerTint)
                    )
                    .overlay(
                        Circle()
                            .stroke(TahoeWidgetStyle.rowBorder, lineWidth: 0.6)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct TahoeRowBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(TahoeWidgetStyle.rowFill)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(TahoeWidgetStyle.rowBorder, lineWidth: 0.6)
            )
    }
}

private struct TahoeDivider: View {
    var body: some View {
        Rectangle()
            .fill(TahoeWidgetStyle.divider)
            .frame(height: 0.6)
    }
}

private struct TahoeEmptyState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.18))
                )

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum TaskWidgetSummary {
    static func subtitle(for tasks: [Task]) -> String {
        guard !tasks.isEmpty else { return "No tasks yet" }
        let remaining = tasks.filter { !$0.isCompleted }.count
        if remaining == 0 {
            return "All tasks completed"
        }
        return "\(remaining) remaining"
    }
}

private enum TaskWidgetEmptyStateCopy {
    static func text(tasks: [Task], hideCompleted: Bool) -> (title: String, subtitle: String) {
        let hasTasks = !tasks.isEmpty
        let hasIncomplete = tasks.contains { !$0.isCompleted }

        if hideCompleted && hasTasks && !hasIncomplete {
            return ("All tasks completed", "Completed tasks are hidden.")
        }

        return ("No tasks", "Add a task from the app.")
    }
}

private enum TaskWidgetBadge {
    static func status(for task: Task) -> (text: String, icon: String, color: Color)? {
        if task.isOverdue {
            return ("Overdue", "exclamationmark.circle.fill", .red)
        }
        if task.isDueToday {
            return ("Today", "calendar", .orange)
        }
        return nil
    }
}

private struct TaskStatusBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
            Text(text)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color.opacity(0.18))
        )
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let tasks = loadTasks()
        let entry = SimpleEntry(date: Date(), tasks: tasks)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let tasks = loadTasks()
        let entry = SimpleEntry(date: Date(), tasks: tasks)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTasks() -> [Task] {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            print("Failed to access shared UserDefaults")
            return []
        }

        let sortOptionRaw = sharedDefaults.string(forKey: "sortOption") ?? TaskSortOption.manual.rawValue
        let sortOption = TaskSortOption(rawValue: sortOptionRaw) ?? .manual
        
        guard let data = sharedDefaults.data(forKey: "tasks") else {
            print("No tasks data found")
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            print("Successfully loaded \(tasks.count) tasks")
            return TaskWidgetSorting.sort(tasks: tasks, by: sortOption)
        } catch {
            print("Failed to decode tasks: \(error)")
            // Attempt to clear corrupted data
            sharedDefaults.removeObject(forKey: "tasks")
            return []
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [Task]
}

struct JuDoWidgetEntryView : View {
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

struct JuDoMediumWidgetView: View {
    let tasks: [Task]
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) private var hideCompleted: Bool = false
    
    var filteredTasks: [Task] {
        if hideCompleted {
            return tasks.filter { !$0.isCompleted }.prefix(5).map { $0 }
        }
        return tasks.prefix(5).map { $0 }
    }

    private var headerSubtitle: String {
        TaskWidgetSummary.subtitle(for: tasks)
    }

    private let addURL = URL(string: "judo://add")!
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                TahoeWidgetHeader(title: "JuDo", subtitle: headerSubtitle, addURL: addURL)
                TahoeDivider()

                if filteredTasks.isEmpty {
                    let emptyCopy = TaskWidgetEmptyStateCopy.text(tasks: tasks, hideCompleted: hideCompleted)
                    TahoeEmptyState(title: emptyCopy.title, subtitle: emptyCopy.subtitle)
                } else {
                    VStack(spacing: 4) {
                        ForEach(filteredTasks) { task in
                            TaskWidgetRow(task: task)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
        .widgetContainerBackground()
    }
}

struct JuDoLargeWidgetView: View {
    let tasks: [Task]
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) private var hideCompleted: Bool = false
    
    var filteredTasks: [Task] {
        if hideCompleted {
            return tasks.filter { !$0.isCompleted }.prefix(8).map { $0 }
        }
        return tasks.prefix(8).map { $0 }
    }

    private var headerSubtitle: String {
        TaskWidgetSummary.subtitle(for: tasks)
    }

    private let addURL = URL(string: "judo://add")!
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                TahoeWidgetHeader(title: "JuDo", subtitle: headerSubtitle, addURL: addURL)
                TahoeDivider()

                if filteredTasks.isEmpty {
                    let emptyCopy = TaskWidgetEmptyStateCopy.text(tasks: tasks, hideCompleted: hideCompleted)
                    TahoeEmptyState(title: emptyCopy.title, subtitle: emptyCopy.subtitle)
                } else {
                    VStack(spacing: 4) {
                        ForEach(filteredTasks) { task in
                            TaskWidgetRowLarge(task: task)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
        .widgetContainerBackground()
    }
}

struct TaskWidgetRow: View {
    let task: Task
    
    var priorityColor: Color? {
        guard let priority = task.priority else { return nil }
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }

    private var statusBadge: (text: String, icon: String, color: Color)? {
        guard !task.isCompleted else { return nil }
        return TaskWidgetBadge.status(for: task)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ToggleTaskIntent(taskId: task.id)) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isCompleted ? TahoeWidgetStyle.accent : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 16, height: 16)
            
            // Priority indicator (visual only in medium widget)
            if let color = priorityColor {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }
            
            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(task.isCompleted ? .secondary : (task.isOverdue ? .red : .primary))
                .strikethrough(task.isCompleted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let badge = statusBadge {
                TaskStatusBadge(icon: badge.icon, text: badge.text, color: badge.color)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(TahoeRowBackground())
    }
}

struct TaskWidgetRowLarge: View {
    let task: Task
    
    var priorityColor: Color? {
        guard let priority = task.priority else { return nil }
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
    
    var currentPriority: PriorityIntentValue {
        PriorityIntentValue.from(task.priority)
    }

    private var statusBadge: (text: String, icon: String, color: Color)? {
        guard !task.isCompleted else { return nil }
        return TaskWidgetBadge.status(for: task)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ToggleTaskIntent(taskId: task.id)) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isCompleted ? TahoeWidgetStyle.accent : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 16, height: 16)
            
            // Interactive priority indicator (tap to cycle)
            Button(intent: SetPriorityIntent(taskId: task.id, priority: currentPriority.next())) {
                if let color = priorityColor {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        .frame(width: 6, height: 6)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 12, height: 12)
            .help("Tap to change priority")
            
            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(task.isCompleted ? .secondary : (task.isOverdue ? .red : .primary))
                .strikethrough(task.isCompleted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let badge = statusBadge {
                TaskStatusBadge(icon: badge.icon, text: badge.text, color: badge.color)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(TahoeRowBackground())
    }
}

struct JuDoWidget: Widget {
    let kind: String = "JuDoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JuDoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("JuDo Tasks")
        .description("View and manage your tasks from JuDo")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}


#Preview(as: .systemMedium) {
    JuDoWidget()
} timeline: {
    SimpleEntry(date: .now, tasks: [
        Task(title: "Sample task 1", order: 0),
        Task(title: "Sample task 2", order: 1),
        Task(title: "Sample task 3", order: 2)
    ])
}
