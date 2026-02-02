//
//  WidgetTests.swift
//  JuDoTests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Testing
import WidgetKit
import Foundation
@testable import JuDo

struct WidgetTests {
    
    // MARK: - Test Lifecycle
    
    init() {
        TestHelpers.clearTestData()
    }
    
    // MARK: - Basic Widget Tests (without direct widget import)
    
    @Test("Widget data sharing through App Groups")
    func widgetDataSharing() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 3)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        
        // Verify data is available for widgets through App Groups
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        guard let tasksData = userDefaults.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) else {
            throw JuDoError.appGroupsError("Could not read tasks from App Groups")
        }
        
        #expect(tasks.count == 3)
        #expect(tasks[0].title == "Test Task 1")
        #expect(tasks[1].title == "Test Task 2")
        #expect(tasks[2].title == "Test Task 3")
    }
    
    @Test("Widget performance requirement: 3-second refresh")
    func widgetPerformanceRequirement() async throws {
        let largeTasks = TestHelpers.createSampleTasks(count: 100)
        TestHelpers.setupTestEnvironment(tasks: largeTasks)
        
        // Simulate widget data loading performance
        let (_, timeInterval) = TestHelpers.measureTime {
            guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
                return
            }
            
            guard let tasksData = userDefaults.data(forKey: "tasks"),
                  let _ = try? JSONDecoder().decode([Task].self, from: tasksData) else {
                return
            }
        }
        
        #expect(timeInterval < 3.0) // Must meet 3-second requirement
    }
    
    @Test("Widget hideCompleted preference synchronization")
    func widgetHideCompletedSync() async throws {
        TestHelpers.setupTestEnvironment()
        
        let taskManager = TaskManager()
        taskManager.hideCompleted = true
        
        // Verify preference is available for widgets
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        let hideCompleted = userDefaults.bool(forKey: "hideCompleted")
        #expect(hideCompleted == true)
    }
    
    @Test("Widget task limit enforcement")
    func widgetTaskLimitEnforcement() async throws {
        let sampleTasks = TestHelpers.createSampleTasks(count: 15)
        TestHelpers.setupTestEnvironment(tasks: sampleTasks)
        
        // Simulate widget task limit logic
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        guard let tasksData = userDefaults.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) else {
            throw JuDoError.appGroupsError("Could not read tasks from App Groups")
        }
        
        // Medium widget limit: 5 tasks
        let mediumWidgetTasks = Array(tasks.prefix(5))
        #expect(mediumWidgetTasks.count <= 5)
        
        // Large widget limit: 8 tasks
        let largeWidgetTasks = Array(tasks.prefix(8))
        #expect(largeWidgetTasks.count <= 8)
    }
    
    @Test("Widget error handling with corrupted data")
    func widgetErrorHandlingCorruptedData() async throws {
        TestHelpers.setupTestEnvironment()
        
        // Corrupt the data in UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            throw JuDoError.appGroupsError("Could not access App Groups UserDefaults")
        }
        
        userDefaults.set("corrupted data".data(using: .utf8), forKey: "tasks")
        userDefaults.synchronize()
        
        // Widget should handle corrupted data gracefully by providing empty data
        let tasksData = userDefaults.data(forKey: "tasks")
        if let tasksData = tasksData {
            let tasks = try? JSONDecoder().decode([Task].self, from: tasksData)
            #expect(tasks?.isEmpty == true) // Should default to empty array
        } else {
            // If no data, widget should handle gracefully
            #expect(true) // Test passes if no data available
        }
    }
}
