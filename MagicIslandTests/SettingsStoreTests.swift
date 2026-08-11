import XCTest
@testable import MagicIsland

final class SettingsStoreTests: XCTestCase {
    func testHoverDelayAndSelectedDisplayPersistAcrossStoreInstances() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.hoverDelay = 0.45
        store.displayPreference = .specificDisplay(42)

        let reloadedStore = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloadedStore.hoverDelay, 0.45)
        XCTAssertEqual(reloadedStore.displayPreference, .specificDisplay(42))
    }

    func testClipboardRetentionDefaultsToSevenDaysAndPersistsChanges() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.clipboardRetentionDays, 7)

        store.clipboardRetentionDays = 14

        XCTAssertEqual(SettingsStore(defaults: defaults).clipboardRetentionDays, 14)
    }

    func testFeatureToggleDefaultsAndPersistence() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        XCTAssertFalse(store.isFeatureEnabled(.media))
        XCTAssertTrue(store.isFeatureEnabled(.fileShelf))
        XCTAssertTrue(store.isFeatureEnabled(.timer))
        XCTAssertTrue(store.isFeatureEnabled(.quickActions))
        XCTAssertFalse(store.isFeatureEnabled(.clipboardHistory))

        store.setFeature(.media, enabled: false)

        XCTAssertFalse(SettingsStore(defaults: defaults).isFeatureEnabled(.media))
    }

    func testPermissionGrantStateDefaultsAndPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.permissionGrantState(.spotifyAutomation), .notDetermined)

        store.setPermissionGrantState(.spotifyAutomation, .denied)

        XCTAssertEqual(SettingsStore(defaults: defaults).permissionGrantState(.spotifyAutomation), .denied)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "SettingsStoreTests.\(UUID().uuidString)")!
    }
}
