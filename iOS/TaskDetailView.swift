import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedPriority: Priority?
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var notes: String
    @State private var showingDeleteConfirmation = false

    init(task: Task, taskManager: TaskManager) {
        self.task = task
        self.taskManager = taskManager
        _title           = State(initialValue: task.title)
        _selectedPriority = State(initialValue: task.priority)
        _hasDueDate      = State(initialValue: task.dueDate != nil)
        _dueDate         = State(initialValue: task.dueDate ?? Date())
        _notes           = State(initialValue: task.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                }

                Section("Priority") {
                    Picker("Priority", selection: $selectedPriority) {
                        Text("None").tag(Priority?.none)
                        Text("High").tag(Priority?.some(.high))
                        Text("Medium").tag(Priority?.some(.medium))
                        Text("Low").tag(Priority?.some(.low))
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    taskManager.deleteTask(task)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.title       = trimmed
        task.priority    = selectedPriority
        task.dueDate     = hasDueDate ? dueDate : nil
        task.notes       = notes.isEmpty ? nil : notes
        task.updatedAt   = Date()
        taskManager.saveTasks()
        dismiss()
    }
}
