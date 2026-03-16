import SwiftUI

struct TasksView: View {
    @ObservedObject var store: AppStore
    @State private var newTaskText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input field
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)

                TextField("Add a task...", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isInputFocused)
                    .onSubmit {
                        store.addTask(newTaskText)
                        newTaskText = ""
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            // Task list
            ScrollView {
                LazyVStack(spacing: 2) {
                    if !store.pendingTasks.isEmpty {
                        ForEach(store.pendingTasks) { task in
                            TaskRow(task: task, store: store)
                        }
                    }

                    if !store.completedTasks.isEmpty {
                        HStack {
                            Text("Completed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Spacer()

                            Button("Clear") {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    store.clearCompleted()
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 6)

                        ForEach(store.completedTasks) { task in
                            TaskRow(task: task, store: store)
                        }
                    }

                    if store.tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No tasks yet")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    @ObservedObject var store: AppStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    store.toggleTask(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(task.isCompleted ? .green : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 14))
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted, color: .secondary.opacity(0.5))
                .lineLimit(2)

            Spacer()

            if isHovering {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.deleteTask(task)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : .clear)
        )
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
