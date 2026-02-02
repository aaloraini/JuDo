//
//  WidgetUITests.swift
//  JuDoUITests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import XCTest
import WidgetKit

final class WidgetUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Clear existing data
        clearAllTasks()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Widget UI Tests
    
    @MainActor
    func testWidgetDataSynchronization() throws {
        // Add task in main app
        addTaskViaUI(title: "Widget Sync Test")
        
        // Simulate widget refresh (in real scenario, this would involve Notification Center)
        // For now, we'll verify the data is available in App Groups
        verifyTaskInAppGroups(title: "Widget Sync Test")
    }
    
    @MainActor
    func testWidgetURLScheme() throws {
        // Test URL scheme for adding tasks from widget
        let url = URL(string: "judo://add")
        
        if let url = url {
            // In a real test, you would use XCUIApplication.open(url)
            // For now, we'll verify the URL scheme is properly formatted
            XCTAssertEqual(url.scheme, "judo")
            XCTAssertEqual(url.host, "add")
        }
    }
    
    @MainActor
    func testWidgetPerformanceRequirement() throws {
        // Measure widget data loading performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate widget data loading
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Add test data
            for i in 0..<50 {
                addTaskViaUI(title: "Performance Task \(i)")
            }
            
            // Simulate widget reading data
            verifyTaskInAppGroups(title: "Performance Task 0")
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            // Verify 3-second requirement
            XCTAssertLessThan(duration, 3.0, "Widget data loading should complete within 3 seconds")
        }
    }
    
    @MainActor
    func testWidgetTaskLimits() throws {
        // Add more tasks than widget limits
        for i in 0..<15 {
            addTaskViaUI(title: "Widget Limit Task \(i)")
        }
        
        // Verify data is available for widget processing
        verifyTaskInAppGroups(title: "Widget Limit Task 0")
        verifyTaskInAppGroups(title: "Widget Limit Task 14")
        
        // Widget should limit to 5 (medium) and 8 (large) tasks
        // This would be tested in actual widget implementation
    }
    
    @MainActor
    func testWidgetErrorHandling() throws {
        // Test widget behavior with corrupted data
        // This would involve simulating data corruption scenarios
        
        // For now, verify normal operation
        addTaskViaUI(title: "Error Test Task")
        verifyTaskInAppGroups(title: "Error Test Task")
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func addTaskViaUI(title: String) {
        let addTaskButton = app.buttons["Add Task"]
        addTaskButton.click()
        
        let sheet = app.sheets.firstMatch
        sheet.waitForExistence(timeout: 2.0)
        
        let textField = app.textFields["New task..."]
        textField.typeText(title)
        
        let addButton = sheet.buttons["Add"]
        addButton.click()
    }
    
    @MainActor
    private func clearAllTasks() {
        let appCells = app.cells.allElementsBoundByIndex
        
        for cell in appCells.reversed() {
            if cell.exists {
                cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).swipeLeft()
                
                let deleteButton = app.buttons["Delete"]
                if deleteButton.exists {
                    deleteButton.click()
                }
            }
        }
    }
    
    private func verifyTaskInAppGroups(title: String) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.aloraini.JuDo") else {
            XCTFail("Could not access App Groups UserDefaults")
            return
        }
        
        guard let tasksData = userDefaults.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) else {
            XCTFail("Could not read tasks from App Groups")
            return
        }
        
        XCTAssertTrue(tasks.contains { $0.title == title }, "Task '\(title)' should be available in App Groups")
    }
}
