import SwiftUI

struct NotesView: View {
    @ObservedObject var store: AppStore
    @State private var selectedNote: NoteItem?
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var showCopied = false

    var body: some View {
        if let note = selectedNote {
            noteEditor(note: note)
        } else {
            notesList
        }
    }

    var notesList: some View {
        VStack(spacing: 0) {
            Button {
                let note = store.addNote()
                selectedNote = note
                editingTitle = note.title
                editingContent = note.content
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                    Text("New note")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    if store.notes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No notes yet")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(store.notes) { note in
                            NoteRow(note: note, store: store) {
                                selectedNote = note
                                editingTitle = note.title
                                editingContent = note.content
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    func noteEditor(note: NoteItem) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.updateNote(note, title: editingTitle, content: editingContent)
                    selectedNote = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                // Copy note
                Button {
                    let full = (editingTitle.isEmpty ? "" : editingTitle + "\n\n") + editingContent
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(full, forType: .string)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy note")

                Button {
                    store.deleteNote(note)
                    selectedNote = nil
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Title
            TextField("Title", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .onChange(of: editingTitle) { _, newValue in
                    store.updateNote(note, title: newValue)
                }

            // Markdown editor
            MarkdownTextEditor(text: $editingContent) {
                store.updateNote(note, content: editingContent)
            }

            // Footer hints
            HStack(spacing: 12) {
                Text(formatDate(note.updatedAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("⇧↵ checkbox")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NoteRow: View {
    let note: NoteItem
    @ObservedObject var store: AppStore
    let onTap: () -> Void
    @State private var isHovering = false
    @State private var rowCopied = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(previewText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isHovering {
                    // Copy button
                    Button {
                        let full = (note.title.isEmpty ? "" : note.title + "\n\n") + note.content
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(full, forType: .string)
                        rowCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { rowCopied = false }
                    } label: {
                        Image(systemName: rowCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(rowCopied ? .green : .secondary)
                            .frame(width: 20, height: 20)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))

                    // Delete button
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            store.deleteNote(note)
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
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : .clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    var previewText: String {
        if note.content.isEmpty { return "No content" }
        let cleaned = note.content
            .components(separatedBy: "\n")
            .first?
            .replacingOccurrences(of: "^#{1,3} ", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^- \\[.\\] ", with: "", options: .regularExpression)
            ?? "No content"
        return cleaned.isEmpty ? "No content" : cleaned
    }
}
