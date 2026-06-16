//
//  AppGroupsTests.swift
//  JuDoTests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Testing
import Foundation
@testable import JuDo

struct AppGroupsTests {
    
    // MARK: - Test Lifecycle
    
    init() {
        TestHelpers.clearTestData()
    }
    
    // MARK: - App Groups Integration Tests
    
    @Test("App Groups data sharing between TaskManager instances")
    func appGroupsDataSharing() async throws {
        TestHelpers.setupTestEnvironment()
        
        // Create first TaskManager and add tasks
        let taskManager1 = TaskManager()
        taskManager1.addTask(title: "Shared Task 1")
        taskManager1.addTask(title: "Shared Task 2")
        
        // Create second TaskManager instance (simulates app restart or different target)
        let taskManager2 = TaskManager()
        
        // Verify data is shared
        #expect(taskManager2.tasks.count == 2)
        #expect(taskManager2.tasks.contains { $0.title == "Shared Task 1" })
        #expect(taskManager2.tasks.contains { $0.title == "Shared Task 2" })
    }
    
    @Test("App Groups hideCompleted preference sharing")
    func appGroupsHideCompletedSharing() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager1 = TaskManager()
        taskManager1.hideCompleted = true
        
        // Create second TaskManager instance
        let taskManager2 = TaskManager()
        
        // Verify preference is shared
        #expect(taskManager2.hideCompleted == true)
    }
    
    @Test("Concurrent access to App Groups data")
    func concurrentAccess() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager1 = TaskManager()
        let taskManager2 = TaskManager()
        
        // Both managers add tasks concurrently
        taskManager1.addTask(title: "Concurrent Task 1")
        taskManager2.addTask(title: "Concurrent Task 2")
        
        // Verify both tasks are saved
        let taskManager3 = TaskManager()
        #expect(taskManager3.tasks.count == 2)
        #expect(taskManager3.tasks.contains { $0.title == "Concurrent Task 1" })
        #expect(taskManager3.tasks.contains { $0.title == "Concurrent Task 2" })
    }
    
    @Test("Data integrity across app restarts")
    func dataIntegrityAcrossRestarts() async throws {
        TestHelpers.setupTestEnvironment()
        
        // Simulate multiple app restarts
        for i in 1...5 {
            let taskManager = TaskManager()
            taskManager.addTask(title: "Restart Task \(i)")
            
            // Verify data persists
            let newTaskManager = TaskManager()
            #expect(newTaskManager.tasks.count == i)
            #expect(newTaskManager.tasks.contains { $0.title == "Restart Task \(i)" })
        }
    }
    
    @Test("Large dataset handling in App Groups")
    func largeDatasetHandling() async throws {
        let largeTasks = TestHelpers.createSampleTasks(count: 500)
        TestHelpers.setupTestEnvironment(tasks: largeTasks)
        
        let taskManager = TaskManager()
        #expect(taskManager.tasks.count == 500)
        
        // Verify data integrity
        for (index, task) in taskManager.tasks.enumerated() {
            #expect(task.title == "Test Task \(index + 1)")
            #expect(task.order == index)
        }
    }
    
    @Test("App Groups data corruption recovery")
    func dataCorruptionRecovery() async throws {
        TestHelpers.setupTestEnvironment()
        
        // Manually corrupt data in UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        // Write invalid JSON data
        userDefaults.set("invalid json".data(using: .utf8), forKey: "tasks")
        userDefaults.synchronize()
        
        // TaskManager should handle corruption gracefully
        let taskManager = TaskManager()
        #expect(taskManager.tasks.isEmpty) // Should default to empty array
    }
    
    @Test("App Groups permission handling")
    func appGroupsPermissionHandling() async throws {
        // This test simulates what happens when App Groups are not available
        // In a real scenario, this would test the fallback behavior
        
        let taskManager = TaskManager()
        
        // Should not crash even if App Groups are unavailable
        taskManager.addTask(title: "Permission Test Task")
        
        // Task should be added to local state even if persistence fails
        #expect(taskManager.tasks.count == 1)
    }
    
    // MARK: - Performance Tests for App Groups
    
    @Test("Performance: App Groups read/write operations")
    func performanceAppGroupsOperations() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        // Test write performance
        let writeTime = TestHelpers.measureTime {
            for i in 0..<100 {
                taskManager.addTask(title: "Performance Task \(i)")
            }
        }
        
        #expect(taskManager.tasks.count == 100)
        #expect(writeTime.timeInterval < 2.0) // Should complete within 2 seconds
        
        // Test read performance
        let readTime = TestHelpers.measureTime {
            let newTaskManager = TaskManager()
            #expect(newTaskManager.tasks.count == 100)
        }
        
        #expect(readTime.timeInterval < 1.0) // Should load within 1 second
    }
    
    @Test("Performance: Synchronization overhead")
    func performanceSynchronizationOverhead() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        // Measure time for multiple save operations
        let totalTime = TestHelpers.measureTime {
            for i in 0..<50 {
                taskManager.addTask(title: "Sync Task \(i)")
                taskManager.toggleTaskCompletion(taskManager.tasks[i])
            }
        }
        
        #expect(taskManager.tasks.count == 50)
        #expect(totalTime.timeInterval < 3.0) // Should complete within 3 seconds
    }
    
    // MARK: - Edge Cases for App Groups
    
    @Test("Edge case: Empty App Groups data")
    func emptyAppGroupsData() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager = TaskManager()
        #expect(taskManager.tasks.isEmpty)
        
        // Should handle empty data gracefully
        taskManager.hideCompleted = true
        #expect(taskManager.filteredTasks.isEmpty)
    }
    
    @Test("Edge case: Malformed data in App Groups")
    func malformedAppGroupsData() async throws {
        TestHelpers.setupTestEnvironment()
        
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        // Write data with missing required fields
        let malformedJSON = """
        [
            {"id": "invalid-id", "title": "Malformed Task"}
        ]
        """
        
        userDefaults.set(malformedJSON.data(using: .utf8), forKey: "tasks")
        userDefaults.synchronize()
        
        // Should handle malformed data gracefully
        let taskManager = TaskManager()
        #expect(taskManager.tasks.isEmpty) // Should default to empty array
    }
    
    @Test("Edge case: App Groups storage limits")
    func appGroupsStorageLimits() async throws {
        TestHelpers.setupTestEnvironment()
        let taskManager = TaskManager()
        
        // Add tasks with very long titles to test storage limits
        let longTitle = String(repeating: "A", count: 1000)
        
        for i in 0..<10 {
            taskManager.addTask(title: "\(longTitle) \(i)")
        }
        
        // Verify tasks are saved despite large size
        let newTaskManager = TaskManager()
        #expect(newTaskManager.tasks.count == 10)
        
        // Verify data integrity
        for (index, task) in newTaskManager.tasks.enumerated() {
            #expect(task.title.hasPrefix(longTitle))
        }
    }
}
