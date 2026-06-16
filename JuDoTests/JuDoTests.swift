//
//  JuDoTests.swift
//  JuDoTests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Testing
import Foundation
@testable import JuDo

struct JuDoTests {
    
    // MARK: - Test Lifecycle
    
    init() {
        // Clean up any existing test data before running tests
        TestHelpers.clearTestData()
    }
    
    // MARK: - TaskManager Unit Tests
    
    @Test("TaskManager initialization with empty data")
    func taskManagerInitialization() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager = TaskManager()
        
        #expect(taskManager.tasks.isEmpty)
        #expect(taskManager.filteredTasks.isEmpty)
        #expect(taskManager.hideCompleted == false)
    }
    
    @Test("TaskManager initialization with existing data")
    func taskManagerInitializationWithData() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 3)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        
        let taskManager = TaskManager()
        
        #expect(taskManager.tasks.count == 3)
        #expect(taskManager.filteredTasks.count == 3)
        
        // Verify task data integrity
        for (index, task) in taskManager.tasks.enumerated() {
            #expect(task.title == "Test Task \(index + 1)")
            #expect(task.order == index)
            #expect(task.isCompleted == false)
        }
    }
    
    @Test("Add task functionality")
    func addTask() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        taskManager.addTask(title: "New Task")
        
        #expect(taskManager.tasks.count == 1)
        #expect(taskManager.filteredTasks.count == 1)
        
        let task = taskManager.tasks.first!
        #expect(task.title == "New Task")
        #expect(task.order == 0)
        #expect(task.isCompleted == false)
    }
    
    @Test("Add multiple tasks")
    func addMultipleTasks() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        taskManager.addTask(title: "Task 1")
        taskManager.addTask(title: "Task 2")
        taskManager.addTask(title: "Task 3")
        
        #expect(taskManager.tasks.count == 3)
        #expect(taskManager.tasks[0].title == "Task 1")
        #expect(taskManager.tasks[0].order == 0)
        #expect(taskManager.tasks[1].title == "Task 2")
        #expect(taskManager.tasks[1].order == 1)
        #expect(taskManager.tasks[2].title == "Task 3")
        #expect(taskManager.tasks[2].order == 2)
    }
    
    @Test("Delete task functionality")
    func deleteTask() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 3)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        let taskManager = TaskManager()
        
        let taskToDelete = taskManager.tasks[1]
        taskManager.deleteTask(taskToDelete)
        
        #expect(taskManager.tasks.count == 2)
        #expect(taskManager.tasks.contains { $0.id == taskToDelete.id } == false)
        
        // Verify tasks are reordered correctly
        #expect(taskManager.tasks[0].order == 0)
        #expect(taskManager.tasks[1].order == 1)
    }
    
    @Test("Toggle task completion")
    func toggleTaskCompletion() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 1)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        let taskManager = TaskManager()
        
        let task = taskManager.tasks.first!
        #expect(task.isCompleted == false)
        
        taskManager.toggleTaskCompletion(task)
        #expect(task.isCompleted == true)
        
        taskManager.toggleTaskCompletion(task)
        #expect(task.isCompleted == false)
    }
    
    @Test("Move task functionality")
    func moveTask() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 3)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        let taskManager = TaskManager()
        
        // Move task at index 0 to index 2
        taskManager.moveTask(from: IndexSet([0]), to: 2)
        
        #expect(taskManager.tasks.count == 3)
        #expect(taskManager.tasks[0].title == "Test Task 2")
        #expect(taskManager.tasks[0].order == 0)
        #expect(taskManager.tasks[1].title == "Test Task 3")
        #expect(taskManager.tasks[1].order == 1)
        #expect(taskManager.tasks[2].title == "Test Task 1")
        #expect(taskManager.tasks[2].order == 2)
    }
    
    @Test("Hide completed tasks functionality")
    func hideCompletedTasks() async throws {
        let mixedTasks = TestHelpers.createMixedTasks(count: 4)
        TestHelpers.setupTestEnvironment(tasks: mixedTasks)
        let taskManager = TaskManager()
        
        // Initially, hideCompleted is false, so all tasks should be visible
        #expect(taskManager.filteredTasks.count == 4)
        
        // Hide completed tasks
        taskManager.hideCompleted = true
        let visibleTasks = taskManager.filteredTasks
        #expect(visibleTasks.count == 2) // Only uncompleted tasks
        #expect(visibleTasks.allSatisfy { !$0.isCompleted })
        
        // Show completed tasks again
        taskManager.hideCompleted = false
        #expect(taskManager.filteredTasks.count == 4)
    }
    
    @Test("Data persistence verification")
    func dataPersistence() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager1 = TaskManager()
        
        taskManager1.addTask(title: "Persistent Task")
        #expect(taskManager1.tasks.count == 1)
        
        // Create a new TaskManager instance to simulate app restart
        let taskManager2 = TaskManager()
        #expect(taskManager2.tasks.count == 1)
        #expect(taskManager2.tasks.first?.title == "Persistent Task")
    }
    
    // MARK: - Performance Tests
    
    @Test("Performance: Adding 100 tasks")
    func performanceAddTasks() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        let (_, timeInterval) = TestHelpers.measureTime {
            for i in 0..<100 {
                taskManager.addTask(title: "Task \(i)")
            }
        }
        
        #expect(taskManager.tasks.count == 100)
        #expect(timeInterval < 1.0) // Should complete within 1 second
    }
    
    @Test("Performance: Loading large dataset")
    func performanceLoadLargeDataset() async throws {
        let largeTasks = TestHelpers.createSampleTasks(count: 1000)
        TestHelpers.setupTestEnvironment(tasks: largeTasks)
        
        let (_, timeInterval) = TestHelpers.measureTime {
            let taskManager = TaskManager()
            #expect(taskManager.tasks.count == 1000)
        }
        
        #expect(timeInterval < 0.5) // Should load within 0.5 seconds
    }
    
    // MARK: - Edge Cases
    
    @Test("Edge case: Empty task title")
    func emptyTaskTitle() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        taskManager.addTask(title: "")
        #expect(taskManager.tasks.isEmpty) // Should not add empty task
        
        taskManager.addTask(title: "   ")
        #expect(taskManager.tasks.isEmpty) // Should not add whitespace-only task
        
        taskManager.addTask(title: "Valid Task")
        #expect(taskManager.tasks.count == 1) // Should add valid task
    }
    
    @Test("Edge case: Delete non-existent task")
    func deleteNonExistentTask() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        let nonExistentTask = TestHelpers.createSampleTask(title: "Non-existent")
        taskManager.deleteTask(nonExistentTask)
        
        #expect(taskManager.tasks.isEmpty) // Should not crash or change state
    }
    
    @Test("Edge case: Toggle non-existent task")
    func toggleNonExistentTask() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        let nonExistentTask = TestHelpers.createSampleTask(title: "Non-existent")
        taskManager.toggleTaskCompletion(nonExistentTask)
        
        #expect(taskManager.tasks.isEmpty) // Should not crash or change state
    }
}
