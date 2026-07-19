import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @StateObject private var errorManager = ErrorManager.shared
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @FocusState private var searchFieldFocused: Bool
    @State private var showingClearConfirmation = false
    @State private var showingSupport = false
    @State private var showingSync = false
    @State private var editingTask: Task? = nil
    @State private var expandedTasks: Set<UUID> = []
    @State private var taskPendingDelete: Task? = nil

    init(container: ModelContainer) {
        _taskManager = StateObject(wrappedValue: TaskManager(container: container))
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbarContent
            taskListContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(
                taskTitle: $newTaskTitle,
                onAdd: { priority, dueDate, subtaskTitles in
                    addTask(priority: priority, dueDate: dueDate, subtaskTitles: subtaskTitles)
                },
                onCancel: {
                    newTaskTitle = ""
                    showingAddTask = false
                }
            )
        }
        .sheet(item: $editingTask) { task in
            EditTaskSheet(task: task, taskManager: taskManager)
        }
        .sheet(isPresented: $showingSupport) {
            SupportView()
        }
        .sheet(isPresented: $showingSync) {
            SyncStatusView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addTaskFromWidget)) { _ in
            showingAddTask = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSearch)) { _ in
            showingSearch = true
        }
        .onChange(of: showingSearch) { _, newValue in
            searchFieldFocused = newValue
        }
        .alert("Error", isPresented: $errorManager.showError) {
            Button("OK") { errorManager.dismissError() }
        } message: {
            if let error = errorManager.currentError {
                Text(error.errorDescription ?? "An unknown error occurred")
            }
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
        .alert(
            "Delete Task",
            isPresented: Binding(
                get: { taskPendingDelete != nil },
                set: { if !$0 { taskPendingDelete = nil } }
            ),
            presenting: taskPendingDelete
        ) { task in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                taskManager.safeDeleteTask(task)
            }
        } message: { task in
            let count = taskManager.subtasks(of: task).count
            Text("\"\(task.title)\" has \(count) subtask\(count == 1 ? "" : "s") that will also be deleted.")
        }
    }

    var searchedIncompleteTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.incompleteTasks }
        return taskManager.incompleteTasks.filter { taskManager.matches($0, query: searchQuery) }
    }

    var searchedCompletedTasks: [Task] {
        guard !searchQuery.isEmpty else { return taskManager.completedTasks }
        return taskManager.completedTasks.filter { taskManager.matches($0, query: searchQuery) }
    }

    private var toolbarContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { showingAddTask = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                if showingSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))

                        TextField("Search tasks...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .focused($searchFieldFocused)
                            .frame(width: 200)

                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            showingSearch = false
                            searchQuery = ""
                            searchFieldFocused = false
                        }) {
                            Text("Done").font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                } else {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .help("Search tasks")
                }

                Menu {
                    ForEach(TaskSortOption.allCases, id: \.self) { option in
                        Button(action: { taskManager.sortOption = option }) {
                            HStack {
                                Text(option.rawValue)
                                if taskManager.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(taskManager.sortOption.rawValue)
                    }
                }
                .buttonStyle(.bordered)
                .help("Sort tasks")

                Button(action: { taskManager.hideCompleted.toggle() }) {
                    Image(systemName: taskManager.hideCompleted ? "eye" : "eye.slash")
                        .help(taskManager.hideCompleted ? "Show Completed" : "Hide Completed")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    if !taskManager.completedTasks.isEmpty {
                        showingClearConfirmation = true
                    }
                }) {
                    Image(systemName: "trash").help("Clear Completed Tasks")
                }
                .buttonStyle(.bordered)
                .disabled(taskManager.completedTasks.isEmpty)

                Button(action: { showingSync = true }) {
                    Image(systemName: SyncManager.shared.status.symbolName).help("iCloud Sync")
                }
                .buttonStyle(.bordered)

                Button(action: { showingSupport = true }) {
                    Image(systemName: "heart").help("Support JuDo")
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

    private var taskListContent: some View {
        let incomplete = searchedIncompleteTasks
        let completed = searchedCompletedTasks
        let showsCompleted = !taskManager.hideCompleted && !completed.isEmpty
        let hasTasks = !incomplete.isEmpty || showsCompleted

        return Group {
            if hasTasks {
                List {
                    if !incomplete.isEmpty {
                        ForEach(incomplete) { task in
                            taskRowGroup(for: task)
                                .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 16))
                        }
                        .onMove(perform: taskManager.sortOption == .manual && searchQuery.isEmpty
                            ? { source, destination in moveIncompleteTasks(from: source, to: destination) }
                            : nil
                        )
                        .onDelete { offsets in
                            offsets.forEach { requestDelete(incomplete[$0]) }
                        }
                    }

                    if !taskManager.hideCompleted && !completed.isEmpty {
                        Section(header: Text("Completed").font(.caption).foregroundColor(.secondary)) {
                            ForEach(completed) { task in
                                taskRowGroup(for: task)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 16))
                            }
                            .onDelete { offsets in
                                offsets.forEach { requestDelete(completed[$0]) }
                            }
                        }
                    }
                }
            } else {
                emptyStateContent
            }
        }
    }

    @ViewBuilder
    private func taskRowGroup(for task: Task) -> some View {
        if taskManager.hasSubtasks(task) || expandedTasks.contains(task.id) {
            DisclosureGroup(isExpanded: expansionBinding(for: task)) {
                let children = taskManager.subtasks(of: task)
                ForEach(children) { subtask in
                    SubtaskRow(
                        task: subtask,
                        taskManager: taskManager,
                        onEdit: { editingTask = subtask },
                        onDelete: { requestDelete(subtask) }
                    )
                }
                .onMove { source, destination in
                    taskManager.moveSubtask(of: task, from: source, to: destination)
                }
                .onDelete { offsets in
                    offsets.forEach { requestDelete(children[$0]) }
                }
                AddSubtaskRow { title in
                    taskManager.safeAddSubtask(to: task, title: title)
                }
            } label: {
                taskRowLabel(for: task)
            }
        } else {
            taskRowLabel(for: task)
        }
    }

    private func taskRowLabel(for task: Task) -> some View {
        TaskRow(
            task: task,
            taskManager: taskManager,
            onEdit: { editingTask = task },
            onDelete: { requestDelete(task) }
        )
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
            taskManager.safeDeleteTask(task)
        }
    }

    private var emptyStateContent: some View {
        let isSearching = !searchQuery.isEmpty
        let hasCompleted = !taskManager.completedTasks.isEmpty
        let title: String
        let message: String
        let symbol: String

        if isSearching {
            title = "No results"
            message = "Try a different search or clear the filter."
            symbol = "magnifyingglass"
        } else if taskManager.hideCompleted && hasCompleted {
            title = "All tasks completed"
            message = "Completed tasks are hidden."
            symbol = "checkmark.circle"
        } else {
            title = "No tasks yet"
            message = "Add your first task to get started."
            symbol = "tray"
        }

        return VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            if isSearching {
                Button("Clear Search") { searchQuery = "" }.buttonStyle(.bordered)
            } else if taskManager.hideCompleted && hasCompleted {
                Button("Show Completed") { taskManager.hideCompleted = false }.buttonStyle(.bordered)
            } else {
                Button("Add Task") { showingAddTask = true }.buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func moveIncompleteTasks(from source: IndexSet, to destination: Int) {
        taskManager.moveTask(from: source, to: destination)
    }

    private func addTask(priority: Priority?, dueDate: Date?, subtaskTitles: [String]) {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ErrorManager.shared.handle(JuDoError.taskCreationFailed("Task title cannot be empty"))
            return
        }
        taskManager.safeAddTask(title: trimmed, priority: priority, dueDate: dueDate, subtaskTitles: subtaskTitles)
        newTaskTitle = ""
        showingAddTask = false
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: Task
    let taskManager: TaskManager
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var priorityColor: Color? {
        switch task.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .gray
        case nil:     return nil
        }
    }

    var dueDateText: String? {
        guard let dueDate = task.dueDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        if calendar.isDateInToday(dueDate)     { return "Today" }
        if calendar.isDateInTomorrow(dueDate)  { return "Tomorrow" }
        if calendar.isDateInYesterday(dueDate) { return "Yesterday" }
        if dueDate < now {
            let days = calendar.dateComponents([.day], from: dueDate, to: now).day ?? 0
            return "\(days)d ago"
        }
        let days = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0
        if days <= 7 {
            let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: dueDate)
        }
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: dueDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            if taskManager.sortOption == .manual {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                    .help("Drag to reorder")
            }

            Button(action: { taskManager.safeToggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .accentColor : .secondary)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 20, height: 20)

            if let color = priorityColor {
                Circle().fill(color).frame(width: 6, height: 6)
            }

            Text(task.title)
                .font(.system(size: 15))
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let progress = taskManager.subtaskProgress(of: task) {
                HStack(spacing: 4) {
                    Image(systemName: "checklist").font(.system(size: 11))
                    Text("\(progress.done)/\(progress.total)").font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)))
            }

            if let dateText = dueDateText, !task.isOverdue && !task.isDueToday {
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)))
            }

            if task.isOverdue {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12)).foregroundColor(.red)
                    Text("Overdue").font(.system(size: 11)).foregroundColor(.red)
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.1)))
            } else if task.isDueToday {
                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.orange)
                    Text("Today").font(.system(size: 11)).foregroundColor(.orange)
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.1)))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture { onEdit?() }
        .contextMenu {
            Button { onEdit?() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete?() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
    }
}

