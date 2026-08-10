import AppKit
import SwiftUI

@MainActor
final class IslandWindowController: NSObject {
    static let placeholderSize = IslandPlacement.floatingIslandSize
    private static let peekSize = CGSize(width: 184, height: 46)
    private static let expandedSize = CGSize(width: 420, height: 220)

    private var panel: IslandPanel!
    private let screenProvider: @MainActor () -> [NSScreen]
    private let selectedDisplayID: UInt32?
    private let currentActivityProvider: @MainActor () -> CurrentActivity?
    private var interactionController = IslandInteractionController()
    private var shortcutController: IslandShortcutController?
    private var currentPresentation: IslandPresentation = .passive

    init(
        screenProvider: @escaping @MainActor () -> [NSScreen] = { NSScreen.screens },
        selectedDisplayID: UInt32? = nil,
        currentActivityProvider: @escaping @MainActor () -> CurrentActivity? = { nil }
    ) {
        self.screenProvider = screenProvider
        self.selectedDisplayID = selectedDisplayID
        self.currentActivityProvider = currentActivityProvider
        super.init()

        let display = Self.selectedDisplay(
            from: screenProvider(),
            selectedDisplayID: selectedDisplayID
        )
        let placement = IslandPlacement.frame(for: display ?? Self.fallbackDisplayDescriptor)

        panel = IslandPanel(
            contentRect: placement.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hasShadow = false
        panel.isMovable = false
        panel.isOpaque = false
        panel.level = .statusBar

        panel.contentView = IslandTrackingHostingView(
            rootView: IslandPlaceholderView(size: placement.frame.size),
            onHoverEntered: { [weak self] in
                self?.apply(self?.interactionController.hoverEntered())
            },
            onHoverExited: { [weak self] in
                self?.apply(self?.interactionController.hoverExited())
            },
            onCommit: { [weak self] in
                self?.commitFromClick()
            }
        )

        shortcutController = IslandShortcutController(
            onShortcut: { [weak self] in
                self?.commitFromShortcut()
            },
            onEscape: { [weak self] in
                self?.collapse()
            }
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func refreshPlacement(animated: Bool = false) {
        let display = Self.selectedDisplay(
            from: screenProvider(),
            selectedDisplayID: selectedDisplayID
        ) ?? Self.fallbackDisplayDescriptor
        let placement = IslandPlacement.frame(for: display)
        let size = Self.size(for: currentPresentation)
        let nextFrame = IslandPlacement.clampedFrame(
            frame(for: size, anchoredAt: placement.frame),
            to: display.visibleFrame
        )

        panel.setFrame(nextFrame, display: true, animate: animated)
        panel.contentView = makeContentView(size: size, presentation: currentPresentation)
    }

    @objc private func screenParametersDidChange() {
        refreshPlacement(animated: true)
    }

    private func commitFromClick() {
        let transition = interactionController.click(
            currentActivity: currentActivityProvider()
        )
        apply(transition)
    }

    private func commitFromShortcut() {
        let transition = interactionController.shortcutPressed(
            currentActivity: currentActivityProvider()
        )
        apply(transition)
    }

    private func collapse() {
        apply(interactionController.collapse())
        apply(interactionController.finishCollapse())
    }

    private func apply(_ transition: IslandTransition?) {
        guard let transition else {
            return
        }

        panel.allowsInputFocus = transition.focusBehavior == .inputAllowed

        currentPresentation = transition.presentation
        let size = Self.size(for: transition.presentation)
        panel.setFrame(frame(for: size), display: true, animate: true)
        panel.contentView = makeContentView(size: size, presentation: transition.presentation)

        if transition.focusBehavior == .inputAllowed {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func makeContentView(
        size: CGSize,
        presentation: IslandPresentation = .passive
    ) -> IslandTrackingHostingView<IslandPlaceholderView> {
        IslandTrackingHostingView(
            rootView: IslandPlaceholderView(size: size, presentation: presentation),
            onHoverEntered: { [weak self] in
                self?.apply(self?.interactionController.hoverEntered())
            },
            onHoverExited: { [weak self] in
                self?.apply(self?.interactionController.hoverExited())
            },
            onCommit: { [weak self] in
                self?.commitFromClick()
            }
        )
    }

    private func frame(for size: CGSize) -> CGRect {
        frame(for: size, anchoredAt: panel.frame)
    }

    private func frame(for size: CGSize, anchoredAt currentFrame: CGRect) -> CGRect {
        return CGRect(
            x: currentFrame.midX - (size.width / 2),
            y: currentFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private static func size(for presentation: IslandPresentation) -> CGSize {
        switch presentation {
        case .passive, .collapsing:
            return placeholderSize
        case .peek:
            return peekSize
        case .expanded:
            return expandedSize
        }
    }

    private static func selectedDisplay(
        from screens: [NSScreen],
        selectedDisplayID: UInt32?
    ) -> IslandDisplayDescriptor? {
        IslandDisplaySelection.selectedDisplay(
            from: screens.map(displayDescriptor),
            selectedDisplayID: selectedDisplayID,
            primaryDisplayID: displayID(for: NSScreen.main)
        )
    }

    private static var fallbackDisplayDescriptor: IslandDisplayDescriptor {
        IslandDisplayDescriptor(
            id: nil,
            frame: .zero,
            visibleFrame: .zero,
            safeAreaInsets: .zero,
            auxiliaryTopLeftArea: .zero,
            auxiliaryTopRightArea: .zero
        )
    }

    private static func displayDescriptor(for screen: NSScreen) -> IslandDisplayDescriptor {
        IslandDisplayDescriptor(
            id: displayID(for: screen),
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
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

    private static func displayID(for screen: NSScreen?) -> UInt32? {
        guard
            let screen,
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return nil
        }

        return screenNumber.uint32Value
    }
}

private final class IslandPanel: NSPanel {
    var allowsInputFocus = false

    override var canBecomeKey: Bool {
        allowsInputFocus
    }

    override var canBecomeMain: Bool {
        false
    }
}

private final class IslandTrackingHostingView<Content: View>: NSHostingView<Content> {
    private let onHoverEntered: @MainActor () -> Void
    private let onHoverExited: @MainActor () -> Void
    private let onCommit: @MainActor () -> Void

    init(
        rootView: Content,
        onHoverEntered: @escaping @MainActor () -> Void,
        onHoverExited: @escaping @MainActor () -> Void,
        onCommit: @escaping @MainActor () -> Void
    ) {
        self.onHoverEntered = onHoverEntered
        self.onHoverExited = onHoverExited
        self.onCommit = onCommit
        super.init(rootView: rootView)
    }

    required init(rootView: Content) {
        onHoverEntered = {}
        onHoverExited = {}
        onCommit = {}
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder: NSCoder) {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverEntered()
    }

    override func mouseExited(with event: NSEvent) {
        onHoverExited()
    }

    override func mouseDown(with event: NSEvent) {
        onCommit()
    }
}
