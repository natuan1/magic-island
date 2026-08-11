import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onShowIsland: @MainActor () -> Void
    private let onOpenFeature: @MainActor (FeatureID) -> Void
    private let onOpenSettings: @MainActor () -> Void
    private let onCheckUpdates: @MainActor () -> Void

    init(
        statusBar: NSStatusBar = .system,
        model: StatusBarMenuModel = .core(featureIDs: [.media, .fileShelf, .clipboardHistory]),
        onShowIsland: @escaping @MainActor () -> Void = {},
        onOpenFeature: @escaping @MainActor (FeatureID) -> Void = { _ in },
        onOpenSettings: @escaping @MainActor () -> Void = {},
        onCheckUpdates: @escaping @MainActor () -> Void = {}
    ) {
        self.onShowIsland = onShowIsland
        self.onOpenFeature = onOpenFeature
        self.onOpenSettings = onOpenSettings
        self.onCheckUpdates = onCheckUpdates
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "MI"
        statusItem.button?.toolTip = "Magic Island"

        updateMenu(model)
    }

    func updateMenu(_ model: StatusBarMenuModel) {
        let menu = NSMenu()
        for item in model.items {
            let menuItem = NSMenuItem(
                title: item.title,
                action: selector(for: item.command),
                keyEquivalent: keyEquivalent(for: item.command)
            )
            menuItem.target = self
            menuItem.representedObject = item.command
            menu.addItem(menuItem)
            if item.command == .showIsland || item.command == .openSettings {
                menu.addItem(.separator())
            }
        }
        statusItem.menu = menu
    }

    private func selector(for command: StatusBarMenuCommand) -> Selector {
        switch command {
        case .showIsland:
            return #selector(showIsland)
        case .openFeature:
            return #selector(openFeature(_:))
        case .openSettings:
            return #selector(openSettings)
        case .checkUpdates:
            return #selector(checkUpdates)
        case .quit:
            return #selector(NSApplication.terminate(_:))
        }
    }

    private func keyEquivalent(for command: StatusBarMenuCommand) -> String {
        switch command {
        case .openSettings:
            return ","
        case .quit:
            return "q"
        case .showIsland, .openFeature, .checkUpdates:
            return ""
        }
    }

    @objc private func showIsland() {
        onShowIsland()
    }

    @objc private func openFeature(_ sender: NSMenuItem) {
        guard case .openFeature(let featureID) = sender.representedObject as? StatusBarMenuCommand else {
            return
        }
        onOpenFeature(featureID)
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func checkUpdates() {
        onCheckUpdates()
    }
}
