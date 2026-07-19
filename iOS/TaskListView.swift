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
    @State private var expandedTasks: Set<UUID> = []
    @State private var taskPendingDelete: Task? = nil

    init(container: ModelContainer) {
        _taskManager = StateObject(wrappedValue: TaskManager(container: container))
    }

    var searchedIncompleteTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.incompleteTasks }
        return taskManager.incompleteTasks.filter { taskManager.matches($0, query: searchQuery) }
    }

    var searchedCompletedTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.completedTasks }
        return taskManager.completedTasks.filter { taskManager.matches($0, query: searchQuery) }
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
                        Image(systemName: SyncManager.shared.status.symbolName)
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
                        if !taskManager.completedTasks.isEmpty {
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
                let completed = taskManager.completedTasks
                let hasChildren = completed.contains { taskManager.hasSubtasks($0) }
                Text("Delete \(completed.count) completed task\(completed.count == 1 ? "" : "s")\(hasChildren ? " and their subtasks" : "")? This cannot be undone.")
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: Binding(
                    get: { taskPendingDelete != nil },
                    set: { if !$0 { taskPendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: taskPendingDelete
            ) { task in
                Button("Delete", role: .destructive) {
                    taskManager.deleteTask(task)
                }
                Button("Cancel", role: .cancel) { }
            } message: { task in
                let count = taskManager.subtasks(of: task).count
                Text("\"\(task.title)\" has \(count) subtask\(count == 1 ? "" : "s") that will also be deleted.")
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
                        taskRowGroup(for: task)
                    }
                    .onMove { source, destination in
                        if taskManager.sortOption == .manual {
                            taskManager.moveTask(from: source, to: destination)
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { requestDelete(incomplete[$0]) }
                    }
                }
            }

            if !taskManager.hideCompleted && !completed.isEmpty {
                Section("Completed") {
                    ForEach(completed) { task in
                        taskRowGroup(for: task)
                    }
                    .onDelete { offsets in
                        offsets.forEach { requestDelete(completed[$0]) }
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

    @ViewBuilder
    private func taskRowGroup(for task: Task) -> some View {
        if taskManager.hasSubtasks(task) || expandedTasks.contains(task.id) {
            DisclosureGroup(isExpanded: expansionBinding(for: task)) {
                let children = taskManager.subtasks(of: task)
                ForEach(children) { subtask in
                    TaskRowView(task: subtask, taskManager: taskManager)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTask = subtask }
                        .contextMenu {
                            Button { selectedTask = subtask } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) { requestDelete(subtask) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove { source, destination in
                    taskManager.moveSubtask(of: task, from: source, to: destination)
                }
                .onDelete { offsets in
                    offsets.forEach { requestDelete(children[$0]) }
                }
                AddSubtaskField { title in
                    taskManager.addSubtask(to: task, title: title)
                }
            } label: {
                taskRowLabel(for: task)
            }
        } else {
            taskRowLabel(for: task)
        }
    }

    private func taskRowLabel(for task: Task) -> some View {
        TaskRowView(task: task, taskManager: taskManager)
            .contentShape(Rectangle())
            .onTapGesture { selectedTask = task }
            .contextMenu {
                Button { selectedTask = task } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) { requestDelete(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private func expansionBinding(for task: Task) -> Binding<Bool> {
        Binding(
            get: { expandedTasks.contains(task.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedTasks.insert(task.id)
                } else {
                    expandedTasks.remove(task.id)
                }
            }
        )
    }

    private func requestDelete(_ task: Task) {
        if taskManager.hasSubtasks(task) {
            taskPendingDelete = task
        } else {
            taskManager.deleteTask(task)
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

// MARK: - AddSubtaskField

struct AddSubtaskField: View {
    @State private var title = ""
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)

            TextField("Add subtask", text: $title)
                .onSubmit {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSubmit(trimmed)
                    title = ""
                }
        }
    }
}
