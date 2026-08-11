import Foundation

enum TimerCommand: Equatable {
    case start(TimeInterval)
    case pause
    case resume
    case cancel
    case restart
    case close
}

enum TimerActivityState: Equatable {
    case running
    case paused
    case completed
}

struct TimerActivity: Equatable {
    let state: TimerActivityState
    let remainingTime: TimeInterval
    let duration: TimeInterval
}

enum TimerDurationFormatter {
    static func string(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.up)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TimerFeature {
    static let featureID = "timer"
    static let activityID = "timer.current"

    private enum Session: Equatable {
        case running(duration: TimeInterval, startedAt: Date, endsAt: Date)
        case paused(duration: TimeInterval, startedAt: Date, remainingTime: TimeInterval)
        case completed(duration: TimeInterval, startedAt: Date, completedAt: Date)

        var duration: TimeInterval {
            switch self {
            case .running(let duration, _, _),
                 .paused(let duration, _, _),
                 .completed(let duration, _, _):
                return duration
            }
        }
    }

    private var session: Session?

    var isActive: Bool {
        session != nil
    }

    mutating func start(duration: TimeInterval, now: Date = Date(), engine: inout ActivityEngine) {
        let clampedDuration = max(1, duration)
        session = .running(
            duration: clampedDuration,
            startedAt: now,
            endsAt: now.addingTimeInterval(clampedDuration)
        )
        publish(now: now, engine: &engine)
    }

    mutating func pause(now: Date = Date(), engine: inout ActivityEngine) {
        guard case .running(let duration, let startedAt, let endsAt) = session else {
            return
        }

        session = .paused(
            duration: duration,
            startedAt: startedAt,
            remainingTime: max(0, endsAt.timeIntervalSince(now))
        )
        publish(now: now, engine: &engine)
    }

    mutating func resume(now: Date = Date(), engine: inout ActivityEngine) {
        guard case .paused(let duration, let startedAt, let remainingTime) = session else {
            return
        }

        session = .running(
            duration: duration,
            startedAt: startedAt,
            endsAt: now.addingTimeInterval(remainingTime)
        )
        publish(now: now, engine: &engine)
    }

    mutating func cancel(engine: inout ActivityEngine) {
        session = nil
        engine.removeActivity(id: Self.activityID)
    }

    mutating func close(engine: inout ActivityEngine) {
        session = nil
        engine.removeActivity(id: Self.activityID)
    }

    mutating func restart(now: Date = Date(), engine: inout ActivityEngine) {
        let duration = session?.duration ?? 300
        start(duration: duration, now: now, engine: &engine)
    }

    mutating func refresh(now: Date = Date(), engine: inout ActivityEngine) {
        if case .running(let duration, let startedAt, let endsAt) = session,
           endsAt <= now {
            session = .completed(duration: duration, startedAt: startedAt, completedAt: endsAt)
        }

        publish(now: now, engine: &engine)
    }

    mutating func perform(_ command: TimerCommand, now: Date = Date(), engine: inout ActivityEngine) {
        switch command {
        case .start(let duration):
            start(duration: duration, now: now, engine: &engine)
        case .pause:
            pause(now: now, engine: &engine)
        case .resume:
            resume(now: now, engine: &engine)
        case .cancel:
            cancel(engine: &engine)
        case .restart:
            restart(now: now, engine: &engine)
        case .close:
            close(engine: &engine)
        }
    }

    private func publish(now: Date, engine: inout ActivityEngine) {
        guard let session else {
            engine.removeActivity(id: Self.activityID)
            return
        }

        let activity: TimerActivity
        let priority: Int
        let startedAt: Date

        switch session {
        case .running(let duration, let started, let endsAt):
            activity = TimerActivity(
                state: .running,
                remainingTime: max(0, endsAt.timeIntervalSince(now)),
                duration: duration
            )
            priority = 40
            startedAt = started
        case .paused(let duration, let started, let remainingTime):
            activity = TimerActivity(
                state: .paused,
                remainingTime: max(0, remainingTime),
                duration: duration
            )
            priority = 40
            startedAt = started
        case .completed(let duration, let started, _):
            activity = TimerActivity(
                state: .completed,
                remainingTime: 0,
                duration: duration
            )
            priority = 100
            startedAt = started
        }

        engine.publish(Activity(
            id: Self.activityID,
            featureID: Self.featureID,
            priority: priority,
            startedAt: startedAt,
            expiresAt: nil,
            presentation: .timer(activity)
        ))
    }
}
