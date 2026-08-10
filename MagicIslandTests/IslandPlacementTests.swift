import CoreGraphics
import XCTest
@testable import MagicIsland

final class IslandPlacementTests: XCTestCase {
    func testPrimaryDisplayPrefersTheScreenAtTheMenuBarOrigin() {
        let externalDisplay = CGRect(x: -1512, y: 40, width: 1512, height: 982)
        let primaryDisplay = CGRect(x: 0, y: 0, width: 1728, height: 1117)

        let selectedFrame = IslandDisplaySelection.primaryDisplayFrame(
            from: [externalDisplay, primaryDisplay],
            mainScreenFrame: externalDisplay
        )

        XCTAssertEqual(selectedFrame, primaryDisplay)
    }

    func testPlaceholderAppearsAtTopCenterOfPrimaryDisplay() {
        let displayFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let islandSize = CGSize(width: 148, height: 38)

        let frame = IslandPlacement.placeholderFrame(
            in: displayFrame,
            islandSize: islandSize
        )

        XCTAssertEqual(frame, CGRect(x: 790, y: 1071, width: 148, height: 38))
    }

    func testPlacementRespectsDisplayOrigin() {
        let displayFrame = CGRect(x: -1512, y: 40, width: 1512, height: 982)
        let islandSize = CGSize(width: 148, height: 38)

        let frame = IslandPlacement.placeholderFrame(
            in: displayFrame,
            islandSize: islandSize
        )

        XCTAssertEqual(frame, CGRect(x: -830, y: 976, width: 148, height: 38))
    }
}
