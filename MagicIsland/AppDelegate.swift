import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?
    private var statusBarController: StatusBarController?
    private var activityEngine = ActivityEngine()
    private var mediaFeature = MediaFeature(provider: SpotifyMediaProvider())
    private var mediaRefreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
        islandWindowController = IslandWindowController(
            currentActivityProvider: { [weak self] in
                self?.activityEngine.currentActivity()
            },
            mediaCommandHandler: { [weak self] command in
                self?.performMediaCommand(command)
            }
        )
        islandWindowController?.show()
        startMediaRefresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mediaRefreshTimer?.invalidate()
    }

    private func startMediaRefresh() {
        refreshMedia()
        mediaRefreshTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(refreshMediaTimerFired),
            userInfo: nil,
            repeats: true
        )
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

    @objc private func refreshMediaTimerFired() {
        refreshMedia()
    }
}
