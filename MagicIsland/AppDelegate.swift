import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var activityEngine = ActivityEngine()
    private let settingsStore = SettingsStore()
    private var featureLifecycleController: FeatureLifecycleController?
    private var mediaFeature = MediaFeature(provider: SpotifyMediaProvider())
    private var mediaRefreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        featureLifecycleController = FeatureLifecycleController(settingsStore: settingsStore)
        statusBarController = StatusBarController(
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        settingsWindowController = SettingsWindowController(
            settingsStore: settingsStore,
            onSettingsChanged: { [weak self] in
                self?.settingsChanged()
            }
        )
        islandWindowController = IslandWindowController(
            settingsStore: settingsStore,
            currentActivityProvider: { [weak self] in
                self?.activityEngine.currentActivity()
            },
            mediaCommandHandler: { [weak self] command in
                self?.performMediaCommand(command)
            }
        )
        islandWindowController?.show()
        if !Self.isRunningUnitTests {
            syncFeatureLifecycles()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopMediaRefresh()
    }

    private func startMediaRefresh() {
        guard mediaRefreshTimer == nil else {
            return
        }

        refreshMedia()
        mediaRefreshTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(refreshMediaTimerFired),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopMediaRefresh() {
        mediaRefreshTimer?.invalidate()
        mediaRefreshTimer = nil
    }

    private func refreshMedia() {
        mediaFeature.refresh(engine: &activityEngine)
        islandWindowController?.refreshCurrentActivity()
    }

    private func performMediaCommand(_ command: MediaCommand) {
        mediaFeature.perform(command)
        if !mediaFeature.isEnabled {
            activityEngine.removeActivities(for: MediaFeature<SpotifyMediaProvider>.featureID)
        }
        refreshMedia()
    }

    private func openSettings() {
        settingsWindowController?.show()
    }

    private func settingsChanged() {
        syncFeatureLifecycles()
        islandWindowController?.settingsChanged()
        islandWindowController?.refreshCurrentActivity()
    }

    private func syncFeatureLifecycles() {
        featureLifecycleController?.sync(
            engine: &activityEngine,
            startFeature: { [weak self] featureID in
                self?.startFeature(featureID)
            },
            stopFeature: { [weak self] featureID in
                self?.stopFeature(featureID)
            }
        )
    }

    private func startFeature(_ featureID: FeatureID) {
        switch featureID {
        case .media:
            startMediaRefresh()
        }
    }

    private func stopFeature(_ featureID: FeatureID) {
        switch featureID {
        case .media:
            stopMediaRefresh()
        }
    }

    @objc private func refreshMediaTimerFired() {
        refreshMedia()
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
