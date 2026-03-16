import SwiftUI

struct NotesView: View {
    @ObservedObject var store: AppStore
    @State private var selectedNote: NoteItem?
    @State private var editingTitle = ""
    @State private var blocks: [Block] = []

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
                blocks = parseMarkdown(note.content)
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
                                blocks = parseMarkdown(note.content)
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
            // Toolbar
            HStack {
                Button {
                    let content = serializeBlocks(blocks)
                    store.updateNote(note, title: editingTitle, content: content)
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

                // Block type shortcuts
                HStack(spacing: 2) {
                    blockTypeButton("H1", icon: "textformat.size.larger", type: .heading1)
                    blockTypeButton("H2", icon: "textformat.size", type: .heading2)
                    blockTypeButton("H3", icon: "textformat.size.smaller", type: .heading3)
                    blockTypeButton(nil, icon: "checkmark.square", type: .checkbox)
                    blockTypeButton("T", icon: "textformat", type: .text)
                }

                Spacer()

                Button {
                    let content = serializeBlocks(blocks)
                    store.updateNote(note, content: content)
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
                .padding(.bottom, 2)
                .onChange(of: editingTitle) { _, newValue in
                    store.updateNote(note, title: newValue)
                }

            // Hint
            Text("Type # for headings, [] for checkbox")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            // Block editor
            BlockEditor(blocks: $blocks) {
                let content = serializeBlocks(blocks)
                store.updateNote(note, content: content)
            }

            // Footer
            HStack {
                Text(formatDate(note.updatedAt))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(blocks.count) block\(blocks.count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    func blockTypeButton(_ label: String?, icon: String, type: BlockType) -> some View {
        Button {
            appendBlock(type: type)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                )
        }
        .buttonStyle(.plain)
        .help(type == .checkbox ? "Add checkbox" : "Add \(label ?? "text")")
    }

    func appendBlock(type: BlockType) {
        let block = Block(type: type)
        blocks.append(block)
        let content = serializeBlocks(blocks)
        if let note = selectedNote {
            store.updateNote(note, content: content)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: NoteItem
    @ObservedObject var store: AppStore
    let onTap: () -> Void
    @State private var isHovering = false

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
        // Strip markdown prefixes for preview
        let cleaned = note.content
            .components(separatedBy: "\n")
            .first?
            .replacingOccurrences(of: "^#{1,3} ", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^- \\[.\\] ", with: "", options: .regularExpression)
            ?? "No content"
        return cleaned.isEmpty ? "No content" : cleaned
    }
}
