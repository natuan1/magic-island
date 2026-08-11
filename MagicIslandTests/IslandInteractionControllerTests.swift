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
}
