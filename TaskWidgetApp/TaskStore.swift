//
//  TaskStore.swift
//  TaskWidgetApp
//
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import Foundation
import WidgetKit
import os.log

@MainActor
final class TaskStore: ObservableObject {
    static let shared = TaskStore()
    
    @Published private(set) var items: [TodoItem] = []
    @Published private(set) var hideCompleted: Bool = false
    
    private let dataStore = DataStore.shared
    private let logger = Logger(subsystem: "hkem.TaskWidgetApp", category: "TaskStore")
    
    private init() {
        Task {
            await load()
        }
    }
    
    func load() async {
        let (items, hideCompleted) = await dataStore.load()
        self.items = items
        self.hideCompleted = hideCompleted
    }

    
    func addTask(title: String) async {
        let updatedItems = await dataStore.addTask(title: title)
        self.items = updatedItems
        logger.info("Reloading widget timelines after adding task")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }

    
    func toggleDone(id: UUID) async {
        let updatedItems = await dataStore.toggleTask(with: id)
        self.items = updatedItems
        logger.info("Reloading widget timelines after toggling task")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }

    
    func setHideCompleted(_ value: Bool) async {
        await dataStore.setHideCompleted(value)
        self.hideCompleted = value
        logger.info("Reloading widget timelines after changing hide completed setting")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }

    func updateTask(id: UUID, title: String) async {
        let updatedItems = await dataStore.updateTask(id: id, title: title)
        self.items = updatedItems
        logger.info("Reloading widget timelines after updating task")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }


    func deleteTask(id: UUID) async {
        let updatedItems = await dataStore.deleteTask(id: id)
        self.items = updatedItems
        logger.info("Reloading widget timelines after deleting task")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }


    
    var visibleItems: [TodoItem] {
        items
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .filter { hideCompleted ? !$0.isDone : true }
    }
    
    func reorderTasks(from sourceIndexSet: IndexSet, to destination: Int) async {
        logger.info("Starting task reordering in TaskStore")
        let updatedItems = await dataStore.reorderTasks(from: sourceIndexSet, to: destination)
        self.items = updatedItems
        logger.info("Reloading widget timelines after reordering tasks")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
        
        // Force a more aggressive refresh to ensure widget sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
        }
    }
    
    // MARK: - Manual Widget Refresh
    func refreshWidget() {
        logger.info("Manual widget refresh triggered")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
