import XCTest
@testable import MagicIsland

final class FeatureLifecycleControllerTests: XCTestCase {
    func testDisabledFeatureStopsLifecycleAndRemovesActivities() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        var controller = FeatureLifecycleController(settingsStore: settingsStore)
        var engine = ActivityEngine()
        var started: [FeatureID] = []
        var stopped: [FeatureID] = []

        controller.sync(
            engine: &engine,
            startFeature: { started.append($0) },
            stopFeature: { stopped.append($0) }
        )
        engine.publish(Activity(
            id: "media.current",
            featureID: FeatureID.media.rawValue,
            priority: 50,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .generic(title: "Media", subtitle: "Playing")
        ))

        settingsStore.setFeature(.media, enabled: false)
        controller.sync(
            engine: &engine,
            startFeature: { started.append($0) },
            stopFeature: { stopped.append($0) }
        )

        XCTAssertTrue(started.contains(.media))
        XCTAssertTrue(stopped.contains(.media))
        XCTAssertNil(engine.currentActivity())
    }

    func testAlreadyRunningEnabledFeatureDoesNotStartTwice() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        var controller = FeatureLifecycleController(settingsStore: settingsStore)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })
        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertEqual(started.filter { $0 == .media }.count, 1)
    }
}
