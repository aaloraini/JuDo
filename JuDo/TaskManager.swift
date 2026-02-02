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

class TaskManager: ObservableObject {
    @AppStorage("tasks", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) private var tasksData: Data = Data()
    @Published var tasks: [Task] = []
    @AppStorage("hideCompleted", store: UserDefaults(suiteName: "group.com.aloraini.JuDo")) var hideCompleted: Bool = false
    
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
    
    private func saveTasks() {
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
    
    func addTask(title: String) {
        let newTask = Task(title: title, order: tasks.count)
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
    
    private func reorderTasks() {
        for (index, _) in tasks.enumerated() {
            tasks[index].order = index
        }
    }
    
    var filteredTasks: [Task] {
        if hideCompleted {
            return tasks.filter { !$0.isCompleted }
        }
        return tasks
    }
}
