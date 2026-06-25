import Foundation
import Combine
import SwiftUI
import WidgetKit
import SwiftData
import CoreData

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var hideCompleted: Bool = false
    @AppStorage("sortOption", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var sortOption: TaskSortOption = .manual

    private let modelContext: ModelContext

    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
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
            self?.loadTasks()
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

    private func persist() {
        do {
            try modelContext.save()
        } catch {
            print("[JuDo] Save failed: \(error)")
        }
    }

    private func reloadAndNotify() {
        persist()
        loadTasks()
        WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
    }

    // Kept for compatibility with ContentView and ErrorHandling
    func saveTasks() {
        reloadAndNotify()
    }

    func addTask(title: String, priority: Priority? = nil, dueDate: Date? = nil) {
        let newTask = Task(title: title, order: tasks.count, priority: priority, dueDate: dueDate)
        modelContext.insert(newTask)
        reloadAndNotify()
    }

    func deleteTask(_ task: Task) {
        modelContext.delete(task)
        persist()
        loadTasks()
        reorderTasks()
        reloadAndNotify()
    }

    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        task.completedAt = task.isCompleted ? Date() : nil
        reloadAndNotify()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        let incomplete = incompleteTasks
        guard let sourceIdx = source.first, sourceIdx < incomplete.count else { return }
        let taskToMove = incomplete[sourceIdx]
        guard let actualSource = tasks.firstIndex(where: { $0.id == taskToMove.id }) else { return }
        let actualDest: Int
        if destination < incomplete.count {
            actualDest = tasks.firstIndex(where: { $0.id == incomplete[destination].id }) ?? destination
        } else if let last = incomplete.last {
            actualDest = (tasks.firstIndex(where: { $0.id == last.id }) ?? 0) + 1
        } else {
            actualDest = 0
        }
        tasks.move(fromOffsets: IndexSet(integer: actualSource), toOffset: actualDest)
        reorderTasks()
        saveTasks()
    }

    func reorderTasks() {
        for (index, task) in tasks.enumerated() {
            task.order = index
        }
    }

    func clearCompletedTasks() {
        tasks.filter { $0.isCompleted }.forEach { modelContext.delete($0) }
        persist()
        loadTasks()
        reorderTasks()
        reloadAndNotify()
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
