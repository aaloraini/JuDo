//
//  ContentView.swift
//  JuDo
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @StateObject private var errorManager = ErrorManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            taskListContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(
                taskTitle: $newTaskTitle,
                onAdd: addTask,
                onCancel: { 
                    newTaskTitle = ""
                    showingAddTask = false 
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .addTaskFromWidget)) { _ in
            showingAddTask = true
        }
        .alert("Error", isPresented: $errorManager.showError) {
            Button("OK") {
                errorManager.dismissError()
            }
        } message: {
            if let error = errorManager.currentError {
                Text(error.errorDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private var taskListContent: some View {
        VStack(spacing: 0) {
            // Task list with native styling
            List {
                ForEach(taskManager.filteredTasks) { task in
                    TaskRow(task: task, taskManager: taskManager)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                }
                .onMove { source, destination in
                    taskManager.safeMoveTask(from: source, to: destination)
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
            .scrollContentBackground(.hidden)
        }
        .safeAreaInset(edge: .top) {
            // Native toolbar
            HStack(spacing: 16) {
                Button(action: {
                    showingAddTask = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button(action: {
                    taskManager.hideCompleted.toggle()
                }) {
                    Image(systemName: taskManager.hideCompleted ? "eye" : "eye.slash")
                        .help(taskManager.hideCompleted ? "Show Completed" : "Hide Completed")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                VisualEffectView(material: .titlebar)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.separatorColor),
                        alignment: .bottom
                    )
            )
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for offset in offsets {
            taskManager.safeDeleteTask(taskManager.filteredTasks[offset])
        }
    }
    
    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { 
            ErrorManager.shared.handle(JuDoError.taskCreationFailed("Task title cannot be empty"))
            return
        }
        
        taskManager.safeAddTask(title: trimmedTitle)
        newTaskTitle = ""
        showingAddTask = false
    }
}

struct TaskRow: View {
    let task: Task
    let taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                taskManager.safeToggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .accentColor : .secondary)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 20, height: 20)
            
            Text(task.title)
                .font(.system(size: 15))
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
}

struct AddTaskSheet: View {
    @Binding var taskTitle: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Task")
                .font(.title2)
                .fontWeight(.medium)
            
            TextField("New task...", text: $taskTitle)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 15))
                .onSubmit {
                    if !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onAdd()
                    }
                }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button("Add") {
                    onAdd()
                }
                .keyboardShortcut(.return)
                .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// Helper for system materials
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.state = .active
        visualEffectView.isEmphasized = false
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// Helper for separator color
extension Color {
    static let separatorColor = Color(NSColor.separatorColor)
}

#Preview {
    ContentView()
}
