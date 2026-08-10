import Foundation

struct Activity: Equatable, Identifiable {
    let id: String
    let featureID: String
    let priority: Int
    let startedAt: Date
    let expiresAt: Date?
    let presentation: ActivityPresentation

    var title: String {
        presentation.title
    }

    var subtitle: String {
        presentation.subtitle
    }

    func isExpired(at now: Date) -> Bool {
        guard let expiresAt else {
            return false
        }

        return expiresAt <= now
    }
}

enum ActivityPresentation: Equatable {
    case generic(title: String, subtitle: String)
    case media(MediaActivity)

    var title: String {
        switch self {
        case .generic(let title, _):
            return title
        case .media(let media):
            return media.title
        }
    }

    var subtitle: String {
        switch self {
        case .generic(_, let subtitle):
            return subtitle
        case .media(let media):
            return [media.artist, media.appName]
                .filter { !$0.isEmpty }
                .joined(separator: " - ")
        }
    }
}

typealias CurrentActivity = Activity

struct ActivityEngine {
    private var activities: [String: Activity] = [:]

    func currentActivity(at now: Date = Date()) -> CurrentActivity? {
        activities.values
            .filter { !$0.isExpired(at: now) }
            .sorted(by: ActivityEngine.hasHigherSelectionRank)
            .first
    }

    mutating func publish(_ activity: Activity) {
        activities[activity.id] = activity
    }

    mutating func removeActivity(id: String) {
        activities[id] = nil
    }

    mutating func removeActivities(for featureID: String) {
        activities = activities.filter { _, activity in
            activity.featureID != featureID
        }
    }

    mutating func expireActivities(at now: Date = Date()) {
        activities = activities.filter { _, activity in
            !activity.isExpired(at: now)
        }
    }

    private static func hasHigherSelectionRank(_ lhs: Activity, _ rhs: Activity) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority
        }

        return lhs.startedAt > rhs.startedAt
    }
}

