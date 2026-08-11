import Carbon
import XCTest
@testable import MagicIsland

final class ProductShellTests: XCTestCase {
    func testMenuModelIncludesCoreCommandsAndFeatures() {
        let model = StatusBarMenuModel.core(featureIDs: [.media, .fileShelf, .clipboardHistory])

        XCTAssertEqual(model.items.map(\.title), [
            "Show Island",
            "Media",
            "File Shelf",
            "Clipboard History",
            "Settings...",
            "Check for Updates...",
            "Quit Magic Island"
        ])
    }

    func testMenuModelCanOmitDisabledFeatures() {
        let model = StatusBarMenuModel.core(featureIDs: [.media, .fileShelf])

        XCTAssertEqual(model.items.map(\.title), [
            "Show Island",
            "Media",
            "File Shelf",
            "Settings...",
            "Check for Updates...",
            "Quit Magic Island"
        ])
    }

    func testLaunchAtLoginSettingPersistsAcrossStoreInstances() {
        let defaults = UserDefaults(suiteName: "ProductShellTests.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)

        XCTAssertFalse(store.launchAtLoginEnabled)

        store.launchAtLoginEnabled = true

        XCTAssertTrue(SettingsStore(defaults: defaults).launchAtLoginEnabled)
    }

    func testGlobalShortcutSettingDefaultsAndPersists() {
        let defaults = UserDefaults(suiteName: "ProductShellTests.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.expansionShortcut, .commandOptionSpace)

        store.expansionShortcut = .commandOptionF

        XCTAssertEqual(SettingsStore(defaults: defaults).expansionShortcut, .commandOptionF)
    }

    func testGlobalShortcutOffersMultipleConfigurableChoices() {
        XCTAssertTrue(ExpansionShortcut.allCases.count >= 5)
        XCTAssertEqual(ExpansionShortcut.commandOptionSpace.keyCode, UInt16(kVK_Space))
        XCTAssertEqual(ExpansionShortcut.commandOptionF.keyCode, UInt16(kVK_ANSI_F))
    }

    func testLaunchAtLoginCoordinatorUsesNativeControllerAndReportsFailure() {
        let controller = SpyLaunchAtLoginController()
        let coordinator = LaunchAtLoginCoordinator(controller: controller)

        XCTAssertTrue(coordinator.setEnabled(true))
        XCTAssertEqual(controller.enabledValues, [true])

        controller.nextResult = false

        XCTAssertFalse(coordinator.setEnabled(false))
        XCTAssertEqual(controller.enabledValues, [true, false])
    }

    func testUpdaterRunnerWrapsApplicationUpdater() {
        let updater = SpyApplicationUpdater()
        let runner = UpdaterRunner(updater: updater)

        XCTAssertEqual(runner.checkForUpdates(), .success("No updates available"))
        XCTAssertEqual(updater.checkCount, 1)

        updater.nextResult = .failure("Updater unavailable")

        XCTAssertEqual(runner.checkForUpdates(), .failure("Updater unavailable"))
    }

    func testSparkleUpdaterReportsUnavailableWhenFrameworkIsMissing() {
        let updater = SparkleApplicationUpdater(updaterController: nil)

        XCTAssertEqual(updater.checkForUpdates(), .failure("Sparkle updater unavailable"))
    }
}

private final class SpyLaunchAtLoginController: LaunchAtLoginControlling {
    var enabledValues: [Bool] = []
    var nextResult = true

    func setEnabled(_ enabled: Bool) -> Bool {
        enabledValues.append(enabled)
        return nextResult
    }
}

private final class SpyApplicationUpdater: ApplicationUpdating {
    var checkCount = 0
    var nextResult: UpdateCheckResult = .success("No updates available")

    func checkForUpdates() -> UpdateCheckResult {
        checkCount += 1
        return nextResult
    }
}
