import AppKit
import SwiftUI

@MainActor
final class IslandWindowController {
    static let placeholderSize = IslandPlacement.floatingIslandSize

    private let panel: NSPanel

    init(screenProvider: @MainActor () -> NSScreen? = IslandWindowController.primaryDisplay) {
        let screen = screenProvider()
        let placement = IslandPlacement.frame(
            for: screen.map(Self.displayDescriptor) ?? Self.fallbackDisplayDescriptor
        )

        panel = NSPanel(
            contentRect: placement.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: IslandPlaceholderView(size: placement.frame.size))
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

    private static var fallbackDisplayDescriptor: IslandDisplayDescriptor {
        IslandDisplayDescriptor(
            frame: .zero,
            safeAreaInsets: .zero,
            auxiliaryTopLeftArea: .zero,
            auxiliaryTopRightArea: .zero
        )
    }

    private static func displayDescriptor(for screen: NSScreen) -> IslandDisplayDescriptor {
        IslandDisplayDescriptor(
            frame: screen.frame,
            safeAreaInsets: DisplaySafeAreaInsets(
                top: screen.safeAreaInsets.top,
                left: screen.safeAreaInsets.left,
                bottom: screen.safeAreaInsets.bottom,
                right: screen.safeAreaInsets.right
            ),
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea ?? .zero,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea ?? .zero
        )
    }
}
