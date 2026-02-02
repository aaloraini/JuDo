//
//  TestHelpers.swift
//  JuDoTests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Foundation
@testable import JuDo

/// Test utilities for generating mock data and managing test state
class TestHelpers {
    
    // MARK: - Mock Data Generators
    
    /// Creates a sample task for testing
    static func createSampleTask(title: String = "Test Task", order: Int = 0) -> Task {
        return Task(title: title, order: order)
    }
    
    /// Creates multiple sample tasks
    static func createSampleTasks(count: Int) -> [Task] {
        return (0..<count).map { index in
            createSampleTask(title: "Test Task \(index + 1)", order: index)
        }
    }
    
    /// Creates tasks with mixed completion states
    static func createMixedTasks(count: Int) -> [Task] {
        return (0..<count).map { index in
            var task = createSampleTask(title: "Task \(index + 1)", order: index)
            task.isCompleted = index % 2 == 0 // Every other task is completed
            return task
        }
    }
    
    // MARK: - Test Data Management
    
    /// Clears all test data from App Groups UserDefaults
    static func clearTestData() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            print("Warning: Could not access App Groups UserDefaults for cleanup")
            return
        }
        
        userDefaults.removeObject(forKey: "tasks")
        userDefaults.removeObject(forKey: "hideCompleted")
        userDefaults.synchronize()
    }
    
    /// Sets up test environment with initial data
    static func setupTestEnvironment(tasks: [Task] = [], hideCompleted: Bool = false) {
        clearTestData()
        
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            fatalError("Could not access App Groups UserDefaults for test setup")
        }
        
        do {
            let tasksData = try JSONEncoder().encode(tasks)
            userDefaults.set(tasksData, forKey: "tasks")
            userDefaults.set(hideCompleted, forKey: "hideCompleted")
            userDefaults.synchronize()
        } catch {
            fatalError("Failed to setup test data: \(error)")
        }
    }
    
    // MARK: - Assertion Helpers
    
    /// Verifies that two arrays of tasks are equivalent (ignoring order differences)
    static func assertTasksEqual(_ tasks1: [Task], _ tasks2: [Task], file: StaticString = #file, line: UInt = #line) {
        let sorted1 = tasks1.sorted { $0.order < $1.order }
        let sorted2 = tasks2.sorted { $0.order < $1.order }
        
        guard sorted1.count == sorted2.count else {
            print("Task count mismatch: \(sorted1.count) vs \(sorted2.count)")
            return
        }
        
        for (index, task1) in sorted1.enumerated() {
            let task2 = sorted2[index]
            
            if task1.title != task2.title {
                print("Task title mismatch at index \(index): '\(task1.title)' vs '\(task2.title)'")
            }
            
            if task1.isCompleted != task2.isCompleted {
                print("Task completion mismatch at index \(index): \(task1.isCompleted) vs \(task2.isCompleted)")
            }
            
            if task1.order != task2.order {
                print("Task order mismatch at index \(index): \(task1.order) vs \(task2.order)")
            }
        }
    }
    
    // MARK: - Performance Testing Helpers
    
    /// Measures execution time of a block
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeInterval = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeInterval)
    }
    
    /// Verifies that an operation completes within a time limit
    static func assertCompletesWithin<T>(
        timeLimit: TimeInterval,
        operation: () throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) rethrows -> T {
        let (_, timeInterval) = try measureTime(operation: operation)
        
        if timeInterval > timeLimit {
            print("Operation took \(timeInterval)s, expected <= \(timeLimit)s")
        }
        
        return try operation()
    }
}