// MARK: - SubtaskRow

struct SubtaskRow: View {
    let task: Task
    let taskManager: TaskManager
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.safeToggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .accentColor : .secondary)
                    .font(.system(size: 15))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 18, height: 18)

            Text(task.title)
                .font(.system(size: 13))
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture { onEdit?() }
        .contextMenu {
            Button { onEdit?() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete?() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor).opacity(0.3)))
    }
}

// MARK: - AddSubtaskRow

struct AddSubtaskRow: View {
    @State private var title = ""
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 18)

            TextField("Add subtask...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSubmit(trimmed)
                    title = ""
                }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
    }
}

// MARK: - AddTaskSheet

struct AddTaskSheet: View {
    @Binding var taskTitle: String
    @State private var selectedPriority: Priority? = nil
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isParentTask: Bool = false
    @State private var subtaskTitles: [String] = []
    @State private var newSubtaskTitle: String = ""
    @FocusState private var titleFieldFocused: Bool

    let onAdd: (Priority?, Date?, [String]) -> Void
    let onCancel: () -> Void

    private var pendingSubtaskTitles: [String] {
        guard isParentTask else { return [] }
        let pending = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return pending.isEmpty ? subtaskTitles : subtaskTitles + [pending]
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Task").font(.title2).fontWeight(.medium)

            TextField("New task...", text: $taskTitle)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 15))
                .focused($titleFieldFocused)
                .onSubmit {
                    if !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onAdd(selectedPriority, hasDueDate ? dueDate : nil, pendingSubtaskTitles)
                    }
                }
                .onAppear { titleFieldFocused = true }

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority").font(.system(size: 13)).foregroundColor(.secondary)
                Picker("Priority", selection: $selectedPriority) {
                    Text("None").tag(Priority?.none)
                    Text("🔴 High").tag(Priority?.some(.high))
                    Text("🟠 Medium").tag(Priority?.some(.medium))
                    Text("⚪️ Low").tag(Priority?.some(.low))
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Set Due Date", isOn: $hasDueDate).font(.system(size: 13))
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Parent Task with Subtasks", isOn: $isParentTask).font(.system(size: 13))
                if isParentTask {
                    ForEach(subtaskTitles.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            Text(subtaskTitles[index]).font(.system(size: 13))
                            Spacer()
                            Button(action: { subtaskTitles.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 4)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Add subtask...", text: $newSubtaskTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit { commitSubtask() }
                    }
                    .padding(.leading, 4)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { onCancel() }.keyboardShortcut(.escape)
                Button("Add") { onAdd(selectedPriority, hasDueDate ? dueDate : nil, pendingSubtaskTitles) }
                    .keyboardShortcut(.return)
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func commitSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        subtaskTitles.append(trimmed)
        newSubtaskTitle = ""
    }
}

// MARK: - EditTaskSheet

struct EditTaskSheet: View {
    let task: Task
    let taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedPriority: Priority?
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isParentTask: Bool
    @State private var existingSubtasks: [Task]
    @State private var removedSubtaskIds: Set<UUID> = []
    @State private var newSubtaskTitles: [String] = []
    @State private var newSubtaskTitle: String = ""
    @FocusState private var titleFieldFocused: Bool

    init(task: Task, taskManager: TaskManager) {
        self.task = task
        self.taskManager = taskManager
        _title            = State(initialValue: task.title)
        _selectedPriority = State(initialValue: task.priority)
        _hasDueDate       = State(initialValue: task.dueDate != nil)
        _dueDate          = State(initialValue: task.dueDate ?? Date())
        let children = taskManager.subtasks(of: task)
        _existingSubtasks = State(initialValue: children)
        _isParentTask     = State(initialValue: !children.isEmpty)
    }

    private var pendingSubtaskTitles: [String] {
        guard isParentTask else { return [] }
        let pending = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return pending.isEmpty ? newSubtaskTitles : newSubtaskTitles + [pending]
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Task").font(.title2).fontWeight(.medium)

            TextField("Task title...", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 15))
                .focused($titleFieldFocused)
                .onSubmit { saveChanges() }
                .onAppear { titleFieldFocused = true }

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority").font(.system(size: 13)).foregroundColor(.secondary)
                Picker("Priority", selection: $selectedPriority) {
                    Text("None").tag(Priority?.none)
                    Text("🔴 High").tag(Priority?.some(.high))
                    Text("🟠 Medium").tag(Priority?.some(.medium))
                    Text("⚪️ Low").tag(Priority?.some(.low))
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Set Due Date", isOn: $hasDueDate).font(.system(size: 13))
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }

            if task.parentId == nil {
                VStack(alignment: .leading, spacing: 8) {
                    if existingSubtasks.isEmpty && newSubtaskTitles.isEmpty {
                        Toggle("Parent Task with Subtasks", isOn: $isParentTask).font(.system(size: 13))
                    } else {
                        Text("Subtasks").font(.system(size: 13)).foregroundColor(.secondary)
                    }

                    if isParentTask {
                        ForEach(existingSubtasks.filter { !removedSubtaskIds.contains($0.id) }) { subtask in
                            HStack(spacing: 8) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(subtask.isCompleted ? .accentColor : .secondary)
                                Text(subtask.title)
                                    .font(.system(size: 13))
                                    .strikethrough(subtask.isCompleted)
                                    .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                                Spacer()
                                Button(action: { removedSubtaskIds.insert(subtask.id) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading, 4)
                        }

                        ForEach(newSubtaskTitles.indices, id: \.self) { index in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                Text(newSubtaskTitles[index]).font(.system(size: 13))
                                Spacer()
                                Button(action: { newSubtaskTitles.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading, 4)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField("Add subtask...", text: $newSubtaskTitle)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .onSubmit { commitSubtask() }
                        }
                        .padding(.leading, 4)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.escape)
                Button("Save") { saveChanges() }
                    .keyboardShortcut(.return)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func commitSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        newSubtaskTitles.append(trimmed)
        newSubtaskTitle = ""
    }

    private func saveChanges() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.title     = trimmed
        task.priority  = selectedPriority
        task.dueDate   = hasDueDate ? dueDate : nil
        task.updatedAt = Date()
        for id in removedSubtaskIds {
            if let subtask = existingSubtasks.first(where: { $0.id == id }) {
                taskManager.deleteTask(subtask)
            }
        }
        for subtaskTitle in pendingSubtaskTitles {
            taskManager.addSubtask(to: task, title: subtaskTitle)
        }
        taskManager.saveTasks()
        dismiss()
    }
}

// MARK: - Helpers

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.state = .active
        v.isEmphasized = false
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

extension Color {
    static let separatorColor = Color(NSColor.separatorColor)
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Task.self, configurations: config)
    return ContentView(container: container)
}
