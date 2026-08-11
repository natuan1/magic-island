import Foundation
import Carbon
import AppKit
import ServiceManagement

enum StatusBarMenuCommand: Equatable {
    case showIsland
    case openFeature(FeatureID)
    case openSettings
    case checkUpdates
    case quit
}

struct StatusBarMenuItemModel: Equatable {
    let title: String
    let command: StatusBarMenuCommand
}

struct StatusBarMenuModel: Equatable {
    let items: [StatusBarMenuItemModel]

    static func core(featureIDs: [FeatureID]) -> StatusBarMenuModel {
        let featureItems = featureIDs.map {
            StatusBarMenuItemModel(title: $0.title, command: .openFeature($0))
        }

        return StatusBarMenuModel(items:
            [StatusBarMenuItemModel(title: "Show Island", command: .showIsland)] +
            featureItems +
            [
                StatusBarMenuItemModel(title: "Settings...", command: .openSettings),
                StatusBarMenuItemModel(title: "Check for Updates...", command: .checkUpdates),
                StatusBarMenuItemModel(title: "Quit Magic Island", command: .quit)
            ]
        )
    }
}

enum ExpansionShortcut: String, CaseIterable, Equatable, Identifiable {
    case commandOptionSpace
    case optionSpace
    case controlOptionSpace
    case commandOptionReturn
    case commandOptionF

    var id: String { rawValue }

    var title: String {
        switch self {
        case .commandOptionSpace:
            return "Command-Option-Space"
        case .optionSpace:
            return "Option-Space"
        case .controlOptionSpace:
            return "Control-Option-Space"
        case .commandOptionReturn:
            return "Command-Option-Return"
        case .commandOptionF:
            return "Command-Option-F"
        }
    }

    var keyCode: UInt16 {
        switch self {
        case .commandOptionSpace, .optionSpace, .controlOptionSpace:
            return UInt16(kVK_Space)
        case .commandOptionReturn:
            return UInt16(kVK_Return)
        case .commandOptionF:
            return UInt16(kVK_ANSI_F)
        }
    }

    var carbonModifiers: UInt32 {
        switch self {
        case .commandOptionSpace:
            return UInt32(cmdKey | optionKey)
        case .optionSpace:
            return UInt32(optionKey)
        case .controlOptionSpace:
            return UInt32(controlKey | optionKey)
        case .commandOptionReturn, .commandOptionF:
            return UInt32(cmdKey | optionKey)
        }
    }

    var eventModifiers: NSEvent.ModifierFlags {
        switch self {
        case .commandOptionSpace:
            return [.command, .option]
        case .optionSpace:
            return [.option]
        case .controlOptionSpace:
            return [.control, .option]
        case .commandOptionReturn, .commandOptionF:
            return [.command, .option]
        }
    }
}

protocol LaunchAtLoginControlling: AnyObject {
    func setEnabled(_ enabled: Bool) -> Bool
}

struct LaunchAtLoginCoordinator {
    private let controller: LaunchAtLoginControlling

    init(controller: LaunchAtLoginControlling) {
        self.controller = controller
    }

    func setEnabled(_ enabled: Bool) -> Bool {
        controller.setEnabled(enabled)
    }
}

final class NativeLaunchAtLoginController: LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}

enum UpdateCheckResult: Equatable {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }
}

protocol ApplicationUpdating: AnyObject {
    func checkForUpdates() -> UpdateCheckResult
}

struct UpdaterRunner {
    private let updater: ApplicationUpdating

    init(updater: ApplicationUpdating) {
        self.updater = updater
    }

    func checkForUpdates() -> UpdateCheckResult {
        updater.checkForUpdates()
    }
}

final class SparkleApplicationUpdater: ApplicationUpdating {
    private let updaterController: NSObject?

    init(updaterController: NSObject? = SparkleApplicationUpdater.loadSharedController()) {
        self.updaterController = updaterController
    }

    func checkForUpdates() -> UpdateCheckResult {
        guard let updaterController else {
            return .failure("Sparkle updater unavailable")
        }

        let selector = NSSelectorFromString("checkForUpdates:")
        guard updaterController.responds(to: selector) else {
            return .failure("Sparkle updater unavailable")
        }

        updaterController.perform(selector, with: nil)
        return .success("Checking for updates")
    }

    private static func loadSharedController() -> NSObject? {
        guard let controllerClass = NSClassFromString("SPUStandardUpdaterController") as? NSObject.Type else {
            return nil
        }

        return controllerClass.value(forKey: "sharedUpdaterController") as? NSObject
    }
}
