import AppKit
import CoreServices
import Foundation

enum PermissionID: String, CaseIterable, Equatable, Identifiable {
    case spotifyAutomation

    var id: String { rawValue }
}

enum PermissionGrantState: String, Equatable {
    case notDetermined
    case granted
    case denied
    case unavailable

    var title: String {
        switch self {
        case .notDetermined:
            return "Not Requested"
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .unavailable:
            return "Unavailable"
        }
    }
}

struct PermissionCenterItem: Equatable, Identifiable {
    let id: PermissionID
    let title: String
    let state: PermissionGrantState
    let stateDescription: String
    let purpose: String
    let featureID: FeatureID
    let revokeGuidance: String

    var keyboardAccessibilityLabel: String {
        "\(title), \(state.title), \(featureID.title). \(purpose) Revoke in \(revokeGuidance)"
    }
}

protocol PermissionAuthorizing {
    func currentGrantState(for permissionID: PermissionID) -> PermissionGrantState
    func requestGrant(for permissionID: PermissionID) -> PermissionGrantState
}

struct PermissionCenter {
    private static let requirements: [PermissionCenterItem] = [
        PermissionCenterItem(
            id: .spotifyAutomation,
            title: "Spotify Automation",
            state: .notDetermined,
            stateDescription: "Last known state. Magic Island checks without prompting in Settings.",
            purpose: "Control Spotify playback and read the current track for the Media Feature.",
            featureID: .media,
            revokeGuidance: "System Settings > Privacy & Security > Automation > Magic Island > Spotify"
        )
    ]

    static func items(
        settingsStore: SettingsStore,
        authorizer: PermissionAuthorizing = NativePermissionAuthorizer()
    ) -> [PermissionCenterItem] {
        requirements.map { requirement in
            PermissionCenterItem(
                id: requirement.id,
                title: requirement.title,
                state: visibleState(for: requirement.id, settingsStore: settingsStore, authorizer: authorizer),
                stateDescription: requirement.stateDescription,
                purpose: requirement.purpose,
                featureID: requirement.featureID,
                revokeGuidance: requirement.revokeGuidance
            )
        }
    }

    static func requestRequiredPermissions(
        for featureID: FeatureID,
        settingsStore: SettingsStore,
        authorizer: PermissionAuthorizing
    ) -> Bool {
        let requiredPermissionIDs = requirements
            .filter { $0.featureID == featureID }
            .map(\.id)

        guard !requiredPermissionIDs.isEmpty else {
            return true
        }

        for permissionID in requiredPermissionIDs {
            let persistedState = settingsStore.permissionGrantState(permissionID)
            let currentState = authorizer.currentGrantState(for: permissionID)
            let state = currentState == .notDetermined ? persistedState : currentState

            switch state {
            case .granted:
                settingsStore.setPermissionGrantState(permissionID, .granted)
            case .denied, .unavailable:
                settingsStore.setPermissionGrantState(permissionID, state)
                settingsStore.setFeature(featureID, enabled: false)
                return false
            case .notDetermined:
                let requestedState = authorizer.requestGrant(for: permissionID)
                settingsStore.setPermissionGrantState(permissionID, requestedState)
                guard requestedState == .granted else {
                    settingsStore.setFeature(featureID, enabled: false)
                    return false
                }
            }
        }

        return true
    }

    private static func visibleState(
        for permissionID: PermissionID,
        settingsStore: SettingsStore,
        authorizer: PermissionAuthorizing
    ) -> PermissionGrantState {
        let currentState = authorizer.currentGrantState(for: permissionID)
        if currentState != .notDetermined {
            settingsStore.setPermissionGrantState(permissionID, currentState)
            return currentState
        }

        return settingsStore.permissionGrantState(permissionID)
    }
}

final class NativePermissionAuthorizer: PermissionAuthorizing {
    func currentGrantState(for permissionID: PermissionID) -> PermissionGrantState {
        switch permissionID {
        case .spotifyAutomation:
            return determineSpotifyAutomation(askUserIfNeeded: false)
        }
    }

    func requestGrant(for permissionID: PermissionID) -> PermissionGrantState {
        switch permissionID {
        case .spotifyAutomation:
            return determineSpotifyAutomation(askUserIfNeeded: true)
        }
    }

    private func determineSpotifyAutomation(askUserIfNeeded: Bool) -> PermissionGrantState {
        guard let target = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.spotify.client"
        ).first else {
            return .notDetermined
        }

        let processIdentifier = target.processIdentifier
        var address = AEAddressDesc()
        let createStatus = AECreateDesc(
            typeKernelProcessID,
            [processIdentifier],
            MemoryLayout<pid_t>.size,
            &address
        )
        guard createStatus == noErr else {
            return .unavailable
        }
        defer { AEDisposeDesc(&address) }

        let status = AEDeterminePermissionToAutomateTarget(
            &address,
            typeWildCard,
            typeWildCard,
            askUserIfNeeded
        )

        switch status {
        case noErr:
            return .granted
        case OSStatus(errAEEventNotPermitted):
            return .denied
        case OSStatus(errAEEventWouldRequireUserConsent):
            return .notDetermined
        default:
            return .unavailable
        }
    }
}
