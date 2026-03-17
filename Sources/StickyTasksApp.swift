import SwiftUI
import AppKit

@main
struct StickyTasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store: AppStore!
    var focusBarManager = FocusBarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        store = AppStore()

        store.onPinChanged = { [weak self] pinned in
            self?.popover.behavior = pinned ? .applicationDefined : .transient
        }

        store.onFocusChanged = { [weak self] focusing in
            guard let self = self else { return }
            if focusing {
                self.focusBarManager.show(store: self.store)
            } else {
                self.focusBarManager.hide()
            }
        }

        store.onOpenApp = { [weak self] in
            self?.openPopover()
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 440, height: 540)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: ContentView(store: store))

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "StickyTasks")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    func openPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
