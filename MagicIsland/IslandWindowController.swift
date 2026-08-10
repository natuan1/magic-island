import AppKit
import SwiftUI

@MainActor
final class IslandWindowController {
    static let placeholderSize = CGSize(width: 148, height: 38)

    private let panel: NSPanel

    init(screenProvider: @MainActor () -> NSScreen? = IslandWindowController.primaryDisplay) {
        let screen = screenProvider()
        let frame = IslandPlacement.placeholderFrame(
            in: screen?.frame ?? .zero,
            islandSize: Self.placeholderSize
        )

        panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: IslandPlaceholderView())
        panel.hasShadow = false
        panel.isMovable = false
        panel.isOpaque = false
        panel.level = .statusBar
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private static func primaryDisplay() -> NSScreen? {
        guard let selectedFrame = IslandDisplaySelection.primaryDisplayFrame(
            from: NSScreen.screens.map(\.frame),
            mainScreenFrame: NSScreen.main?.frame
        ) else {
            return nil
        }

        return NSScreen.screens.first { $0.frame == selectedFrame }
    }
}
