import Foundation

struct FeatureLifecycleController {
    private let settingsStore: SettingsStore
    private let permissionAuthorizer: PermissionAuthorizing
    private var activeFeatureIDs: Set<FeatureID> = []

    init(
        settingsStore: SettingsStore,
        permissionAuthorizer: PermissionAuthorizing = NativePermissionAuthorizer()
    ) {
        self.settingsStore = settingsStore
        self.permissionAuthorizer = permissionAuthorizer
    }

    mutating func sync(
        engine: inout ActivityEngine,
        startFeature: (FeatureID) -> Void,
        stopFeature: (FeatureID) -> Void
    ) {
        for featureID in FeatureID.allCases {
            let shouldRun = settingsStore.isFeatureEnabled(featureID)
            let isRunning = activeFeatureIDs.contains(featureID)

            if shouldRun, !isRunning {
                guard PermissionCenter.requestRequiredPermissions(
                    for: featureID,
                    settingsStore: settingsStore,
                    authorizer: permissionAuthorizer
                ) else {
                    continue
                }

                activeFeatureIDs.insert(featureID)
                startFeature(featureID)
            } else if !shouldRun, isRunning {
                activeFeatureIDs.remove(featureID)
                stopFeature(featureID)
                engine.removeActivities(for: featureID.rawValue)
            }
        }
    }

    mutating func stop(
        _ featureID: FeatureID,
        engine: inout ActivityEngine,
        stopFeature: (FeatureID) -> Void
    ) {
        guard activeFeatureIDs.remove(featureID) != nil else {
            return
        }

        stopFeature(featureID)
        engine.removeActivities(for: featureID.rawValue)
    }
}
