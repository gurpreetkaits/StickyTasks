import SwiftUI
import AppKit

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onChange: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = NSFont.systemFont(ofSize: 13.5)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = context.coordinator

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        textView.string = text
        context.coordinator.applyStyles(textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            context.coordinator.applyStyles(textView)
            // Restore cursor safely
            let safeRange = NSRange(
                location: min(selectedRange.location, textView.string.count),
                length: 0
            )
            textView.setSelectedRange(safeRange)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        private var isUpdating = false

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.onChange()
            applyStyles(textView)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Shift+Enter: toggle checkbox on current line
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let event = NSApp.currentEvent
                if event?.modifierFlags.contains(.shift) == true {
                    toggleCheckbox(textView)
                    return true
                }
            }
            return false
        }

        private func toggleCheckbox(_ textView: NSTextView) {
            let string = textView.string as NSString
            let cursorLocation = textView.selectedRange().location
            let lineRange = string.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let line = string.substring(with: lineRange)

            var newLine: String
            if line.hasPrefix("- [x] ") {
                newLine = "- [ ] " + String(line.dropFirst(6))
            } else if line.hasPrefix("- [ ] ") {
                newLine = "- [x] " + String(line.dropFirst(6))
            } else {
                // Convert current line to unchecked checkbox
                let trimmed = line.trimmingCharacters(in: .newlines)
                newLine = "- [ ] " + trimmed + (line.hasSuffix("\n") ? "\n" : "")
            }

            isUpdating = true
            textView.replaceCharacters(in: lineRange, with: newLine)
            parent.text = textView.string
            parent.onChange()
            applyStyles(textView)
            isUpdating = false

            // Restore cursor
            let newCursor = min(lineRange.location + newLine.count, textView.string.count)
            textView.setSelectedRange(NSRange(location: newCursor, length: 0))
        }

        func applyStyles(_ textView: NSTextView) {
            let fullString = textView.string as NSString
            let fullRange = NSRange(location: 0, length: fullString.length)
            guard let storage = textView.textStorage else { return }

            storage.beginEditing()

            // Reset to default
            storage.addAttributes([
                .font: NSFont.systemFont(ofSize: 13.5),
                .foregroundColor: NSColor.labelColor,
                .strikethroughStyle: 0
            ], range: fullRange)

            // Process line by line
            fullString.enumerateSubstrings(in: fullRange, options: .byLines) { line, lineRange, _, _ in
                guard let line = line else { return }

                if line.hasPrefix("### ") {
                    // H3: prefix faded, text semibold
                    let prefixRange = NSRange(location: lineRange.location, length: 4)
                    let textRange = NSRange(location: lineRange.location + 4, length: lineRange.length - 4)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ], range: prefixRange)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 15, weight: .semibold)
                    ], range: textRange)

                } else if line.hasPrefix("## ") {
                    // H2
                    let prefixRange = NSRange(location: lineRange.location, length: 3)
                    let textRange = NSRange(location: lineRange.location + 3, length: lineRange.length - 3)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ], range: prefixRange)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 18, weight: .semibold)
                    ], range: textRange)

                } else if line.hasPrefix("# ") {
                    // H1
                    let prefixRange = NSRange(location: lineRange.location, length: 2)
                    let textRange = NSRange(location: lineRange.location + 2, length: lineRange.length - 2)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ], range: prefixRange)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 22, weight: .bold)
                    ], range: textRange)

                } else if line.hasPrefix("- [x] ") {
                    // Checked checkbox
                    let prefixRange = NSRange(location: lineRange.location, length: 6)
                    let textRange = NSRange(location: lineRange.location + 6, length: lineRange.length - 6)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 13.5),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ], range: prefixRange)
                    storage.addAttributes([
                        .foregroundColor: NSColor.secondaryLabelColor,
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .strikethroughColor: NSColor.secondaryLabelColor
                    ], range: textRange)

                } else if line.hasPrefix("- [ ] ") {
                    // Unchecked checkbox
                    let prefixRange = NSRange(location: lineRange.location, length: 6)
                    storage.addAttributes([
                        .font: NSFont.systemFont(ofSize: 13.5),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ], range: prefixRange)

                } else if line.hasPrefix("- ") {
                    // Bullet list
                    let prefixRange = NSRange(location: lineRange.location, length: 2)
                    storage.addAttributes([
                        .foregroundColor: NSColor.secondaryLabelColor
                    ], range: prefixRange)

                } else if line.hasPrefix("> ") {
                    // Blockquote
                    storage.addAttributes([
                        .foregroundColor: NSColor.secondaryLabelColor,
                        .font: NSFont.systemFont(ofSize: 13.5, weight: .regular)
                    ], range: lineRange)
                }

                // Inline: **bold**
                self.applyInlinePattern(storage: storage, line: line, lineOffset: lineRange.location,
                    pattern: "\\*\\*(.+?)\\*\\*", attrs: [.font: NSFont.systemFont(ofSize: 13.5, weight: .bold)])

                // Inline: *italic*
                self.applyInlinePattern(storage: storage, line: line, lineOffset: lineRange.location,
                    pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)",
                    attrs: [.font: NSFont(descriptor: NSFont.systemFont(ofSize: 13.5).fontDescriptor.withSymbolicTraits(.italic), size: 13.5)!])

                // Inline: `code`
                self.applyInlinePattern(storage: storage, line: line, lineOffset: lineRange.location,
                    pattern: "`(.+?)`",
                    attrs: [
                        .font: NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular),
                        .foregroundColor: NSColor.systemPink,
                        .backgroundColor: NSColor.quaternaryLabelColor
                    ])
            }

            storage.endEditing()
        }

        private func applyInlinePattern(storage: NSTextStorage, line: String, lineOffset: Int, pattern: String, attrs: [NSAttributedString.Key: Any]) {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            let nsLine = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let fullRange = NSRange(location: lineOffset + match.range.location, length: match.range.length)
                if fullRange.location + fullRange.length <= storage.length {
                    storage.addAttributes(attrs, range: fullRange)
                }
            }
        }
    }
}
