import SwiftUI
import AppKit

// MARK: - Floating Panel (always on top, no dock, no shadow jump)

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false

        // Rounded corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 14
        contentView?.layer?.masksToBounds = true
    }
}

// MARK: - Focus Bar Manager

class FocusBarManager {
    private var panel: FloatingPanel?
    private var hostingView: NSHostingView<FloatingFocusBarView>?

    func show(store: AppStore) {
        guard panel == nil else { return }

        let barView = FloatingFocusBarView(store: store)
        let hosting = NSHostingView(rootView: barView)
        hosting.frame = NSRect(x: 0, y: 0, width: 260, height: 48)

        // Position: bottom center of main screen
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let x = screenFrame.midX - 130
        let y = screenFrame.minY + 20

        let p = FloatingPanel(contentRect: NSRect(x: x, y: y, width: 260, height: 48))
        p.contentView = hosting
        p.orderFront(nil)

        panel = p
        hostingView = hosting
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
    }

    var isVisible: Bool { panel != nil }
}

// MARK: - Floating Bar SwiftUI View

struct FloatingFocusBarView: View {
    @ObservedObject var store: AppStore
    @State private var showOptions = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Options dropdown — floats ABOVE the bar
            if showOptions {
                VStack(spacing: 4) {
                    optionButton(icon: "arrow.counterclockwise", label: "Reset", color: .orange) {
                        store.stopFocus()
                        store.startFocus()
                        showOptions = false
                    }
                    optionButton(icon: "square.stack", label: "Open App", color: .accentColor) {
                        store.onOpenApp?()
                        showOptions = false
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
                )
                .offset(y: -56)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // The bar itself — fixed position
            HStack(spacing: 12) {
                // Pulsing red dot
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(.red.opacity(0.4))
                            .frame(width: 16, height: 16)
                            .opacity(store.isFocusing ? 1 : 0)
                            .scaleEffect(store.isFocusing ? 1 : 0.5)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: store.isFocusing)
                    )

                // Timer
                Text(formatTime(store.focusElapsed))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                // More options
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        showOptions.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
                        .rotationEffect(.degrees(showOptions ? 180 : 0))
                }
                .buttonStyle(.plain)

                // Stop button
                Button {
                    store.stopFocus()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(width: 260, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 2)
            )
        }
        .frame(width: 260)
    }

    func optionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.01))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            // handled by contentShape
        }
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
