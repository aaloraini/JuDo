import SwiftUI

struct AddTaskView: View {
    let taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedPriority: Priority? = nil
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @FocusState private var titleFocused: Bool

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
        taskManager.addTask(title: trimmed, priority: selectedPriority, dueDate: hasDueDate ? dueDate : nil)
        dismiss()
    }
}
