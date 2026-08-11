import AppKit
import SwiftUI

@MainActor
final class IslandWindowController {
    static let placeholderSize = IslandPlacement.floatingIslandSize

    private let panel: IslandPanel
    private let settingsStore: SettingsStore
    private let motionPreferenceProvider: MotionPreferenceProviding
    private let currentActivityProvider: @MainActor () -> CurrentActivity?
    private let mediaCommandHandler: @MainActor (MediaCommand) -> Void
    private let timerCommandHandler: @MainActor (TimerCommand) -> Void
    private let fileShelfItemsProvider: @MainActor () -> [ShelfItem]
    private let fileDropHandler: @MainActor ([URL]) -> Void
    private let shelfRevealHandler: @MainActor (UUID) -> Void
    private let clipboardItemsProvider: @MainActor () -> [ClipboardHistoryItem]
    private let clipboardCopyHandler: @MainActor (UUID) -> Void
    private let clipboardDeleteHandler: @MainActor (UUID) -> Void
    private let quickActionsProvider: @MainActor (QuickActionContext) -> [QuickAction]
    private let quickActionHandler: @MainActor (QuickActionID, QuickActionContext) -> QuickActionResult
    private var interactionController = IslandInteractionController()
    private var shortcutController: IslandShortcutController?
    private var currentPresentation: IslandPresentation = .passive
    private var selectedHomeDestination: HomeDestination?

