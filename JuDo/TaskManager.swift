//
//  TaskManager.swift
//  JuDo
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Foundation
import SwiftUI
import WidgetKit
import Combine

enum TaskSortOption: String, CaseIterable, Codable {
    case manual = "Manual"
    case priority = "Priority"
    case dueDate = "Due Date"
    case created = "Created"
    case updated = "Updated"
}

class TaskManager: ObservableObject {
    @AppStorage("tasks", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) private var tasksData: Data = Data()
    @Published var tasks: [Task] = []
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var hideCompleted: Bool = false
    @AppStorage("sortOption", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var sortOption: TaskSortOption = .manual
    
    init() {
        loadTasks()
    }
    
    private func loadTasks() {
        guard !tasksData.isEmpty else {
            tasks = []
            return
        }
        
        do {
            tasks = try JSONDecoder().decode([Task].self, from: tasksData)
        } catch {
            print("Error loading tasks: \(error)")
            tasks = []
        }
    }
    
    func saveTasks() {
        do {
            tasksData = try JSONEncoder().encode(tasks)
            reloadWidgetTimelines()
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
    }
    
    func addTask(title: String, priority: Priority? = nil, dueDate: Date? = nil) {
        let newTask = Task(title: title, order: tasks.count, priority: priority, dueDate: dueDate)
        tasks.append(newTask)
        saveTasks()
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        reorderTasks()
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].updatedAt = Date()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        saveTasks()
    }
    
    func moveTask(from source: IndexSet, to destination: Int) {
        var newTasks = tasks
        newTasks.move(fromOffsets: source, toOffset: destination)
        
        for (index, _) in newTasks.enumerated() {
            newTasks[index].order = index
        }
        
        tasks = newTasks
        saveTasks()
    }
    
    func reorderTasks() {
        for (index, _) in tasks.enumerated() {
            tasks[index].order = index
        }
    }
    
    var incompleteTasks: [Task] {
        let incomplete = tasks.filter { !$0.isCompleted }
        return sortTasks(incomplete)
    }
    
    var completedTasks: [Task] {
        let completed = tasks.filter { $0.isCompleted }
        return sortTasks(completed)
    }
    
    var filteredTasks: [Task] {
        let filtered = hideCompleted ? tasks.filter { !$0.isCompleted } : tasks
        return sortTasks(filtered)
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch sortOption {
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
                // Overdue tasks first
                if a.isOverdue && !b.isOverdue { return true }
                if !a.isOverdue && b.isOverdue { return false }
                
                // Then by due date
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
