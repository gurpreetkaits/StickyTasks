import Foundation
import SwiftUI

class AppStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var notes: [NoteItem] = []
    @Published var ideas: [IdeaItem] = []
    @Published var currentTab: Tab = .tasks
    @Published var isPinned: Bool = false

    // Focus timer
    @Published var isFocusing: Bool = false
    @Published var focusElapsed: TimeInterval = 0
    @Published var focusSessions: [FocusSession] = []
    @Published var currentSession: FocusSession?
    private var focusTimer: Timer?

    // Callbacks
    var onPinChanged: ((Bool) -> Void)?
    var onFocusChanged: ((Bool) -> Void)?
    var onOpenApp: (() -> Void)?

    init() {
        load()
    }

    // MARK: - Persistence (JSON in App Support)

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("StickyTasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Markdown backup directory (~/StickyTasks/)

    private var mdBaseURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent("StickyTasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func mdDir(_ name: String) -> URL {
        let dir = mdBaseURL.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: storageURL.appendingPathComponent("tasks.json")),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            tasks = decoded
        }

        if let data = try? Data(contentsOf: storageURL.appendingPathComponent("notes.json")),
           let decoded = try? decoder.decode([NoteItem].self, from: data) {
            notes = decoded
        }

        if let data = try? Data(contentsOf: storageURL.appendingPathComponent("ideas.json")),
           let decoded = try? decoder.decode([IdeaItem].self, from: data) {
            ideas = decoded
        }

        if let data = try? Data(contentsOf: storageURL.appendingPathComponent("sessions.json")),
           let decoded = try? decoder.decode([FocusSession].self, from: data) {
            focusSessions = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(tasks) {
            try? data.write(to: storageURL.appendingPathComponent("tasks.json"))
        }
        if let data = try? encoder.encode(notes) {
            try? data.write(to: storageURL.appendingPathComponent("notes.json"))
        }
        if let data = try? encoder.encode(ideas) {
            try? data.write(to: storageURL.appendingPathComponent("ideas.json"))
        }
        if let data = try? encoder.encode(focusSessions) {
            try? data.write(to: storageURL.appendingPathComponent("sessions.json"))
        }

        // Sync markdown backups
        syncMarkdownFiles()
    }

    // MARK: - Markdown Sync

    private func syncMarkdownFiles() {
        // ~/StickyTasks/Tasks/tasks.md
        let tasksDir = mdDir("Tasks")
        var tasksMd = "# Tasks\n\n"
        if !pendingTasks.isEmpty {
            tasksMd += "## Pending\n\n"
            for t in pendingTasks {
                tasksMd += "- [ ] \(t.title)\n"
            }
            tasksMd += "\n"
        }
        if !completedTasks.isEmpty {
            tasksMd += "## Completed\n\n"
            for t in completedTasks {
                let dateStr = formatDateShort(t.completedAt ?? t.createdAt)
                tasksMd += "- [x] \(t.title) _(completed \(dateStr))_\n"
            }
            tasksMd += "\n"
        }
        try? tasksMd.write(to: tasksDir.appendingPathComponent("tasks.md"), atomically: true, encoding: .utf8)

        // ~/StickyTasks/Notes/<title>.md per note
        let notesDir = mdDir("Notes")
        // Clear old notes
        if let files = try? FileManager.default.contentsOfDirectory(at: notesDir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "md" {
                try? FileManager.default.removeItem(at: file)
            }
        }
        for note in notes {
            let fileName = sanitizeFilename(note.title.isEmpty ? "Untitled" : note.title, id: note.id)
            var content = "# \(note.title.isEmpty ? "Untitled" : note.title)\n\n"
            content += note.content
            content += "\n\n---\n_Created: \(formatDateShort(note.createdAt)) | Updated: \(formatDateShort(note.updatedAt))_\n"
            try? content.write(to: notesDir.appendingPathComponent("\(fileName).md"), atomically: true, encoding: .utf8)
        }

        // ~/StickyTasks/Ideas/ideas.md
        let ideasDir = mdDir("Ideas")
        var ideasMd = "# Ideas\n\n"
        for idea in ideas {
            let dateStr = formatDateShort(idea.createdAt)
            ideasMd += "- \(idea.title) _(\(dateStr))_\n"
        }
        if ideas.isEmpty {
            ideasMd += "_No ideas yet._\n"
        }
        try? ideasMd.write(to: ideasDir.appendingPathComponent("ideas.md"), atomically: true, encoding: .utf8)
    }

    private func sanitizeFilename(_ name: String, id: UUID) -> String {
        let cleaned = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .prefix(50)
        let shortID = id.uuidString.prefix(6)
        return "\(cleaned)_\(shortID)"
    }

    private func formatDateShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Pin

    func togglePin() {
        isPinned.toggle()
        onPinChanged?(isPinned)
    }

    // MARK: - Tasks

    func addTask(_ title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        tasks.insert(TaskItem(title: title), at: 0)
        save()
    }

    func toggleTask(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            tasks[idx].completedAt = tasks[idx].isCompleted ? Date() : nil
            save()
        }
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func clearCompleted() {
        tasks.removeAll { $0.isCompleted }
        save()
    }

    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }

    // MARK: - Notes

    func addNote() -> NoteItem {
        let note = NoteItem(title: "Untitled")
        notes.insert(note, at: 0)
        save()
        return note
    }

    func updateNote(_ note: NoteItem, title: String? = nil, content: String? = nil) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            if let title = title { notes[idx].title = title }
            if let content = content { notes[idx].content = content }
            notes[idx].updatedAt = Date()
            save()
        }
    }

    func deleteNote(_ note: NoteItem) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    // MARK: - Ideas

    func addIdea(_ title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        ideas.insert(IdeaItem(title: title), at: 0)
        save()
    }

    func deleteIdea(_ idea: IdeaItem) {
        ideas.removeAll { $0.id == idea.id }
        save()
    }

    // MARK: - Focus Timer

    func startFocus() {
        let session = FocusSession()
        currentSession = session
        isFocusing = true
        focusElapsed = 0

        focusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.focusElapsed += 1
            }
        }
        onFocusChanged?(true)
    }

    func stopFocus() {
        focusTimer?.invalidate()
        focusTimer = nil
        isFocusing = false

        if var session = currentSession {
            session.endedAt = Date()
            session.duration = focusElapsed
            focusSessions.insert(session, at: 0)
            currentSession = nil
            save()
        }
        onFocusChanged?(false)
    }

    func clearSessions() {
        focusSessions.removeAll()
        save()
    }

    var todaySessions: [FocusSession] {
        let calendar = Calendar.current
        return focusSessions.filter { calendar.isDateInToday($0.startedAt) }
    }

    var todayTotalFocus: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }
}
