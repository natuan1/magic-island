import XCTest
@testable import MagicIsland

final class ActivityEngineTests: XCTestCase {
    func testSampleFeatureCanPublishAndRemoveActivity() {
        var engine = ActivityEngine()
        let sampleFeature = SampleFeature()

        sampleFeature.publishActivity(
            title: "Build finished",
            subtitle: "All checks passed",
            engine: &engine
        )

        XCTAssertEqual(engine.currentActivity()?.title, "Build finished")

        sampleFeature.removeActivity(engine: &engine)

        XCTAssertNil(engine.currentActivity())
    }

    func testHigherPriorityActivityBecomesCurrentActivity() {
        var engine = ActivityEngine()
        let now = Date()

        engine.publish(activity(id: "low", priority: 10, startedAt: now))
        engine.publish(activity(id: "high", priority: 90, startedAt: now.addingTimeInterval(1)))

        XCTAssertEqual(engine.currentActivity()?.id, "high")
    }

    func testExpiredActivityIsNotCurrentActivity() {
        var engine = ActivityEngine()
        let now = Date()

        engine.publish(Activity(
            id: "timer.done",
            featureID: "timer",
            priority: 100,
            startedAt: now.addingTimeInterval(-20),
            expiresAt: now.addingTimeInterval(-1),
            presentation: .generic(title: "Timer", subtitle: "Done")
        ))

        XCTAssertNil(engine.currentActivity(at: now))
    }

    func testInterruptionRestoresPreviousCurrentActivityWhenRemoved() {
        var engine = ActivityEngine()
        let now = Date()

        engine.publish(activity(id: "media", priority: 50, startedAt: now))
        engine.publish(activity(id: "timer", priority: 100, startedAt: now.addingTimeInterval(1)))

        XCTAssertEqual(engine.currentActivity()?.id, "timer")

        engine.removeActivity(id: "timer")

        XCTAssertEqual(engine.currentActivity()?.id, "media")
    }

    private func activity(id: String, priority: Int, startedAt: Date) -> Activity {
        Activity(
            id: id,
            featureID: id,
            priority: priority,
            startedAt: startedAt,
            expiresAt: nil,
            presentation: .generic(title: id, subtitle: "Test")
        )
    }
}

