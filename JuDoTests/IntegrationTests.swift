//
//  IntegrationTests.swift
//  JuDoTests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Testing
import Foundation
@testable import JuDo

struct IntegrationTests {
    
    init() {
        TestHelpers.clearTestData()
    }
    
    @Test("Complete task lifecycle integration")
    func completeTaskLifecycle() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager = TaskManager()
        
        // Add task
        taskManager.addTask(title: "Integration Test Task")
        #expect(taskManager.tasks.count == 1)
        
        let task = taskManager.tasks.first!
        #expect(task.title == "Integration Test Task")
        #expect(task.isCompleted == false)
        
        // Toggle completion
        taskManager.toggleTaskCompletion(task)
        #expect(task.isCompleted == true)
        
        // Delete task
        taskManager.deleteTask(task)
        #expect(taskManager.tasks.isEmpty)
    }
    
    @Test("Multiple task managers data sharing")
    func multipleTaskManagersDataSharing() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager1 = TaskManager()
        taskManager1.addTask(title: "Shared Task 1")
        taskManager1.addTask(title: "Shared Task 2")
        
        let taskManager2 = TaskManager()
        #expect(taskManager2.tasks.count == 2)
        #expect(taskManager2.tasks.contains { $0.title == "Shared Task 1" })
        #expect(taskManager2.tasks.contains { $0.title == "Shared Task 2" })
    }
}
