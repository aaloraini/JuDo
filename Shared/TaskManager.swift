import Foundation
import Combine
import SwiftUI
import WidgetKit
import SwiftData
import CoreData

@MainActor
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var hideCompleted: Bool = false
    @AppStorage("sortOption", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var sortOption: TaskSortOption = .manual

    private let modelContext: ModelContext

    init(container: ModelContainer) {
        self.modelContext = container.mainContext
        loadTasks()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func handleRemoteChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.loadTasks()
            WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
        }
    }

    func loadTasks() {
        do {
            let descriptor = FetchDescriptor<Task>()
            tasks = try modelContext.fetch(descriptor)
        } catch {
            print("[JuDo] Fetch failed: \(error)")
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("[JuDo] Save failed: \(error)")
        }
        loadTasks()
        WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
    }

    func addTask(title: String, priority: Priority? = nil, dueDate: Date? = nil, subtaskTitles: [String] = []) {
        let newTask = Task(title: title, order: topLevelTasks.count, priority: priority, dueDate: dueDate)
        modelContext.insert(newTask)
        var order = 0
        for subtitle in subtaskTitles {
            let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            modelContext.insert(Task(title: trimmed, order: order, parentId: newTask.id))
            order += 1
        }
        save()
    }

    func addSubtask(to parent: Task, title: String) {
        let subtask = Task(title: title, order: subtasks(of: parent).count, parentId: parent.id)
        modelContext.insert(subtask)
        // The list grew, so a completed master goes back to incomplete
        if parent.isCompleted {
            TaskCompletion.setCompleted(parent, false)
        }
        save()
    }

    func deleteTask(_ task: Task) {
        for child in tasks where child.parentId == task.id {
            modelContext.delete(child)
        }
        let scope = task.parentId
        let deletedOrder = task.order
        modelContext.delete(task)
        save()
        // Only shift siblings that were after the deleted one
        for t in tasks where t.parentId == scope && t.order > deletedOrder {
            t.order -= 1
        }
        save()
    }

    func toggleTaskCompletion(_ task: Task) {
        TaskCompletion.toggle(
            task,
            children: { parent in self.subtasks(of: parent) },
            parent: { child in child.parentId.flatMap { pid in self.tasks.first { $0.id == pid } } }
        )
        save()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        let incomplete = incompleteTasks
        guard let sourceIdx = source.first, sourceIdx < incomplete.count else { return }
        let taskToMove = incomplete[sourceIdx]
        let oldOrder = taskToMove.order

        // Calculate the new order based on neighbors in the incomplete list
        let newOrder: Int
        if destination <= 0 {
            newOrder = (incomplete.first?.order ?? 0) - 1
        } else if destination >= incomplete.count {
            newOrder = (incomplete.last?.order ?? 0) + 1
        } else {
            let target = incomplete[destination]
            newOrder = target.order
        }

        if oldOrder < newOrder {
            for t in tasks where t.parentId == nil && t.order > oldOrder && t.order <= newOrder {
                t.order -= 1
            }
        } else if oldOrder > newOrder {
            for t in tasks where t.parentId == nil && t.order >= newOrder && t.order < oldOrder {
                t.order += 1
            }
        }
        taskToMove.order = newOrder
        taskToMove.updatedAt = Date()
        save()
    }

    func moveSubtask(of parent: Task, from source: IndexSet, to destination: Int) {
        let siblings = subtasks(of: parent)
        guard let sourceIdx = source.first, sourceIdx < siblings.count else { return }
        let taskToMove = siblings[sourceIdx]
        let oldOrder = taskToMove.order

        let newOrder: Int
        if destination <= 0 {
            newOrder = (siblings.first?.order ?? 0) - 1
        } else if destination >= siblings.count {
            newOrder = (siblings.last?.order ?? 0) + 1
        } else {
            newOrder = siblings[destination].order
        }

        if oldOrder < newOrder {
            for t in tasks where t.parentId == parent.id && t.order > oldOrder && t.order <= newOrder {
                t.order -= 1
            }
        } else if oldOrder > newOrder {
            for t in tasks where t.parentId == parent.id && t.order >= newOrder && t.order < oldOrder {
                t.order += 1
            }
        }
        taskToMove.order = newOrder
        taskToMove.updatedAt = Date()
        save()
    }

    func clearCompletedTasks() {
        // Completed subtasks of an incomplete master are kept; they stay
        // visible under their master and feed its progress count.
        let completedTopLevel = topLevelTasks.filter { $0.isCompleted }
        for task in completedTopLevel {
            for child in tasks where child.parentId == task.id {
                modelContext.delete(child)
            }
            modelContext.delete(task)
        }
        save()
        // Compact remaining top-level order values
        let sorted = topLevelTasks.sorted { $0.order < $1.order }
        for (index, task) in sorted.enumerated() where task.order != index {
            task.order = index
        }
        if modelContext.hasChanges { save() }
    }

    // Kept for compatibility with ContentView and ErrorHandling
    func saveTasks() {
        save()
    }

    // MARK: - Subtasks

    /// Tasks shown at the root of the list. Orphan-tolerant: a child whose
    /// parent hasn't synced yet (CloudKit delivers records in arbitrary order)
    /// shows as top-level and self-heals when the parent record arrives.
    private var topLevelTasks: [Task] {
        let ids = Set(tasks.map(\.id))
        return tasks.filter { $0.parentId == nil || !ids.contains($0.parentId!) }
    }

    func subtasks(of parent: Task) -> [Task] {
        tasks.filter { $0.parentId == parent.id }.sorted { $0.order < $1.order }
    }

    func hasSubtasks(_ task: Task) -> Bool {
        tasks.contains { $0.parentId == task.id }
    }

    func subtaskProgress(of task: Task) -> (done: Int, total: Int)? {
        let children = subtasks(of: task)
        guard !children.isEmpty else { return nil }
        return (children.filter(\.isCompleted).count, children.count)
    }

    /// Search match: a task matches if its own title/notes match or any subtask's title does.
    func matches(_ task: Task, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        if task.title.localizedCaseInsensitiveContains(query) { return true }
        if task.notes?.localizedCaseInsensitiveContains(query) ?? false { return true }
        return subtasks(of: task).contains { $0.title.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Computed views

    var incompleteTasks: [Task] {
        sortTasks(topLevelTasks.filter { !$0.isCompleted })
    }

    var completedTasks: [Task] {
        sortTasks(topLevelTasks.filter { $0.isCompleted })
    }

    var filteredTasks: [Task] {
        sortTasks(hideCompleted ? topLevelTasks.filter { !$0.isCompleted } : topLevelTasks)
    }

    private func sortTasks(_ input: [Task]) -> [Task] {
        switch sortOption {
        case .manual:
            return input.sorted { $0.order < $1.order }
        case .priority:
            return input.sorted { a, b in
                let ap = a.priority?.sortValue ?? 0
                let bp = b.priority?.sortValue ?? 0
                return ap != bp ? ap > bp : a.order < b.order
            }
        case .dueDate:
            return input.sorted { a, b in
                if a.isOverdue != b.isOverdue { return a.isOverdue }
                switch (a.dueDate, b.dueDate) {
                case (nil, nil): return a.order < b.order
                case (nil, _):   return false
                case (_, nil):   return true
                case (let ad?, let bd?):
                    return ad != bd ? ad < bd : a.order < b.order
                }
            }
        case .created:
            return input.sorted { $0.createdAt > $1.createdAt }
        case .updated:
            return input.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}
