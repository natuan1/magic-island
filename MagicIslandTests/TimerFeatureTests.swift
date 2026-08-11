import XCTest
@testable import MagicIsland

final class TimerFeatureTests: XCTestCase {
    func testRunningTimerPublishesRemainingTimeFromAbsoluteEndDate() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        feature.start(duration: 300, now: now, engine: &engine)
        feature.refresh(now: now.addingTimeInterval(120), engine: &engine)

        let activity = engine.currentActivity(at: now.addingTimeInterval(120))
        XCTAssertEqual(activity?.title, "Timer")
        XCTAssertEqual(timerActivity(activity)?.state, .running)
        XCTAssertEqual(timerActivity(activity)?.remainingTime, 180)
    }

    func testPausedTimerKeepsRemainingTimeWhileClockAdvances() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        feature.start(duration: 300, now: now, engine: &engine)
        feature.pause(now: now.addingTimeInterval(90), engine: &engine)
        feature.refresh(now: now.addingTimeInterval(240), engine: &engine)

        let timer = timerActivity(engine.currentActivity(at: now.addingTimeInterval(240)))
        XCTAssertEqual(timer?.state, .paused)
        XCTAssertEqual(timer?.remainingTime, 210)
    }

    func testResumeRebasesEndDateFromPausedRemainingTime() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        feature.start(duration: 300, now: now, engine: &engine)
        feature.pause(now: now.addingTimeInterval(90), engine: &engine)
        feature.resume(now: now.addingTimeInterval(200), engine: &engine)
        feature.refresh(now: now.addingTimeInterval(260), engine: &engine)

        let timer = timerActivity(engine.currentActivity(at: now.addingTimeInterval(260)))
        XCTAssertEqual(timer?.state, .running)
        XCTAssertEqual(timer?.remainingTime, 150)
    }

    func testCompletionOutranksMediaAndRemovalRestoresPreviousActivity() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        engine.publish(Activity(
            id: MediaFeature<StubMediaProvider>.activityID,
            featureID: MediaFeature<StubMediaProvider>.featureID,
            priority: 50,
            startedAt: now,
            expiresAt: nil,
            presentation: .media(MediaActivity(snapshot: MediaSnapshot(
                appName: "Spotify",
                title: "Song",
                artist: "Artist",
                artworkData: nil,
                playbackState: .playing,
                supportedControls: [.playPause],
                duration: nil,
                position: nil
            )))
        ))
        feature.start(duration: 60, now: now, engine: &engine)
        feature.refresh(now: now.addingTimeInterval(61), engine: &engine)

        XCTAssertEqual(engine.currentActivity(at: now.addingTimeInterval(61))?.id, TimerFeature.activityID)
        XCTAssertEqual(timerActivity(engine.currentActivity(at: now.addingTimeInterval(61)))?.state, .completed)

        feature.close(engine: &engine)

        XCTAssertEqual(engine.currentActivity(at: now.addingTimeInterval(62))?.id, MediaFeature<StubMediaProvider>.activityID)
    }

    func testRunningTimerDoesNotOutrankMediaUntilCompletion() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        engine.publish(Activity(
            id: MediaFeature<StubMediaProvider>.activityID,
            featureID: MediaFeature<StubMediaProvider>.featureID,
            priority: 50,
            startedAt: now,
            expiresAt: nil,
            presentation: .media(MediaActivity(snapshot: MediaSnapshot(
                appName: "Spotify",
                title: "Song",
                artist: "Artist",
                artworkData: nil,
                playbackState: .playing,
                supportedControls: [.playPause],
                duration: nil,
                position: nil
            )))
        ))

        feature.start(duration: 60, now: now, engine: &engine)

        XCTAssertEqual(engine.currentActivity(at: now)?.id, MediaFeature<StubMediaProvider>.activityID)
    }

    func testRestartStartsNewTimerAfterCompletion() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        feature.start(duration: 60, now: now, engine: &engine)
        feature.refresh(now: now.addingTimeInterval(61), engine: &engine)
        feature.restart(now: now.addingTimeInterval(70), engine: &engine)

        let timer = timerActivity(engine.currentActivity(at: now.addingTimeInterval(70)))
        XCTAssertEqual(timer?.state, .running)
        XCTAssertEqual(timer?.remainingTime, 60)
    }

    func testSleepWakeCompletesFromAbsoluteTimestamp() {
        var feature = TimerFeature()
        var engine = ActivityEngine()
        let now = Date(timeIntervalSince1970: 1_000)

        feature.start(duration: 120, now: now, engine: &engine)
        feature.refresh(now: now.addingTimeInterval(3_600), engine: &engine)

        let timer = timerActivity(engine.currentActivity(at: now.addingTimeInterval(3_600)))
        XCTAssertEqual(timer?.state, .completed)
        XCTAssertEqual(timer?.remainingTime, 0)
    }

    private func timerActivity(_ activity: Activity?) -> TimerActivity? {
        guard case .timer(let timer) = activity?.presentation else {
            return nil
        }

        return timer
    }
}

private struct StubMediaProvider: MediaProviding {
    mutating func currentSnapshot() throws -> MediaSnapshot? { nil }
}
