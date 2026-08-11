import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem

    init(
        statusBar: NSStatusBar = .system,
        onOpenSettings: @escaping @MainActor () -> Void = {}
    ) {
        self.onOpenSettings = onOpenSettings
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "MI"
        statusItem.button?.toolTip = "Magic Island"

        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Magic Island",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }

    private let onOpenSettings: @MainActor () -> Void

    @objc private func openSettings() {
        onOpenSettings()
    }
}
