//
//  ErrorHandling.swift
//  JuDo
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Error Types

enum JuDoError: LocalizedError {
    case taskCreationFailed(String)
    case taskDeletionFailed(String)
    case taskUpdateFailed(String)
    case dataCorruption(String)
    case persistenceError(String)
    case widgetError(String)
    case appGroupsError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .taskCreationFailed(let message):
            return "Failed to create task: \(message)"
        case .taskDeletionFailed(let message):
            return "Failed to delete task: \(message)"
        case .taskUpdateFailed(let message):
            return "Failed to update task: \(message)"
        case .dataCorruption(let message):
            return "Data corruption detected: \(message)"
        case .persistenceError(let message):
            return "Failed to save data: \(message)"
        case .widgetError(let message):
            return "Widget error: \(message)"
        case .appGroupsError(let message):
            return "App Groups error: \(message)"
        case .unknownError(let message):
            return "Unexpected error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .taskCreationFailed:
            return "Please try again or restart the app if the problem persists."
        case .taskDeletionFailed:
            return "Please try again or check if the task still exists."
        case .taskUpdateFailed:
            return "Please try again or restart the app if the problem persists."
        case .dataCorruption:
            return "Please restart the app. If the problem continues, you may need to reinstall the app."
        case .persistenceError:
            return "Please check your storage space and try again."
        case .widgetError:
            return "Please try refreshing the widget or restart the app."
        case .appGroupsError:
            return "Please restart the app and ensure widgets have proper permissions."
        case .unknownError:
            return "Please restart the app and try again."
        }
    }
}

// MARK: - Error Manager

class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: JuDoError?
    @Published var showError = false
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: JuDoError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showError = true
            
            // Log the error for debugging
            self.logError(error)
        }
    }
    
    func handle(_ error: Error) {
        let juDoError: JuDoError
        
        if let juDoError = error as? JuDoError {
            self.handle(juDoError)
        } else {
            // Convert generic errors to JuDoError
            juDoError = .unknownError(error.localizedDescription)
            self.handle(juDoError)
        }
    }
    
    func dismissError() {
        currentError = nil
        showError = false
    }
    
    // MARK: - Logging
    
    private func logError(_ error: JuDoError) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] JuDoError: \(error.errorDescription ?? "Unknown error")"
        
        #if DEBUG
        print(logMessage)
        #endif
        
        // In a production app, you might send this to a logging service
        logToFile(logMessage)
    }
    
    private func logToFile(_ message: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFile = documentsDirectory.appendingPathComponent("judo_errors.log")
        
        do {
            let data = (message + "\n").data(using: .utf8) ?? Data()
            
            if FileManager.default.fileExists(atPath: logFile.path) {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: logFile)
            }
        } catch {
            // If we can't log to file, at least print to console
            print("Failed to write error to log file: \(error)")
        }
    }
}

// MARK: - Error Handling Extensions

extension TaskManager {
    func safeAddTask(title: String) {
        do {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw JuDoError.taskCreationFailed("Task title is empty")
            }
            
            addTask(title: title)
        } catch {
            ErrorManager.shared.handle(error)
        }
    }
    
    func safeDeleteTask(_ task: Task) {
        do {
            deleteTask(task)
        } catch {
            ErrorManager.shared.handle(JuDoError.taskDeletionFailed("Failed to delete task: \(task.title)"))
        }
    }
    
    func safeToggleTaskCompletion(_ task: Task) {
        do {
            guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
                throw JuDoError.taskUpdateFailed("Task not found")
            }
            
            toggleTaskCompletion(task)
        } catch {
            ErrorManager.shared.handle(JuDoError.taskUpdateFailed("Failed to toggle task completion"))
        }
    }
    
    func safeMoveTask(from source: IndexSet, to destination: Int) {
        moveTask(from: source, to: destination)
    }
}

// MARK: - Error View for SwiftUI

struct ErrorView: View {
    let error: JuDoError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.errorDescription ?? "An unknown error occurred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Report") {
                    // In a real app, you might implement error reporting
                    ErrorManager.shared.dismissError()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
