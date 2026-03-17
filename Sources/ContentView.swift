import SwiftUI

struct ContentView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }

                Spacer()

                // Pin button
                Button {
                    store.togglePin()
                } label: {
                    Image(systemName: store.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(store.isPinned ? .accentColor : .secondary)
                        .rotationEffect(.degrees(store.isPinned ? 0 : 45))
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(store.isPinned ? Color.accentColor.opacity(0.15) : .clear)
                        )
                }
                .buttonStyle(.plain)
                .help(store.isPinned ? "Unpin popover" : "Pin popover to stay visible")
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            // Content
            Group {
                switch store.currentTab {
                case .tasks:
                    TasksView(store: store)
                case .notes:
                    NotesView(store: store)
                case .ideas:
                    IdeasView(store: store)
                case .focus:
                    FocusTimerView(store: store)
                }
            }
            .frame(maxHeight: .infinity)

            Divider().opacity(0.3)

            // Footer
            HStack {
                if store.currentTab == .tasks {
                    let count = store.pendingTasks.count
                    Text("\(count) task\(count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else if store.currentTab == .notes {
                    Text("\(store.notes.count) note\(store.notes.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else if store.currentTab == .ideas {
                    Text("\(store.ideas.count) idea\(store.ideas.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else if store.isFocusing {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    Text("Focusing...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                } else {
                    Text("Today: \(formatDuration(store.todayTotalFocus))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 440, height: 540)
        .background(.ultraThinMaterial)
    }

    func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                store.currentTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tabIcon(tab))
                    .font(.system(size: 11))
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(store.currentTab == tab ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(store.currentTab == tab ? Color(nsColor: .controlBackgroundColor) : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .tasks: return "checkmark.square"
        case .notes: return "note.text"
        case .ideas: return "lightbulb"
        case .focus: return "timer"
        }
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
