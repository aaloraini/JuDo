//
//  SharedTasks.swift
//  TaskWidgetApp
//
//  Shared data models and thread-safe data store for app and widget
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import Foundation
import os.log

// 1) One task item
struct TodoItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var sortOrder: Int

    init(id: UUID = UUID(), title: String, isDone: Bool = false, createdAt: Date = .now, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

// MARK: - Thread-safe Data Store
actor DataStore {
    static let shared = DataStore()

    private let logger = Logger(subsystem: "hkem.TaskWidgetApp", category: "DataStore")

    private let appGroupID = "group.com.hkem.taskwidget"
    private let itemsKey = "items"
    private let hideKey = "hideCompleted"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private init() {}

    // MARK: - Public Interface

    func load() -> ([TodoItem], Bool) {
        let hideCompleted = defaults.bool(forKey: hideKey)

        guard let data = defaults.data(forKey: itemsKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return ([], hideCompleted)
        }
        return (decoded, hideCompleted)
    }

    func save(items: [TodoItem], hideCompleted: Bool) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: itemsKey)
        }
        defaults.set(hideCompleted, forKey: hideKey)
        defaults.synchronize()
    }

    func toggleTask(with id: UUID) -> [TodoItem] {
        var (items, hideCompleted) = load()

        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isDone.toggle()
            save(items: items, hideCompleted: hideCompleted)
        }
        return items
    }

    func addTask(title: String) -> [TodoItem] {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // IMPORTANT: do NOT return [] here (it wipes UI state)
        guard !trimmedTitle.isEmpty else {
            let (items, _) = load()
            return items
        }

        var (items, hideCompleted) = load()

        // Find the highest sort order and add 1, or use 0 if no items
        let maxSortOrder = items.map { $0.sortOrder }.max() ?? 0
        let newItem = TodoItem(title: trimmedTitle, sortOrder: maxSortOrder + 1)
        items.insert(newItem, at: 0)

        save(items: items, hideCompleted: hideCompleted)
        return items
    }

    // ✅ ADD THIS: update title (edit task)
    func updateTask(id: UUID, title: String) -> [TodoItem] {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var (items, hideCompleted) = load()

        guard let index = items.firstIndex(where: { $0.id == id }),
              !trimmed.isEmpty else {
            return items
        }

        items[index].title = trimmed
        save(items: items, hideCompleted: hideCompleted)
        return items
    }

    // ✅ ADD THIS: delete task
    func deleteTask(id: UUID) -> [TodoItem] {
        var (items, hideCompleted) = load()
        items.removeAll { $0.id == id }
        save(items: items, hideCompleted: hideCompleted)
        return items
    }

    func setHideCompleted(_ value: Bool) {
        let (items, _) = load()
        save(items: items, hideCompleted: value)
    }

    func visibleItems() -> [TodoItem] {
        let (items, hideCompleted) = load()

        // Handle backward compatibility: assign sort order to items that don't have one
        var sortedItems = items
        let itemsWithoutSortOrder = items.filter { $0.sortOrder == 0 }

        // Only auto-assign sort orders if ALL items have sortOrder == 0 (indicating first-time load)
        if itemsWithoutSortOrder.count == items.count && items.count > 1 {
            // If ALL items have sortOrder = 0, reassign based on creation date
            sortedItems = items.enumerated().map { index, item in
                var updatedItem = item
                updatedItem.sortOrder = index
                return updatedItem
            }
            // Save the updated sort orders
            save(items: sortedItems, hideCompleted: hideCompleted)
            logger.info("Auto-assigned sort orders to \(sortedItems.count) items")
        }

        let sorted = sortedItems.sorted { $0.sortOrder < $1.sortOrder }
        return hideCompleted ? sorted.filter { !$0.isDone } : sorted
    }

    // ✅ ADD THIS: reorder tasks
    func reorderTasks(from sourceIndexSet: IndexSet, to destination: Int) -> [TodoItem] {
        logger.info("Reordering tasks: from indices \(sourceIndexSet) to destination \(destination)")

        var (items, hideCompleted) = load()
        let sortedItems = items.sorted { $0.sortOrder < $1.sortOrder }

        var reorderedItems = Array(sortedItems)
        let itemsToMove = sourceIndexSet.map { reorderedItems[$0] }

        // Remove items from original positions
        for index in sourceIndexSet.reversed() {
            reorderedItems.remove(at: index)
        }

        // Insert items at new position
        let adjustedDestination = destination - sourceIndexSet.filter { $0 < destination }.count
        for (offset, item) in itemsToMove.enumerated() {
            reorderedItems.insert(item, at: adjustedDestination + offset)
        }

        // Update sort orders
        for (index, var item) in reorderedItems.enumerated() {
            item.sortOrder = index
            if let originalIndex = items.firstIndex(where: { $0.id == item.id }) {
                items[originalIndex] = item
            }
        }

        save(items: items, hideCompleted: hideCompleted)
        logger.info("Reordering completed: saved \(items.count) items with new sort orders")
        return items
    }
}
