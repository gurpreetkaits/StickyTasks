import Foundation
import SwiftUI

class AppStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var notes: [NoteItem] = []
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

    // MARK: - Persistence

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("StickyTasks", isDirectory: true)
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
        if let data = try? encoder.encode(focusSessions) {
            try? data.write(to: storageURL.appendingPathComponent("sessions.json"))
        }
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
