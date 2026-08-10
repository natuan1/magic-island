import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem

    init(statusBar: NSStatusBar = .system) {
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "MI"
        statusItem.button?.toolTip = "Magic Island"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Quit Magic Island",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }
}
