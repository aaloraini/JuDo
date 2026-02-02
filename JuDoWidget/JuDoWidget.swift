//
//  JuDoWidget.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), tasks: loadTasks())
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
        guard let data = UserDefaults(suiteName: "group.com.aloraini.JuDo")?.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return []
        }
        return tasks.sorted { $0.order < $1.order }
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("JuDo Tasks")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
                .padding(.horizontal, 16)
            
            // Task list
            if filteredTasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No tasks")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(filteredTasks) { task in
                        TaskWidgetRow(task: task)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
                Spacer()
            }
        }
        .background(Color.clear)
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("JuDo Tasks")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
                .padding(.horizontal, 16)
            
            // Task list
            if filteredTasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No tasks")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(filteredTasks) { task in
                        TaskWidgetRow(task: task)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
                Spacer()
            }
        }
        .background(Color.clear)
    }
}

struct TaskWidgetRow: View {
    let task: Task
    @AppStorage("tasks", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) private var tasksData: Data = Data()
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(task.isCompleted ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 20, height: 20)
            
            Text(task.title)
                .font(.system(size: 14))
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 24)
    }
    
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

struct JuDoWidget: Widget {
    let kind: String = "JuDoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                JuDoWidgetEntryView(entry: entry)
                    .containerBackground(.ultraThinMaterial, for: .widget)
            } else {
                JuDoWidgetEntryView(entry: entry)
                    .containerBackground(.thinMaterial, for: .widget)
            }
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
