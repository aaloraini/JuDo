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

    func addTask(title: String, priority: Priority? = nil, dueDate: Date? = nil) {
        let newTask = Task(title: title, order: tasks.count, priority: priority, dueDate: dueDate)
        modelContext.insert(newTask)
        save()
    }

    func deleteTask(_ task: Task) {
        let deletedOrder = task.order
        modelContext.delete(task)
        save()
        // Only shift tasks that were after the deleted one
        for t in tasks where t.order > deletedOrder {
            t.order -= 1
        }
        save()
    }

    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        task.completedAt = task.isCompleted ? Date() : nil
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
            for t in tasks where t.order > oldOrder && t.order <= newOrder {
                t.order -= 1
            }
        } else if oldOrder > newOrder {
            for t in tasks where t.order >= newOrder && t.order < oldOrder {
                t.order += 1
            }
        }
        taskToMove.order = newOrder
        taskToMove.updatedAt = Date()
        save()
    }

    func clearCompletedTasks() {
        let completed = tasks.filter { $0.isCompleted }
        completed.forEach { modelContext.delete($0) }
        save()
        // Compact remaining order values
        let sorted = tasks.sorted { $0.order < $1.order }
        for (index, task) in sorted.enumerated() where task.order != index {
            task.order = index
        }
        if modelContext.hasChanges { save() }
    }

    // Kept for compatibility with ContentView and ErrorHandling
    func saveTasks() {
        save()
    }

    // MARK: - Computed views

    var incompleteTasks: [Task] {
        sortTasks(tasks.filter { !$0.isCompleted })
    }

    var completedTasks: [Task] {
        sortTasks(tasks.filter { $0.isCompleted })
    }

    var filteredTasks: [Task] {
        sortTasks(hideCompleted ? tasks.filter { !$0.isCompleted } : tasks)
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
