import SwiftUI

// MARK: - Block Model

enum BlockType: String, Codable {
    case text
    case heading1
    case heading2
    case heading3
    case checkbox
}

struct Block: Identifiable, Equatable {
    let id: UUID
    var type: BlockType
    var content: String
    var isChecked: Bool

    init(id: UUID = UUID(), type: BlockType = .text, content: String = "", isChecked: Bool = false) {
        self.id = id
        self.type = type
        self.content = content
        self.isChecked = isChecked
    }
}

// MARK: - Markdown <-> Blocks

func parseMarkdown(_ text: String) -> [Block] {
    guard !text.isEmpty else { return [Block()] }

    let lines = text.components(separatedBy: "\n")
    var blocks: [Block] = []

    for line in lines {
        if line.hasPrefix("### ") {
            blocks.append(Block(type: .heading3, content: String(line.dropFirst(4))))
        } else if line.hasPrefix("## ") {
            blocks.append(Block(type: .heading2, content: String(line.dropFirst(3))))
        } else if line.hasPrefix("# ") {
            blocks.append(Block(type: .heading1, content: String(line.dropFirst(2))))
        } else if line.hasPrefix("- [x] ") {
            blocks.append(Block(type: .checkbox, content: String(line.dropFirst(6)), isChecked: true))
        } else if line.hasPrefix("- [ ] ") {
            blocks.append(Block(type: .checkbox, content: String(line.dropFirst(6)), isChecked: false))
        } else {
            blocks.append(Block(type: .text, content: line))
        }
    }

    return blocks
}

func serializeBlocks(_ blocks: [Block]) -> String {
    blocks.map { block in
        switch block.type {
        case .heading1: return "# \(block.content)"
        case .heading2: return "## \(block.content)"
        case .heading3: return "### \(block.content)"
        case .checkbox: return "- [\(block.isChecked ? "x" : " ")] \(block.content)"
        case .text: return block.content
        }
    }.joined(separator: "\n")
}

// MARK: - Block Editor View

struct BlockEditor: View {
    @Binding var blocks: [Block]
    var onChange: () -> Void
    @FocusState private var focusedBlockID: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    BlockRow(
                        block: $blocks[index],
                        isFocused: focusedBlockID == block.id,
                        onFocus: { focusedBlockID = block.id },
                        onEnter: { insertBlock(after: index) },
                        onDelete: { deleteBlock(at: index) },
                        onTypeChange: { onChange() },
                        onChange: onChange
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func insertBlock(after index: Int) {
        let newBlock = Block()
        let insertIndex = min(index + 1, blocks.count)
        blocks.insert(newBlock, at: insertIndex)
        onChange()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedBlockID = newBlock.id
        }
    }

    private func deleteBlock(at index: Int) {
        guard blocks.count > 1 else { return }
        let content = blocks[index].content
        blocks.remove(at: index)
        // Append leftover text to previous block
        let prevIndex = max(0, index - 1)
        blocks[prevIndex].content += content
        onChange()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedBlockID = blocks[prevIndex].id
        }
    }
}

// MARK: - Single Block Row

struct BlockRow: View {
    @Binding var block: Block
    let isFocused: Bool
    let onFocus: () -> Void
    let onEnter: () -> Void
    let onDelete: () -> Void
    let onTypeChange: () -> Void
    let onChange: () -> Void

    @State private var showTypePicker = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Block type indicator / drag handle
            blockHandle

