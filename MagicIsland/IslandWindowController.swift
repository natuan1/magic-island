import AppKit
import SwiftUI

@MainActor
final class IslandWindowController {
    static let placeholderSize = IslandPlacement.floatingIslandSize
    private static let peekSize = CGSize(width: 184, height: 46)
    private static let expandedSize = CGSize(width: 420, height: 220)

    private let panel: IslandPanel
    private let settingsStore: SettingsStore
    private let currentActivityProvider: @MainActor () -> CurrentActivity?
    private let mediaCommandHandler: @MainActor (MediaCommand) -> Void
    private var interactionController = IslandInteractionController()
    private var shortcutController: IslandShortcutController?
    private var currentPresentation: IslandPresentation = .passive

    init(
        settingsStore: SettingsStore = SettingsStore(),
        screenProvider: @MainActor () -> NSScreen? = IslandWindowController.primaryDisplay,
        currentActivityProvider: @escaping @MainActor () -> CurrentActivity? = { nil },
        mediaCommandHandler: @escaping @MainActor (MediaCommand) -> Void = { _ in }
    ) {
        self.settingsStore = settingsStore
        self.currentActivityProvider = currentActivityProvider
        self.mediaCommandHandler = mediaCommandHandler

        let screen = Self.selectedDisplay(settingsStore: settingsStore) ?? screenProvider()
        let placement = IslandPlacement.frame(
            for: screen.map(Self.displayDescriptor) ?? Self.fallbackDisplayDescriptor
        )

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
            rootView: IslandPlaceholderView(
                size: placement.frame.size,
                currentActivity: currentActivityProvider(),
                onMediaCommand: mediaCommandHandler
            ),
            hoverDelay: settingsStore.hoverDelay,
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
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func refreshCurrentActivity() {
        switch currentPresentation {
        case .expanded:
            currentPresentation = currentActivityProvider()
                .map { .expanded(anchor: .currentActivity($0)) }
                ?? .expanded(anchor: .idlePlaceholder)
        case .passive, .peek, .collapsing:
            break
        }

        let size = Self.size(for: currentPresentation)
        panel.contentView = makeContentView(size: size, presentation: currentPresentation)
    }

    func settingsChanged() {
        let screen = Self.selectedDisplay(settingsStore: settingsStore) ?? Self.primaryDisplay()
        let placement = IslandPlacement.frame(
            for: screen.map(Self.displayDescriptor) ?? Self.fallbackDisplayDescriptor
        )
        let size = Self.size(for: currentPresentation)
        panel.setFrame(
            CGRect(
                x: placement.frame.midX - (size.width / 2),
                y: placement.frame.maxY - size.height,
                width: size.width,
                height: size.height
            ),
            display: true,
            animate: true
        )
        panel.contentView = makeContentView(size: size, presentation: currentPresentation)
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
            rootView: IslandPlaceholderView(
                size: size,
                presentation: presentation,
                currentActivity: currentActivityProvider(),
                onMediaCommand: mediaCommandHandler
            ),
            hoverDelay: settingsStore.hoverDelay,
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
        let currentFrame = panel.frame
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

    private static func primaryDisplay() -> NSScreen? {
        guard let selectedFrame = IslandDisplaySelection.primaryDisplayFrame(
            from: NSScreen.screens.map(\.frame),
            mainScreenFrame: NSScreen.main?.frame
        ) else {
            return nil
        }

        return NSScreen.screens.first { $0.frame == selectedFrame }
    }

    private static func selectedDisplay(settingsStore: SettingsStore) -> NSScreen? {
        guard case .specificDisplay(let selectedDisplayID) = settingsStore.displayPreference else {
            return nil
        }

        return NSScreen.screens.first { screen in
            screen.displayID == selectedDisplayID
        }
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
    private let hoverDelay: TimeInterval
    private let onHoverEntered: @MainActor () -> Void
    private let onHoverExited: @MainActor () -> Void
    private let onCommit: @MainActor () -> Void
    private var hoverTimer: Timer?

    init(
        rootView: Content,
        hoverDelay: TimeInterval,
        onHoverEntered: @escaping @MainActor () -> Void,
        onHoverExited: @escaping @MainActor () -> Void,
        onCommit: @escaping @MainActor () -> Void
    ) {
        self.hoverDelay = hoverDelay
        self.onHoverEntered = onHoverEntered
        self.onHoverExited = onHoverExited
        self.onCommit = onCommit
        super.init(rootView: rootView)
    }

    required init(rootView: Content) {
        hoverDelay = 0
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
        hoverTimer?.invalidate()

        if hoverDelay <= 0 {
            onHoverTimerFired()
            return
        }

        hoverTimer = Timer.scheduledTimer(
            timeInterval: hoverDelay,
            target: self,
            selector: #selector(onHoverTimerFired),
            userInfo: nil,
            repeats: false
        )
    }

    override func mouseExited(with event: NSEvent) {
        hoverTimer?.invalidate()
        hoverTimer = nil
        onHoverExited()
    }

    override func mouseDown(with event: NSEvent) {
        onCommit()
    }

    @objc private func onHoverTimerFired() {
        hoverTimer = nil
        onHoverEntered()
    }
}
