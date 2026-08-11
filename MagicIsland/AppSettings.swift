import CoreGraphics
import Foundation

enum FeatureID: String, CaseIterable, Equatable, Identifiable {
    case media
    case fileShelf
    case clipboardHistory
    case timer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .media:
            return "Media"
        case .fileShelf:
            return "File Shelf"
        case .clipboardHistory:
            return "Clipboard History"
        case .timer:
            return "Timer"
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        case .media, .fileShelf, .timer:
            return true
        case .clipboardHistory:
            return false
        }
    }
}

enum DisplayPreference: Equatable {
    case primary
    case specificDisplay(CGDirectDisplayID)

    private static let primaryRawValue = "primary"

    init(rawValue: String) {
        guard let displayID = CGDirectDisplayID(rawValue) else {
            self = .primary
            return
        }

        self = .specificDisplay(displayID)
    }

    var rawValue: String {
        switch self {
        case .primary:
            return Self.primaryRawValue
        case .specificDisplay(let displayID):
            return String(displayID)
        }
    }
}

final class SettingsStore {
    private enum Key {
        static let hoverDelay = "settings.hoverDelay"
        static let displayPreference = "settings.displayPreference"
        static let clipboardRetentionDays = "settings.clipboardRetentionDays"

        static func featureEnabled(_ featureID: FeatureID) -> String {
            "settings.feature.\(featureID.rawValue).enabled"
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hoverDelay: TimeInterval {
        get {
            guard defaults.object(forKey: Key.hoverDelay) != nil else {
                return 0.2
            }

            return defaults.double(forKey: Key.hoverDelay)
        }
        set {
            defaults.set(max(0, newValue), forKey: Key.hoverDelay)
        }
    }

    var displayPreference: DisplayPreference {
        get {
            DisplayPreference(rawValue: defaults.string(forKey: Key.displayPreference) ?? "primary")
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.displayPreference)
        }
    }

    var clipboardRetentionDays: Int {
        get {
            guard defaults.object(forKey: Key.clipboardRetentionDays) != nil else {
                return 7
            }

            return max(1, defaults.integer(forKey: Key.clipboardRetentionDays))
        }
        set {
            defaults.set(max(1, newValue), forKey: Key.clipboardRetentionDays)
        }
    }

    func isFeatureEnabled(_ featureID: FeatureID) -> Bool {
        let key = Key.featureEnabled(featureID)
        guard defaults.object(forKey: key) != nil else {
            return featureID.isEnabledByDefault
        }

        return defaults.bool(forKey: key)
    }

    func setFeature(_ featureID: FeatureID, enabled: Bool) {
        defaults.set(enabled, forKey: Key.featureEnabled(featureID))
    }
}
