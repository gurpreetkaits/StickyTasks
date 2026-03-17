import SwiftUI

struct IdeasView: View {
    @ObservedObject var store: AppStore
    @State private var newIdeaText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                TextField("Capture an idea...", text: $newIdeaText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isInputFocused)
                    .onSubmit {
                        store.addIdea(newIdeaText)
                        newIdeaText = ""
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            // Ideas list
            ScrollView {
                LazyVStack(spacing: 2) {
                    if store.ideas.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No ideas yet")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(store.ideas) { idea in
                            IdeaRow(idea: idea, store: store)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

struct IdeaRow: View {
    let idea: IdeaItem
    @ObservedObject var store: AppStore
    @State private var isHovering = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(formatDate(idea.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            if isHovering {
                // Copy
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(idea.title, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(copied ? .green : .secondary)
                        .frame(width: 20, height: 20)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))

                // Delete
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.deleteIdea(idea)
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

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date)
    }
}