            // Content
            blockContent
        }
        .padding(.vertical, verticalPadding)
    }

    @ViewBuilder
    var blockHandle: some View {
        if block.type == .checkbox {
            Button {
                block.isChecked.toggle()
                onChange()
            } label: {
                Image(systemName: block.isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15))
                    .foregroundColor(block.isChecked ? .accentColor : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        } else {
            Menu {
                Button { setType(.text) } label: { Label("Text", systemImage: "textformat") }
                Button { setType(.heading1) } label: { Label("Heading 1", systemImage: "textformat.size.larger") }
                Button { setType(.heading2) } label: { Label("Heading 2", systemImage: "textformat.size") }
                Button { setType(.heading3) } label: { Label("Heading 3", systemImage: "textformat.size.smaller") }
                Button { setType(.checkbox) } label: { Label("Checkbox", systemImage: "checkmark.square") }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(isFocused ? 0.5 : 0))
                    .frame(width: 18, height: 18)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 18)
            .padding(.top, handleTopPadding)
        }
    }

    @ViewBuilder
    var blockContent: some View {
        CustomTextField(
            text: $block.content,
            placeholder: placeholder,
            font: blockFont,
            fontWeight: blockWeight,
            textColor: textColor,
            strikethrough: block.type == .checkbox && block.isChecked,
            onEnter: onEnter,
            onDeleteEmpty: onDelete,
            onPrefixDetected: { prefix in
                handlePrefix(prefix)
            },
            onChange: onChange
        )
    }

    private func setType(_ type: BlockType) {
        block.type = type
        if type != .checkbox { block.isChecked = false }
        onTypeChange()
    }

    private func handlePrefix(_ prefix: String) {
        switch prefix {
        case "# ":
            block.type = .heading1
            onTypeChange()
        case "## ":
            block.type = .heading2
            onTypeChange()
        case "### ":
            block.type = .heading3
            onTypeChange()
        case "[] ", "[ ] ":
            block.type = .checkbox
            block.isChecked = false
            onTypeChange()
        default:
            break
        }
    }

    private var placeholder: String {
        switch block.type {
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .checkbox: return "To-do"
        case .text: return "Type '/' or start writing..."
        }
    }

    private var blockFont: CGFloat {
        switch block.type {
        case .heading1: return 22
        case .heading2: return 18
        case .heading3: return 15
        case .checkbox, .text: return 13.5
        }
    }

    private var blockWeight: Font.Weight {
        switch block.type {
        case .heading1: return .bold
        case .heading2: return .semibold
        case .heading3: return .semibold
        case .checkbox, .text: return .regular
        }
    }

    private var textColor: NSColor {
        if block.type == .checkbox && block.isChecked {
            return .secondaryLabelColor
        }
        return .labelColor
    }

    private var verticalPadding: CGFloat {
        switch block.type {
        case .heading1: return 6
        case .heading2: return 4
        case .heading3: return 3
        case .checkbox, .text: return 1
        }
    }

    private var handleTopPadding: CGFloat {
        switch block.type {
        case .heading1: return 6
        case .heading2: return 3
        case .heading3: return 2
        case .checkbox, .text: return 1
        }
    }
}

// MARK: - Custom NSTextField wrapper

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font: CGFloat
    var fontWeight: Font.Weight
    var textColor: NSColor
    var strikethrough: Bool
    var onEnter: () -> Void
    var onDeleteEmpty: () -> Void
    var onPrefixDetected: (String) -> Void
    var onChange: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.isEditable = true
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.lineBreakMode = .byWordWrapping
        tf.maximumNumberOfLines = 0
        tf.cell?.wraps = true
        tf.cell?.isScrollable = false
        tf.placeholderString = placeholder
        tf.delegate = context.coordinator
        applyStyle(to: tf)
        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        if tf.stringValue != text {
            tf.stringValue = text
        }
        tf.placeholderString = placeholder
        applyStyle(to: tf)
    }

    private func applyStyle(to tf: NSTextField) {
        let nsWeight: NSFont.Weight = {
            switch fontWeight {
            case .bold: return .bold
            case .semibold: return .semibold
            case .medium: return .medium
            default: return .regular
            }
        }()

        let nsFont = NSFont.systemFont(ofSize: font, weight: nsWeight)
        tf.font = nsFont
        tf.textColor = textColor

        if strikethrough {
            let attributed = NSAttributedString(
                string: text,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .font: nsFont,
                    .foregroundColor: textColor
                ]
            )
            tf.attributedStringValue = attributed
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            let newValue = tf.stringValue

            // Detect markdown prefixes and convert
            let prefixes = ["### ", "## ", "# ", "[] ", "[ ] "]
            for prefix in prefixes {
                if newValue.hasPrefix(prefix) && newValue.count == prefix.count ||
                   newValue == prefix.trimmingCharacters(in: .whitespaces) + " " {
                    // Check if the whole text is just the prefix
                    if newValue.hasPrefix(prefix) {
                        let remaining = String(newValue.dropFirst(prefix.count))
                        tf.stringValue = remaining
                        parent.text = remaining
                        parent.onPrefixDetected(prefix)
                        parent.onChange()
                        return
                    }
                }
            }

            // Re-check with simpler logic
            for prefix in prefixes {
                if newValue == prefix || (newValue.hasPrefix(prefix) && parent.text == String(newValue.dropLast(1)).replacingOccurrences(of: prefix, with: "")) {
                    let remaining = String(newValue.dropFirst(prefix.count))
                    tf.stringValue = remaining
                    parent.text = remaining
                    parent.onPrefixDetected(prefix)
                    parent.onChange()
                    return
                }
            }

            parent.text = newValue
            parent.onChange()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onEnter()
                return true
            }
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if parent.text.isEmpty {
                    parent.onDeleteEmpty()
                    return true
                }
            }
            return false
        }
    }
}
