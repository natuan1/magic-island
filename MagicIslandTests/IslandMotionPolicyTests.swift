import XCTest
@testable import MagicIsland

final class IslandMotionPolicyTests: XCTestCase {
    func testStandardMotionAnimatesGeometryChanges() {
        let policy = IslandMotionPolicy(reduceMotionEnabled: false)

        XCTAssertTrue(policy.animatesGeometryChanges)
    }

    func testReduceMotionDisablesGeometryAnimationWithoutChangingPresentationSizing() {
        let policy = IslandMotionPolicy(reduceMotionEnabled: true)

        XCTAssertFalse(policy.animatesGeometryChanges)
        XCTAssertEqual(IslandPresentationLayout.size(for: .peek), CGSize(width: 184, height: 46))
        XCTAssertEqual(IslandPresentationLayout.size(for: .expanded(anchor: .idlePlaceholder)), CGSize(width: 420, height: 220))
    }
}