    init(
        settingsStore: SettingsStore = SettingsStore(),
        screenProvider: @MainActor () -> NSScreen? = IslandWindowController.primaryDisplay,
        motionPreferenceProvider: MotionPreferenceProviding = SystemMotionPreferenceProvider(),
        currentActivityProvider: @escaping @MainActor () -> CurrentActivity? = { nil },
        mediaCommandHandler: @escaping @MainActor (MediaCommand) -> Void = { _ in },
        timerCommandHandler: @escaping @MainActor (TimerCommand) -> Void = { _ in },
        fileShelfItemsProvider: @escaping @MainActor () -> [ShelfItem] = { [] },
        fileDropHandler: @escaping @MainActor ([URL]) -> Void = { _ in },
        shelfRevealHandler: @escaping @MainActor (UUID) -> Void = { _ in },
        clipboardItemsProvider: @escaping @MainActor () -> [ClipboardHistoryItem] = { [] },
        clipboardCopyHandler: @escaping @MainActor (UUID) -> Void = { _ in },
        clipboardDeleteHandler: @escaping @MainActor (UUID) -> Void = { _ in },
        quickActionsProvider: @escaping @MainActor (QuickActionContext) -> [QuickAction] = { _ in [] },
        quickActionHandler: @escaping @MainActor (QuickActionID, QuickActionContext) -> QuickActionResult = { _, _ in .failure("Action unavailable") }
    ) {
        self.settingsStore = settingsStore
        self.motionPreferenceProvider = motionPreferenceProvider
        self.currentActivityProvider = currentActivityProvider
        self.mediaCommandHandler = mediaCommandHandler
        self.timerCommandHandler = timerCommandHandler
        self.fileShelfItemsProvider = fileShelfItemsProvider
        self.fileDropHandler = fileDropHandler
        self.shelfRevealHandler = shelfRevealHandler
        self.clipboardItemsProvider = clipboardItemsProvider
        self.clipboardCopyHandler = clipboardCopyHandler
        self.clipboardDeleteHandler = clipboardDeleteHandler
        self.quickActionsProvider = quickActionsProvider
        self.quickActionHandler = quickActionHandler

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
                onMediaCommand: mediaCommandHandler,
                onTimerCommand: timerCommandHandler,
                availableHomeDestinations: availableHomeDestinations(),
                fileShelfItems: fileShelfItemsProvider(),
                onHomeSelection: { [weak self] destination in
                    self?.selectHomeDestination(destination)
                },
                onRevealShelfItem: shelfRevealHandler,
                clipboardItems: clipboardItemsProvider(),
                onCopyClipboardItem: clipboardCopyHandler,
                onDeleteClipboardItem: clipboardDeleteHandler,
                quickActionsProvider: quickActionsProvider,
                quickActionHandler: quickActionHandler
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
            },
            onDragEntered: { [weak self] in
                guard self?.canUseFileShelf() == true else {
                    return
                }
                self?.apply(self?.interactionController.dragEntered())
            },
            onDragExited: { [weak self] in
                self?.apply(self?.interactionController.dragExited())
            },
            onFilesDropped: { [weak self] urls in
                self?.finishFileDrop(urls)
            },
            canAcceptFiles: { [weak self] in
                self?.canUseFileShelf() == true
            }
        )

        configureShortcutController()
    }

    private func configureShortcutController() {
        shortcutController = IslandShortcutController(
            shortcut: settingsStore.expansionShortcut,
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
        case .passive, .peek, .dragTarget, .collapsing:
            break
        }

        let size = IslandPresentationLayout.size(for: currentPresentation)
        panel.contentView = makeContentView(size: size, presentation: currentPresentation)
    }

    func showFileShelf() {
        selectedHomeDestination = .fileShelf
        let transition = interactionController.click(currentActivity: currentActivityProvider())
        apply(transition)
    }

    func showFeature(_ featureID: FeatureID) {
        switch featureID {
        case .media:
            selectedHomeDestination = .media
        case .fileShelf:
            selectedHomeDestination = .fileShelf
        case .clipboardHistory:
            selectedHomeDestination = .clipboardHistory
        case .timer:
            selectedHomeDestination = .timer
        case .quickActions:
            break
        }
        apply(interactionController.click(currentActivity: currentActivityProvider()))
    }

    func settingsChanged() {
        let screen = Self.selectedDisplay(settingsStore: settingsStore) ?? Self.primaryDisplay()
        let placement = IslandPlacement.frame(
            for: screen.map(Self.displayDescriptor) ?? Self.fallbackDisplayDescriptor
        )
        let size = IslandPresentationLayout.size(for: currentPresentation)
        panel.setFrame(
            CGRect(
                x: placement.frame.midX - (size.width / 2),
                y: placement.frame.maxY - size.height,
                width: size.width,
                height: size.height
            ),
            display: true,
            animate: motionPolicy.animatesGeometryChanges
        )
        configureShortcutController()
        panel.contentView = makeContentView(size: size, presentation: currentPresentation)
    }

    private func commitFromClick() {
        selectedHomeDestination = nil
        let transition = interactionController.click(
            currentActivity: currentActivityProvider()
        )
        apply(transition)
    }

    private func commitFromShortcut() {
        selectedHomeDestination = nil
        let transition = interactionController.shortcutPressed(
            currentActivity: currentActivityProvider()
        )
        apply(transition)
    }

    private func collapse() {
        apply(interactionController.collapse())
        apply(interactionController.finishCollapse())
    }

    private func selectHomeDestination(_ destination: HomeDestination) {
        guard availableHomeDestinations().contains(destination) else {
            return
        }

        selectedHomeDestination = destination
        apply(interactionController.beginInteracting())
    }

    private func finishFileDrop(_ urls: [URL]) {
        apply(interactionController.dragExited())
        fileDropHandler(urls)
    }

    private func canUseFileShelf() -> Bool {
        settingsStore.isFeatureEnabled(.fileShelf)
    }

    private func availableHomeDestinations() -> [HomeDestination] {
        var destinations: [HomeDestination] = []
        if settingsStore.isFeatureEnabled(.media) {
            destinations.append(.media)
        }
        if settingsStore.isFeatureEnabled(.fileShelf) {
            destinations.append(.fileShelf)
        }
        if settingsStore.isFeatureEnabled(.clipboardHistory) {
            destinations.append(.clipboardHistory)
        }
        if settingsStore.isFeatureEnabled(.timer) {
            destinations.append(.timer)
        }
        destinations.append(.settings)
        return destinations
    }

    private func apply(_ transition: IslandTransition?) {
        guard let transition else {
            return
        }

        panel.allowsInputFocus = transition.focusBehavior == .inputAllowed

        currentPresentation = transition.presentation
        let size = IslandPresentationLayout.size(for: transition.presentation)
        panel.setFrame(frame(for: size), display: true, animate: motionPolicy.animatesGeometryChanges)
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
                onMediaCommand: mediaCommandHandler,
                onTimerCommand: timerCommandHandler,
                selectedHomeDestination: selectedHomeDestination,
                availableHomeDestinations: availableHomeDestinations(),
                fileShelfItems: fileShelfItemsProvider(),
                onHomeSelection: { [weak self] destination in
                    self?.selectHomeDestination(destination)
                },
                onRevealShelfItem: shelfRevealHandler,
                clipboardItems: clipboardItemsProvider(),
                onCopyClipboardItem: clipboardCopyHandler,
                onDeleteClipboardItem: clipboardDeleteHandler,
                quickActionsProvider: quickActionsProvider,
                quickActionHandler: quickActionHandler
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
            },
            onDragEntered: { [weak self] in
                guard self?.canUseFileShelf() == true else {
                    return
                }
                self?.apply(self?.interactionController.dragEntered())
            },
            onDragExited: { [weak self] in
                self?.apply(self?.interactionController.dragExited())
            },
            onFilesDropped: { [weak self] urls in
                self?.finishFileDrop(urls)
            },
            canAcceptFiles: { [weak self] in
                self?.canUseFileShelf() == true
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

    private var motionPolicy: IslandMotionPolicy {
        IslandMotionPolicy(reduceMotionEnabled: motionPreferenceProvider.reduceMotionEnabled)
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
    private let onDragEntered: @MainActor () -> Void
    private let onDragExited: @MainActor () -> Void
    private let onFilesDropped: @MainActor ([URL]) -> Void
    private let canAcceptFiles: @MainActor () -> Bool
    private var hoverTimer: Timer?

    deinit {
        MainActor.assumeIsolated {
            hoverTimer?.invalidate()
        }
    }

    init(
        rootView: Content,
        hoverDelay: TimeInterval,
        onHoverEntered: @escaping @MainActor () -> Void,
        onHoverExited: @escaping @MainActor () -> Void,
        onCommit: @escaping @MainActor () -> Void,
        onDragEntered: @escaping @MainActor () -> Void,
        onDragExited: @escaping @MainActor () -> Void,
        onFilesDropped: @escaping @MainActor ([URL]) -> Void,
        canAcceptFiles: @escaping @MainActor () -> Bool
    ) {
        self.hoverDelay = hoverDelay
        self.onHoverEntered = onHoverEntered
        self.onHoverExited = onHoverExited
        self.onCommit = onCommit
        self.onDragEntered = onDragEntered
        self.onDragExited = onDragExited
        self.onFilesDropped = onFilesDropped
        self.canAcceptFiles = canAcceptFiles
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }

    required init(rootView: Content) {
        hoverDelay = 0
        onHoverEntered = {}
        onHoverExited = {}
        onCommit = {}
        onDragEntered = {}
        onDragExited = {}
        onFilesDropped = { _ in }
        canAcceptFiles = { false }
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
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

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard canAcceptFiles(), fileURLs(from: sender).isEmpty == false else {
            return []
        }

        onDragEntered()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = canAcceptFiles() ? fileURLs(from: sender) : []
        guard urls.isEmpty == false else {
            onDragExited()
            return false
        }

        onFilesDropped(urls)
        return true
    }

    @objc private func onHoverTimerFired() {
        hoverTimer = nil
        onHoverEntered()
    }

    private func fileURLs(from sender: NSDraggingInfo) -> [URL] {
        sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
    }
}
