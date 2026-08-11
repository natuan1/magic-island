import XCTest
@testable import MagicIsland

final class PermissionCenterTests: XCTestCase {
    func testPermissionCenterShowsPurposeFeatureStateAndRevokeGuidance() {
        let defaults = UserDefaults(suiteName: "PermissionCenterTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setPermissionGrantState(.spotifyAutomation, .denied)

        let items = PermissionCenter.items(settingsStore: settingsStore, authorizer: StaticPermissionAuthorizer())

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, .spotifyAutomation)
        XCTAssertEqual(items[0].state, .denied)
        XCTAssertEqual(
            items[0].stateDescription,
            "Last known state. Unknown also covers Spotify not running or Automation not requested yet. Magic Island checks without prompting in Settings."
        )
        XCTAssertEqual(items[0].featureID, .media)
        XCTAssertEqual(items[0].purpose, "Control Spotify playback and read the current track for the Media Feature.")
        XCTAssertEqual(items[0].revokeGuidance, "System Settings > Privacy & Security > Automation > Magic Island > Spotify")
    }

    func testNativeAuthorizerTreatsSpotifyNotRunningAsUnknownWithoutPromptState() {
        let authorizer = NativePermissionAuthorizer(runningApplicationProvider: { bundleIdentifier in
            XCTAssertEqual(bundleIdentifier, "com.spotify.client")
            return nil
        })

        XCTAssertEqual(authorizer.currentGrantState(for: .spotifyAutomation), .notDetermined)
        XCTAssertEqual(authorizer.requestGrant(for: .spotifyAutomation), .notDetermined)
        XCTAssertEqual(PermissionGrantState.notDetermined.title, "Unknown / Not Requested")
    }
}

private struct StaticPermissionAuthorizer: PermissionAuthorizing {
    func currentGrantState(for permissionID: PermissionID) -> PermissionGrantState {
        .notDetermined
    }

    func requestGrant(for permissionID: PermissionID) -> PermissionGrantState {
        .notDetermined
    }
}
