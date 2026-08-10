import XCTest
@testable import MagicIsland

final class MediaFeatureTests: XCTestCase {
    func testMediaFeaturePublishesMediaActivityFromProviderSnapshot() {
        var engine = ActivityEngine()
        var feature = MediaFeature(provider: StubMediaProvider(snapshot: MediaSnapshot(
            appName: "Spotify",
            title: "Hemispheres",
            artist: "Lush",
            artworkData: Data([1, 2, 3]),
            playbackState: .playing,
            supportedControls: [.playPause, .next],
            duration: 240,
            position: 12
        )))

        feature.refresh(engine: &engine)

        guard case .media(let media) = engine.currentActivity()?.presentation else {
            return XCTFail("Expected media activity")
        }

        XCTAssertEqual(media.appName, "Spotify")
        XCTAssertEqual(media.title, "Hemispheres")
        XCTAssertEqual(media.artist, "Lush")
        XCTAssertEqual(media.artworkData, Data([1, 2, 3]))
        XCTAssertEqual(media.playbackState, .playing)
        XCTAssertTrue(media.supportedControls.contains(.playPause))
        XCTAssertTrue(media.supportedControls.contains(.next))
    }

    func testStoppedMediaRemovesMediaActivityAndRestoresPreviousActivity() {
        var engine = ActivityEngine()
        engine.publish(Activity(
            id: "sample",
            featureID: "sample",
            priority: 10,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .generic(title: "Sample", subtitle: "Waiting")
        ))
        var feature = MediaFeature(provider: StubMediaProvider(snapshot: MediaSnapshot(
            appName: "Spotify",
            title: "Hemispheres",
            artist: "Lush",
            artworkData: nil,
            playbackState: .stopped,
            supportedControls: [.playPause],
            duration: nil,
            position: nil
        )))

        feature.refresh(engine: &engine)

        XCTAssertEqual(engine.currentActivity()?.id, "sample")
    }

    func testProviderFailureDisablesOnlyMediaAndDoesNotCrashAppActivity() {
        var engine = ActivityEngine()
        engine.publish(Activity(
            id: "sample",
            featureID: "sample",
            priority: 10,
            startedAt: Date(),
            expiresAt: nil,
            presentation: .generic(title: "Sample", subtitle: "Still available")
        ))
        var feature = MediaFeature(provider: StubMediaProvider(error: StubMediaProvider.Error.failed))

        feature.refresh(engine: &engine)

        XCTAssertFalse(feature.isEnabled)
        XCTAssertEqual(engine.currentActivity()?.id, "sample")
    }

    func testMediaFeatureForwardsSupportedCommandsToProvider() {
        let provider = SpyMediaProvider()
        var feature = MediaFeature(provider: provider)

        feature.perform(.next)

        XCTAssertEqual(provider.performedCommands, [.next])
    }
}

private struct StubMediaProvider: MediaProviding {
    enum Error: Swift.Error {
        case failed
    }

    var snapshot: MediaSnapshot?
    var error: Swift.Error?
    var performedCommands: [MediaCommand] = []

    mutating func currentSnapshot() throws -> MediaSnapshot? {
        if let error {
            throw error
        }

        return snapshot
    }

    mutating func perform(_ command: MediaCommand) throws {
        if let error {
            throw error
        }

        performedCommands.append(command)
    }
}

private final class SpyMediaProvider: MediaProviding {
    var performedCommands: [MediaCommand] = []

    func currentSnapshot() throws -> MediaSnapshot? {
        nil
    }

    func perform(_ command: MediaCommand) throws {
        performedCommands.append(command)
    }
}
