import Foundation

struct SampleFeature {
    static let featureID = "sample"
    static let activityID = "sample.current"

    func publishActivity(
        title: String,
        subtitle: String,
        priority: Int = 10,
        now: Date = Date(),
        engine: inout ActivityEngine
    ) {
        engine.publish(Activity(
            id: Self.activityID,
            featureID: Self.featureID,
            priority: priority,
            startedAt: now,
            expiresAt: nil,
            presentation: .generic(title: title, subtitle: subtitle)
        ))
    }

    func removeActivity(engine: inout ActivityEngine) {
        engine.removeActivity(id: Self.activityID)
    }
}

