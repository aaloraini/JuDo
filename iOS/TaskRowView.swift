import SwiftUI

struct TaskRowView: View {
    let task: Task
    let taskManager: TaskManager

    private var priorityColor: Color? {
        switch task.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .gray
        case nil:     return nil
        }
    }

    private var dueDateLabel: String? {
        guard let dueDate = task.dueDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        if calendar.isDateInToday(dueDate)     { return "Today" }
        if calendar.isDateInTomorrow(dueDate)  { return "Tomorrow" }
        if calendar.isDateInYesterday(dueDate) { return "Yesterday" }
        if dueDate < now {
            let days = calendar.dateComponents([.day], from: dueDate, to: now).day ?? 0
            return "\(days)d overdue"
        }
        let days = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0
        if days <= 7 {
            let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: dueDate)
        }
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: dueDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? Color.accentColor : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let color = priorityColor {
                        Circle().fill(color).frame(width: 7, height: 7)
                    }
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                }

                if let label = dueDateLabel {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : (task.isDueToday ? .orange : .secondary))
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
