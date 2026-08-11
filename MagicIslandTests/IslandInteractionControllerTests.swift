import XCTest
@testable import MagicIsland

final class IslandInteractionControllerTests: XCTestCase {
    func testHoverTriggersPeekWithoutInputFocus() {
        var controller = IslandInteractionController()

        let transition = controller.hoverEntered()

        XCTAssertEqual(controller.state, .peeking)
        XCTAssertEqual(transition.presentation, .peek)
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testClickOpensExpandedIslandAroundIdlePlaceholder() {
        var controller = IslandInteractionController()

        let transition = controller.click(currentActivity: nil)

        XCTAssertEqual(controller.state, .expanded)
        XCTAssertEqual(transition.presentation, .expanded(anchor: .idlePlaceholder))
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testClickOpensExpandedIslandAroundCurrentActivity() {
        var controller = IslandInteractionController()
        let activity = Activity(
            id: "media",
            featureID: "media",
            priority: 50,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .generic(title: "Now Playing", subtitle: "Current Activity")
        )

        let transition = controller.click(currentActivity: activity)

        XCTAssertEqual(controller.state, .expanded)
        XCTAssertEqual(transition.presentation, .expanded(anchor: .currentActivity(activity)))
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testShortcutOpensExpandedIsland() {
        var controller = IslandInteractionController()

        let transition = controller.shortcutPressed(currentActivity: nil)

        XCTAssertEqual(controller.state, .expanded)
        XCTAssertEqual(transition.presentation, .expanded(anchor: .idlePlaceholder))
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testExpandedIslandCanEnterInteractingWhenInputIsNeeded() {
        var controller = IslandInteractionController()
        _ = controller.click(currentActivity: nil)

        let transition = controller.beginInteracting()

        XCTAssertEqual(controller.state, .interacting)
        XCTAssertEqual(transition.presentation, .expanded(anchor: .idlePlaceholder))
        XCTAssertEqual(transition.focusBehavior, .inputAllowed)
    }

    func testCollapseReturnsToPassiveModeAndRestoresPassiveFocusBehavior() {
        var controller = IslandInteractionController()
        _ = controller.click(currentActivity: nil)
        _ = controller.beginInteracting()

        let collapsing = controller.collapse()
        let passive = controller.finishCollapse()

        XCTAssertEqual(collapsing.presentation, .collapsing)
        XCTAssertEqual(collapsing.focusBehavior, .passive)
        XCTAssertEqual(controller.state, .passive)
        XCTAssertEqual(passive.presentation, .passive)
        XCTAssertEqual(passive.focusBehavior, .passive)
    }

    func testHoverExitReturnsPeekToPassive() {
        var controller = IslandInteractionController()
        _ = controller.hoverEntered()

        let transition = controller.hoverExited()

        XCTAssertEqual(controller.state, .passive)
        XCTAssertEqual(transition.presentation, .passive)
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testDraggingFilesOverIslandShowsDragTargetFeedback() {
        var controller = IslandInteractionController()

        let transition = controller.dragEntered()

        XCTAssertEqual(controller.state, .dragTarget)
        XCTAssertEqual(transition.presentation, .dragTarget)
        XCTAssertEqual(transition.focusBehavior, .passive)
    }

    func testFinishingDragTargetReturnsToPassive() {
        var controller = IslandInteractionController()
        _ = controller.dragEntered()

        let transition = controller.dragExited()

        XCTAssertEqual(controller.state, .passive)
        XCTAssertEqual(transition.presentation, .passive)
    }

    func testRepeatedExpandCollapseReturnsToPassiveWithoutAccumulatingState() {
        var controller = IslandInteractionController()

        for _ in 0..<1_000 {
            _ = controller.hoverEntered()
            _ = controller.click(currentActivity: nil)
            _ = controller.beginInteracting()
            _ = controller.collapse()
            let transition = controller.finishCollapse()

            XCTAssertEqual(controller.state, .passive)
            XCTAssertEqual(transition.presentation, .passive)
            XCTAssertEqual(transition.focusBehavior, .passive)
        }
    }

    func testExpandedMediaKeyboardControlsFollowTransportOrderBeforeHomeNavigation() {
        let controls = ExpandedIslandKeyboardNavigation.controls(
            anchor: .currentActivity(mediaActivity()),
            selectedHomeDestination: nil,
            availableHomeDestinations: [.media, .fileShelf, .clipboardHistory, .timer, .settings],
            fileShelfItems: [],
            clipboardItems: [],
            quickActionsProvider: { _ in [] }
        )

        XCTAssertEqual(controls.map(\.accessibilityLabel), [
            "Previous track",
            "Play or pause media",
            "Next track",
            "Seek forward 15 seconds",
            "Media",
            "File Shelf",
            "Clipboard History",
            "Timer",
            "Settings"
        ])
        XCTAssertEqual(controls.map(\.activation).prefix(4), [
            .media(.previous),
            .media(.playPause),
            .media(.next),
            .media(.seek(15))
        ])
        XCTAssertGreaterThan(
            ExpandedIslandKeyboardNavigation.sortPriority(for: .media(.previous), in: controls),
            ExpandedIslandKeyboardNavigation.sortPriority(for: .media(.playPause), in: controls)
        )
        XCTAssertEqual(controls.map(\.group).prefix(4), [.media, .media, .media, .media])
    }

    func testExpandedTimerKeyboardControlsCoverStartAndRunningStates() {
        let startControls = ExpandedIslandKeyboardNavigation.controls(
            anchor: .idlePlaceholder,
            selectedHomeDestination: .timer,
            availableHomeDestinations: [.timer, .settings],
            fileShelfItems: [],
            clipboardItems: [],
            quickActionsProvider: { _ in [] }
        )

        XCTAssertEqual(startControls.map(\.accessibilityLabel), [
            "Start 5 minute timer",
            "Start 10 minute timer",
            "Start 25 minute timer",
            "Timer",
            "Settings"
        ])
        XCTAssertEqual(startControls.map(\.activation).prefix(3), [
            .timer(.start(5 * 60)),
            .timer(.start(10 * 60)),
            .timer(.start(25 * 60))
        ])

        let runningControls = ExpandedIslandKeyboardNavigation.controls(
            anchor: .currentActivity(timerActivity(state: .running)),
            selectedHomeDestination: .timer,
            availableHomeDestinations: [.timer, .settings],
            fileShelfItems: [],
            clipboardItems: [],
            quickActionsProvider: { _ in [] }
        )

        XCTAssertEqual(runningControls.map(\.accessibilityLabel), [
            "Pause timer",
            "Restart timer",
            "Cancel timer",
            "Close timer",
            "Timer",
            "Settings"
        ])
        XCTAssertEqual(runningControls.map(\.activation).prefix(4), [
            .timer(.pause),
            .timer(.restart),
            .timer(.cancel),
            .timer(.close)
        ])
    }

    func testExpandedFileShelfAndClipboardKeyboardControlsExposeQuickActionsAndDeletes() {
        let shelfItem = existingShelfItem()
        let clipboardItem = clipboardItem("Deploy notes")
        let quickActions: (QuickActionContext) -> [QuickAction] = { context in
            switch context {
            case .shelf:
                return [
                    QuickAction(id: .openFile, title: "Open", systemImageName: "arrow.up.right.square"),
                    QuickAction(id: .previewFile, title: "Preview", systemImageName: "eye")
                ]
            case .clipboard:
                return [
                    QuickAction(id: .copyText, title: "Copy", systemImageName: "doc.on.doc"),
                    QuickAction(id: .searchText, title: "Search Web", systemImageName: "magnifyingglass")
                ]
            }
        }

        let shelfControls = ExpandedIslandKeyboardNavigation.controls(
            anchor: .idlePlaceholder,
            selectedHomeDestination: .fileShelf,
            availableHomeDestinations: [.fileShelf, .settings],
            fileShelfItems: [shelfItem],
            clipboardItems: [],
            quickActionsProvider: quickActions
        )

        XCTAssertEqual(shelfControls.map(\.accessibilityLabel), [
            "Open",
            "Preview",
            "File Shelf",
            "Settings"
        ])
        XCTAssertEqual(shelfControls.map(\.activation).prefix(2), [
            .quickAction(.openFile, .shelf(shelfItem)),
            .quickAction(.previewFile, .shelf(shelfItem))
        ])

        let clipboardControls = ExpandedIslandKeyboardNavigation.controls(
            anchor: .idlePlaceholder,
            selectedHomeDestination: .clipboardHistory,
            availableHomeDestinations: [.clipboardHistory, .settings],
            fileShelfItems: [],
            clipboardItems: [clipboardItem],
            quickActionsProvider: quickActions
        )

        XCTAssertEqual(clipboardControls.map(\.accessibilityLabel), [
            "Copy",
            "Search Web",
            "Delete Deploy notes",
            "Clipboard History",
            "Settings"
        ])
        XCTAssertEqual(clipboardControls.map(\.activation).prefix(3), [
            .quickAction(.copyText, .clipboard(clipboardItem)),
            .quickAction(.searchText, .clipboard(clipboardItem)),
            .deleteClipboardItem(clipboardItem.id)
        ])
    }

    func testPermissionCenterRowsExposeSingleKeyboardReadableLabel() {
        let item = PermissionCenterItem(
            id: .spotifyAutomation,
            title: "Spotify Automation",
            state: .notDetermined,
            stateDescription: "Last known state",
            purpose: "Control Spotify playback and read the current track for the Media Feature.",
            featureID: .media,
            revokeGuidance: "System Settings > Privacy & Security > Automation > Magic Island > Spotify"
        )

        XCTAssertEqual(
            item.keyboardAccessibilityLabel,
            "Spotify Automation, Not Requested, Media. Control Spotify playback and read the current track for the Media Feature. Revoke in System Settings > Privacy & Security > Automation > Magic Island > Spotify"
        )
    }

    private func mediaActivity() -> Activity {
        Activity(
            id: "media.current",
            featureID: "media",
            priority: 50,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .media(MediaActivity(snapshot: MediaSnapshot(
                appName: "Spotify",
                title: "Hemispheres",
                artist: "Lush",
                artworkData: nil,
                playbackState: .playing,
                supportedControls: [.previous, .playPause, .next, .seek],
                duration: 240,
                position: 12
            )))
        )
    }

    private func timerActivity(state: TimerActivityState) -> Activity {
        Activity(
            id: "timer.current",
            featureID: "timer",
            priority: 40,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .timer(TimerActivity(state: state, remainingTime: 60, duration: 300))
        )
    }

    private func clipboardItem(_ title: String) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            id: UUID(),
            type: .text,
            title: title,
            contentHash: title,
            addedAt: Date(),
            text: title,
            fileURL: nil,
            imageData: nil
        )
    }

    private func existingShelfItem() -> ShelfItem {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyboard-nav-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: url.path, contents: Data("test".utf8))
        return ShelfItem(
            id: UUID(),
            url: url,
            name: url.lastPathComponent,
            typeDescription: "TXT",
            storageMode: .reference,
            addedAt: Date()
        )
    }
}
