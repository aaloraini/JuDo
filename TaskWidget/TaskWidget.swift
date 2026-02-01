//
//  TaskWidget.swift
//  TaskWidget
//
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import WidgetKit
import SwiftUI
import os.log

struct TaskEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]
}

struct Provider: TimelineProvider {
    private let logger = Logger(subsystem: "hkem.TaskWidgetApp", category: "WidgetProvider")
    
    func placeholder(in context: Context) -> TaskEntry {
        logger.info("Widget placeholder requested")
        return TaskEntry(
            date: .now,
            items: [
                TodoItem(title: "Sample task"),
                TodoItem(title: "Done task", isDone: true)
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        logger.info("Widget snapshot requested")
        Task {
            let items = await DataStore.shared.visibleItems()
            let entry = TaskEntry(date: .now, items: items)
            logger.info("Widget snapshot completed with \(items.count) items")
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        logger.info("Widget timeline requested")
        Task {
            let items = await DataStore.shared.visibleItems()
            let entry = TaskEntry(date: .now, items: items)
            
            // Refresh in 15 minutes or on intent
            let timeline = Timeline(
                entries: [entry],
                policy: .after(Date().addingTimeInterval(15 * 60))
            )
            logger.info("Widget timeline completed with \(items.count) items, next refresh in 15 minutes")
            completion(timeline)
        }
    }
}

struct TaskWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int {
        switch family {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        case .systemLarge:
            return 12   // 👈 more rows for tall widget
        default:
            return 6
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if entry.items.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.items.prefix(maxRows)) { item in
                        TaskRowView(item: item)
                    }
                }

                if entry.items.count > maxRows {
                    Text("+\(entry.items.count - maxRows) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .containerBackground(.background, for: .widget)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .foregroundStyle(.secondary)

            Text("My Tasks")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            HStack(spacing: 8) {
                if !entry.items.isEmpty {
                    let done = entry.items.filter { $0.isDone }.count
                    Text("\(done)/\(entry.items.count)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.quaternary))
                }
            }
            
            Button(intent: AddTaskIntent()) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("No tasks")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Add tasks in the app")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 6)
    }
}

struct TaskRowView: View {
    let item: TodoItem

    var body: some View {
        Button(intent: ToggleTaskIntent(taskID: item.id.uuidString)) {
            HStack(spacing: 8) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)

                Text(item.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 3)   // 👈 tighter rows = more visible items
        }
        .buttonStyle(.plain)
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskWidgetView(entry: entry)
                .widgetAccentable()
        }
        .configurationDisplayName("Task Widget")
        .description("Shows your task list.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
