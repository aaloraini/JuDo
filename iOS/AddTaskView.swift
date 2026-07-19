import SwiftUI

struct AddTaskView: View {
    let taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedPriority: Priority? = nil
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isParentTask = false
    @State private var subtaskTitles: [String] = []
    @State private var newSubtaskTitle = ""
    @FocusState private var titleFocused: Bool

    private var pendingSubtaskTitles: [String] {
        guard isParentTask else { return [] }
        let pending = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return pending.isEmpty ? subtaskTitles : subtaskTitles + [pending]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                        .focused($titleFocused)
                        .onSubmit { submitIfValid() }
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

                Section {
                    Toggle("Parent Task with Subtasks", isOn: $isParentTask)
                    if isParentTask {
                        ForEach(subtaskTitles.indices, id: \.self) { index in
                            HStack(spacing: 10) {
                                Image(systemName: "circle")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                Text(subtaskTitles[index])
                            }
                        }
                        .onDelete { offsets in
                            subtaskTitles.remove(atOffsets: offsets)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                            TextField("Add subtask", text: $newSubtaskTitle)
                                .onSubmit { commitSubtask() }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submitIfValid() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { titleFocused = true }
        }
    }

    private func submitIfValid() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        taskManager.addTask(
            title: trimmed,
            priority: selectedPriority,
            dueDate: hasDueDate ? dueDate : nil,
            subtaskTitles: pendingSubtaskTitles
        )
        dismiss()
    }

    private func commitSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        subtaskTitles.append(trimmed)
        newSubtaskTitle = ""
    }
}
