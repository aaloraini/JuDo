//
//  ContentView.swift
//  TaskWidgetApp
//
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var store = TaskStore.shared
    @State private var newTaskText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingEmptyStateAnimation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("Tasks")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    // Stats badge
                    if totalCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(completedCount)/\(totalCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.1)))
                    }
                }
                
                // Add task section
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                    
                    TextField("What needs to be done?", text: $newTaskText)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .onSubmit(addTask)
                    
                    Button(action: addTask) {
                        Text("Add")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.windowBackgroundColor))
                )
            }
            .padding()
            
            Divider()
            
            // Control panel
            HStack {
                Toggle("Hide Completed", isOn: Binding(
                    get: { store.hideCompleted },
                    set: { newValue in
                        Task { await store.setHideCompleted(newValue) }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Spacer()
                
                Button(action: { store.refreshWidget() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Widget")
                    }
                    .font(.caption)
                    .controlSize(.small)
                }
                .buttonStyle(.bordered)
                .help("Force refresh the widget")
        }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Task list
            if store.visibleItems.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.visibleItems) { item in
                        TaskRow(
                            item: item,
                            onToggle: { Task {
                                await store.toggleDone(id: item.id)
                            } },
                            onDelete: { Task {
                                await store.deleteTask(id: item.id) } },
                            onRename: { newTitle in Task {
                                await store.updateTask(id: item.id, title: newTitle)} }
                        )
               /*         .contextMenu {
                            Button("Delete") {
                                Task {
                                    await store.deleteTask(id: item.id) }
                            }
                        } */
                    }
                    .onMove { indexSet, destination in
                        Task {
                            await store.reorderTasks(from: indexSet, to: destination)
                        }
                    }
                    .onDelete { indexSet in
                        let visible = store.visibleItems
                        for index in indexSet {Task {
                            await store.deleteTask(id: visible[index].id) }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {Task {
            await store.load() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await store.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusTaskField"))) { _ in
            isTextFieldFocused = true
        }
    }
    
    private var completedCount: Int {
        store.items.filter { $0.isDone }.count
    }
    
    private var totalCount: Int {
        store.items.count
    }
    
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
                .scaleEffect(showingEmptyStateAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showingEmptyStateAnimation)
            
            VStack(spacing: 8) {
                Text("No Tasks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first task using the field above")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { isTextFieldFocused = true }) {
                Label("Add a Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .onAppear {
            showingEmptyStateAnimation = true
        }
    }
    
    private func addTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { 
            alertMessage = "Please enter a task description"
            showingAlert = true
            return 
        }
        
        Task {
            await store.addTask(title: text) }
        newTaskText = ""
            }
}

struct TaskRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var draftTitle = ""
    @FocusState private var isEditorFocused: Bool
    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short   // e.g. 14 Dec 2025
        f.timeStyle = .short    // e.g. 8:45 PM
        return f
    }()


    var body: some View {
        HStack(spacing: 12) {
            // Drag handle (always visible)
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(width: 16, height: 16)
            
            Button {
                onToggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(item.isDone ? Color.green : Color.secondary.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if item.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(.borderless)   // ✅ REQUIRED on macOS List


            Group {
                if isEditing {
                    TextField("", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .focused($isEditorFocused)
                        .onSubmit(commitEdit)
                        .onExitCommand(perform: cancelEdit)
                        .onAppear {
                            // Ensure focus is applied when the field appears
                            DispatchQueue.main.async { isEditorFocused = true }
                        }
                } else {
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.isDone, pattern: .solid, color: .secondary)
                        .foregroundColor(item.isDone ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())            // ✅ makes the whole title area clickable
            .onTapGesture(count: 2) {             // ✅ double click works reliably now
                startEdit()
            }

            Spacer()

            if isHovering && !isEditing {
                Text(Self.timestampFormatter.string(from: item.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }

            // Delete button (visible on hover, always accessible without right-click)
            if isHovering && !isEditing {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .imageScale(.small)
                }
                .buttonStyle(.borderless)
                .help("Delete")
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        //.contentShape(Rectangle())
        .contextMenu {
            Button("Rename") { startEdit() }
        }
        .onAppear {
            draftTitle = item.title
        }
        .onChange(of: isEditorFocused) { _, focused in
            if !focused && isEditing {
                commitEdit()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private func startEdit() {
        draftTitle = item.title
        isEditing = true
        DispatchQueue.main.async {
            isEditorFocused = true
        }
    }

    private func commitEdit() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false

        guard !trimmed.isEmpty else {
            draftTitle = item.title
            return
        }

        onRename(trimmed)
    }

    private func cancelEdit() {
        isEditing = false
        draftTitle = item.title
    }
}
