import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

struct NoteItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "", content: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct FocusSession: Identifiable, Codable, Equatable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var duration: TimeInterval

    init(id: UUID = UUID(), startedAt: Date = Date(), endedAt: Date? = nil, duration: TimeInterval = 0) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
    }
}

enum Tab: String, CaseIterable {
    case tasks = "Tasks"
    case notes = "Notes"
    case focus = "Focus"
}
