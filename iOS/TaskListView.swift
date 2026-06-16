import SwiftUI
import SwiftData

struct TaskListView: View {
    @StateObject private var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var searchQuery = ""
    @State private var showingClearConfirmation = false
    @State private var selectedTask: Task? = nil
    @State private var editMode: EditMode = .inactive
    @State private var showingSupport = false
    @State private var showingSync = false

    init(container: ModelContainer) {
        _taskManager = StateObject(wrappedValue: TaskManager(container: container))
    }

    var searchedIncompleteTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.incompleteTasks }
        return taskManager.incompleteTasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.notes?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    var searchedCompletedTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.completedTasks }
        return taskManager.completedTasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.notes?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if taskManager.tasks.isEmpty && searchQuery.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .navigationTitle("JuDo")
            .searchable(text: $searchQuery, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if taskManager.sortOption == .manual {
                            Button(editMode == .active ? "Done" : "Edit") {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSupport = true }) {
                        Image(systemName: "heart")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSync = true }) {
                        Image(systemName: "icloud")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Section("Sort by") {
                            ForEach(TaskSortOption.allCases, id: \.self) { option in
                                Button(action: { taskManager.sortOption = option }) {
                                    Label(option.rawValue,
                                          systemImage: taskManager.sortOption == option ? "checkmark" : "")
                                }
                            }
                        }
                        Divider()
                        Button(action: { taskManager.hideCompleted.toggle() }) {
                            Label(
                                taskManager.hideCompleted ? "Show Completed" : "Hide Completed",
                                systemImage: taskManager.hideCompleted ? "eye" : "eye.slash"
                            )
                        }
                        if taskManager.tasks.contains(where: { $0.isCompleted }) {
                            Button(role: .destructive, action: { showingClearConfirmation = true }) {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task, taskManager: taskManager)
            }
            .sheet(isPresented: $showingSupport) {
                SupportView()
            }
            .sheet(isPresented: $showingSync) {
                SyncStatusView()
            }
            .alert("Clear Completed Tasks", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    taskManager.clearCompletedTasks()
                }
            } message: {
                let count = taskManager.tasks.filter { $0.isCompleted }.count
                Text("Delete \(count) completed task\(count == 1 ? "" : "s")? This cannot be undone.")
            }
        }
    }

    private var taskList: some View {
        List {
            let incomplete = searchedIncompleteTasks
            let completed = searchedCompletedTasks

            if !incomplete.isEmpty {
                Section {
                    ForEach(incomplete) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTask = task }
                    }
                    .onMove { source, destination in
                        if taskManager.sortOption == .manual {
                            taskManager.moveTask(from: source, to: destination)
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { taskManager.deleteTask(incomplete[$0]) }
                    }
                }
            }

            if !taskManager.hideCompleted && !completed.isEmpty {
                Section("Completed") {
                    ForEach(completed) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTask = task }
                    }
                    .onDelete { offsets in
                        offsets.forEach { taskManager.deleteTask(completed[$0]) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
        .onChange(of: taskManager.sortOption) { _, newValue in
            if newValue != .manual { editMode = .inactive }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No tasks yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Tap + to add your first task.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Add Task") { showingAddTask = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
