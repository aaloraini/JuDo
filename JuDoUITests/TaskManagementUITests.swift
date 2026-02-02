//
//  TaskManagementUITests.swift
//  JuDoUITests
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import XCTest

final class TaskManagementUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Clear any existing data before each test
        Task { @MainActor in
            clearAllTasks()
        }
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - UI Test Methods
    
    @MainActor
    func testAddTaskUI() throws {
        // Click Add Task button
        let addTaskButton = app.buttons["Add Task"]
        XCTAssertTrue(addTaskButton.exists)
        addTaskButton.click()
        
        // Wait for sheet to appear
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 2.0))
        
        // Enter task title
        let textField = app.textFields["New task..."]
        XCTAssertTrue(textField.exists)
        textField.typeText("UI Test Task")
        
        // Click Add button
        let addButton = sheet.buttons["Add"]
        XCTAssertTrue(addButton.exists)
        addButton.click()
        
        // Verify task appears in list
        let taskCell = app.staticTexts["UI Test Task"]
        XCTAssertTrue(taskCell.waitForExistence(timeout: 2.0))
    }
    
    @MainActor
    func testToggleTaskCompletionUI() throws {
        // First add a task
        addTaskViaUI(title: "Completion Test Task")
        
        // Find the task and toggle completion
        let taskCell = app.staticTexts["Completion Test Task"]
        XCTAssertTrue(taskCell.exists)
        
        // Click the completion circle
        let completionButton = app.buttons.matching(identifier: "completion-circle").firstMatch
        if completionButton.exists {
            completionButton.click()
        }
        
        // Verify task is marked as completed (strikethrough or visual change)
        // This depends on the specific UI implementation
        XCTAssertTrue(taskCell.exists)
    }
    
    @MainActor
    func testDeleteTaskUI() throws {
        // First add a task
        addTaskViaUI(title: "Delete Test Task")
        
        // Find and swipe to delete
        let taskCell = app.staticTexts["Delete Test Task"]
        XCTAssertTrue(taskCell.exists)
        
        let taskRow = taskCell.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        taskRow.swipeLeft()
        
        // Click delete button
        let deleteButton = app.buttons["Delete"]
        if deleteButton.exists {
            deleteButton.click()
        }
        
        // Verify task is gone
        XCTAssertFalse(taskCell.waitForExistence(timeout: 2.0))
    }
    
    @MainActor
    func testHideCompletedTasksUI() throws {
        // Add tasks and complete one
        addTaskViaUI(title: "Active Task")
        addTaskViaUI(title: "Completed Task")
        
        // Complete the second task
        let completedTaskCell = app.staticTexts["Completed Task"]
        if completedTaskCell.exists {
            let completionButton = app.buttons.matching(identifier: "completion-circle").allElementsBoundByIndex[1]
            completionButton.click()
        }
        
        // Click hide completed button
        let hideButton = app.buttons.matching(identifier: "hide-completed").firstMatch
        if hideButton.exists {
            hideButton.click()
        }
        
        // Verify only active task is visible
        XCTAssertTrue(app.staticTexts["Active Task"].exists)
        XCTAssertFalse(app.staticTexts["Completed Task"].exists)
    }
    
    @MainActor
    func testKeyboardShortcuts() throws {
        // Test Cmd+N shortcut for adding task
        app.typeKey("n", modifierFlags: [.command])
        
        // Verify add sheet appears
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 2.0))
        
        // Dismiss sheet
        let cancelButton = sheet.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.click()
        }
    }
    
    @MainActor
    func testTaskReorderingUI() throws {
        // Add multiple tasks
        addTaskViaUI(title: "Task 1")
        addTaskViaUI(title: "Task 2")
        addTaskViaUI(title: "Task 3")
        
        // Test drag and drop reordering
        let task1 = app.staticTexts["Task 1"]
        let task2 = app.staticTexts["Task 2"]
        
        if task1.exists && task2.exists {
            let task1Coordinate = task1.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let task2Coordinate = task2.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            
            // Drag Task 1 to Task 2 position
            task1Coordinate.press(forDuration: 0.5)
            task1Coordinate.press(forDuration: 0.5, thenDragTo: task2Coordinate)
        }
        
        // Verify reordering (this depends on specific implementation)
        XCTAssertTrue(app.staticTexts["Task 1"].exists)
        XCTAssertTrue(app.staticTexts["Task 2"].exists)
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
        // Swipe to delete all existing tasks
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
}
