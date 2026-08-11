import XCTest
@testable import MagicIsland

final class FeatureLifecycleControllerTests: XCTestCase {
    func testDisabledFeatureStopsLifecycleAndRemovesActivities() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        var controller = FeatureLifecycleController(
            settingsStore: settingsStore,
            permissionAuthorizer: SpyPermissionAuthorizer(requestResult: .granted)
        )
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

        XCTAssertEqual(started.filter { $0 == .fileShelf }.count, 1)
    }

    func testPermissionedFeatureRequestsPermissionJustInTimeWhenEnabled() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        let authorizer = SpyPermissionAuthorizer(requestResult: .granted)
        var controller = FeatureLifecycleController(settingsStore: settingsStore, permissionAuthorizer: authorizer)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertEqual(authorizer.requestedPermissions, [.spotifyAutomation])
        XCTAssertTrue(started.contains(.media))
        XCTAssertEqual(settingsStore.permissionGrantState(.spotifyAutomation), .granted)
    }

    func testDeniedPermissionKeepsFeatureDisabledWithoutRepeatedPrompts() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        let authorizer = SpyPermissionAuthorizer(requestResult: .denied)
        var controller = FeatureLifecycleController(settingsStore: settingsStore, permissionAuthorizer: authorizer)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })
        settingsStore.setFeature(.media, enabled: true)
        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertEqual(authorizer.requestedPermissions, [.spotifyAutomation])
        XCTAssertFalse(settingsStore.isFeatureEnabled(.media))
        XCTAssertFalse(started.contains(.media))
    }
}

private final class SpyPermissionAuthorizer: PermissionAuthorizing {
    private let requestResult: PermissionGrantState
    private(set) var requestedPermissions: [PermissionID] = []

    init(requestResult: PermissionGrantState) {
        self.requestResult = requestResult
    }

    func currentGrantState(for permissionID: PermissionID) -> PermissionGrantState {
        requestedPermissions.contains(permissionID) ? requestResult : .notDetermined
    }

    func requestGrant(for permissionID: PermissionID) -> PermissionGrantState {
        requestedPermissions.append(permissionID)
        return requestResult
    }
}
