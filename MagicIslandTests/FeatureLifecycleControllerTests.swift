import XCTest
@testable import MagicIsland

final class FeatureLifecycleControllerTests: XCTestCase {
    func testDisabledFeatureStopsLifecycleAndRemovesActivities() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        var controller = FeatureLifecycleController(
            settingsStore: settingsStore,
            permissionAuthorizer: SpyPermissionAuthorizer(currentResult: .granted)
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

    func testNotDeterminedPermissionStartsFeatureWithoutPrompting() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        let authorizer = SpyPermissionAuthorizer(currentResult: .notDetermined)
        var controller = FeatureLifecycleController(settingsStore: settingsStore, permissionAuthorizer: authorizer)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertTrue(authorizer.requestedPermissions.isEmpty)
        XCTAssertTrue(started.contains(.media))
        XCTAssertTrue(settingsStore.isFeatureEnabled(.media))
        XCTAssertEqual(settingsStore.permissionGrantState(.spotifyAutomation), .notDetermined)
    }

    func testGrantedPermissionStartsFeatureAndPersistsGrant() {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        let authorizer = SpyPermissionAuthorizer(currentResult: .granted)
        var controller = FeatureLifecycleController(settingsStore: settingsStore, permissionAuthorizer: authorizer)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertTrue(authorizer.requestedPermissions.isEmpty)
        XCTAssertTrue(started.contains(.media))
        XCTAssertEqual(settingsStore.permissionGrantState(.spotifyAutomation), .granted)
    }

    func testDeniedPermissionKeepsFeatureDisabledWithoutPrompting() {
        assertPermissionStateDisablesMedia(.denied)
    }

    func testUnavailablePermissionKeepsFeatureDisabledWithoutPrompting() {
        assertPermissionStateDisablesMedia(.unavailable)
    }

    private func assertPermissionStateDisablesMedia(
        _ permissionState: PermissionGrantState,
        line: UInt = #line
    ) {
        let defaults = UserDefaults(suiteName: "FeatureLifecycleControllerTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.media, enabled: true)
        let authorizer = SpyPermissionAuthorizer(currentResult: permissionState)
        var controller = FeatureLifecycleController(settingsStore: settingsStore, permissionAuthorizer: authorizer)
        var engine = ActivityEngine()
        var started: [FeatureID] = []

        controller.sync(engine: &engine, startFeature: { started.append($0) }, stopFeature: { _ in })

        XCTAssertTrue(authorizer.requestedPermissions.isEmpty, line: line)
        XCTAssertFalse(settingsStore.isFeatureEnabled(.media))
        XCTAssertFalse(started.contains(.media), line: line)
        XCTAssertEqual(settingsStore.permissionGrantState(.spotifyAutomation), permissionState, line: line)
    }
}

private final class SpyPermissionAuthorizer: PermissionAuthorizing {
    private let currentResult: PermissionGrantState
    private let requestResult: PermissionGrantState
    private(set) var requestedPermissions: [PermissionID] = []

    init(
        currentResult: PermissionGrantState,
        requestResult: PermissionGrantState = .notDetermined
    ) {
        self.currentResult = currentResult
        self.requestResult = requestResult
    }

    func currentGrantState(for permissionID: PermissionID) -> PermissionGrantState {
        currentResult
    }

    func requestGrant(for permissionID: PermissionID) -> PermissionGrantState {
        requestedPermissions.append(permissionID)
        return requestResult
    }
}
