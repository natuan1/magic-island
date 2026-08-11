import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var activityEngine = ActivityEngine()
    private let settingsStore = SettingsStore()
    private var featureLifecycleController: FeatureLifecycleController?
    private let fileShelfStore = FileShelfStore()
    private let clipboardHistoryStore = ClipboardHistoryStore()
    private var mediaFeature = MediaFeature(provider: SpotifyMediaProvider())
    private var mediaRefreshTimer: Timer?
    private var clipboardHistoryFeature = ClipboardHistoryFeature(provider: MacPasteboardClipboardProvider())
    private var clipboardRefreshTimer: Timer?
    private var timerFeature = TimerFeature()
    private var timerRefreshTimer: Timer?

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
            },
            timerCommandHandler: { [weak self] command in
                self?.performTimerCommand(command)
            },
            fileShelfItemsProvider: { [weak self] in
                self?.fileShelfStore.items ?? []
            },
            fileDropHandler: { [weak self] urls in
                self?.addFilesToShelf(urls)
            },
            shelfRevealHandler: { [weak self] itemID in
                self?.revealShelfItem(itemID)
            },
            clipboardItemsProvider: { [weak self] in
                self?.clipboardHistoryStore.items ?? []
            },
            clipboardCopyHandler: { [weak self] itemID in
                self?.copyClipboardItem(itemID)
            },
            clipboardDeleteHandler: { [weak self] itemID in
                self?.deleteClipboardItem(itemID)
            }
        )
        islandWindowController?.show()
        if !Self.isRunningUnitTests {
            syncFeatureLifecycles()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopMediaRefresh()
        stopClipboardRefresh()
        stopTimerRefresh()
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

    private func startClipboardRefresh() {
        guard clipboardRefreshTimer == nil else {
            return
        }

        clipboardHistoryFeature.start()
        clipboardRefreshTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(refreshClipboardTimerFired),
            userInfo: nil,
            repeats: true
        )
    }

    private func startTimerRefresh() {
        guard timerRefreshTimer == nil else {
            return
        }

        timerRefreshTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(timerTickFired),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimerRefresh() {
        timerRefreshTimer?.invalidate()
        timerRefreshTimer = nil
    }

    private func stopClipboardRefresh() {
        clipboardRefreshTimer?.invalidate()
        clipboardRefreshTimer = nil
        clipboardHistoryFeature.stop()
    }

    private func refreshClipboardHistory() {
        let changed = clipboardHistoryFeature.poll(
            store: clipboardHistoryStore,
            settingsStore: settingsStore
        )

        if changed {
            islandWindowController?.refreshCurrentActivity()
        }
    }

    private func refreshMedia() {
        mediaFeature.refresh(engine: &activityEngine)
        islandWindowController?.refreshCurrentActivity()
    }

    private func refreshTimer() {
        guard timerFeature.isActive else {
            return
        }

        timerFeature.refresh(engine: &activityEngine)
        islandWindowController?.refreshCurrentActivity()
    }

    private func performMediaCommand(_ command: MediaCommand) {
        mediaFeature.perform(command)
        if !mediaFeature.isEnabled {
            activityEngine.removeActivities(for: MediaFeature<SpotifyMediaProvider>.featureID)
        }
        refreshMedia()
    }

    private func performTimerCommand(_ command: TimerCommand) {
        guard settingsStore.isFeatureEnabled(.timer) else {
            return
        }

        timerFeature.perform(command, engine: &activityEngine)
        islandWindowController?.refreshCurrentActivity()
    }

    private func openSettings() {
        settingsWindowController?.show()
    }

    private func settingsChanged() {
        syncFeatureLifecycles()
        applyClipboardRetention()
        islandWindowController?.settingsChanged()
        islandWindowController?.refreshCurrentActivity()
    }

    private func applyClipboardRetention() {
        guard clipboardHistoryStore.purgeExpired(retentionDays: settingsStore.clipboardRetentionDays) else {
            return
        }

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
        case .clipboardHistory:
            startClipboardRefresh()
        case .timer:
            startTimerRefresh()
        case .fileShelf:
            break
        }
    }

    private func stopFeature(_ featureID: FeatureID) {
        switch featureID {
        case .media:
            stopMediaRefresh()
        case .clipboardHistory:
            stopClipboardRefresh()
        case .timer:
            stopTimerRefresh()
            timerFeature.cancel(engine: &activityEngine)
        case .fileShelf:
            break
        }
    }

    private func addFilesToShelf(_ urls: [URL]) {
        guard settingsStore.isFeatureEnabled(.fileShelf) else {
            return
        }

        fileShelfStore.addFileReferences(urls)
        islandWindowController?.showFileShelf()
    }

    private func revealShelfItem(_ itemID: UUID) {
        guard let item = fileShelfStore.item(id: itemID),
              item.isAvailable() else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    private func copyClipboardItem(_ itemID: UUID) {
        guard settingsStore.isFeatureEnabled(.clipboardHistory) else {
            return
        }

        guard let item = clipboardHistoryStore.items.first(where: { $0.id == itemID }) else {
            return
        }

        clipboardHistoryFeature.copy(item)
    }

    private func deleteClipboardItem(_ itemID: UUID) {
        guard settingsStore.isFeatureEnabled(.clipboardHistory) else {
            return
        }

        clipboardHistoryStore.delete(id: itemID)
        islandWindowController?.refreshCurrentActivity()
    }

    @objc private func refreshMediaTimerFired() {
        refreshMedia()
    }

    @objc private func refreshClipboardTimerFired() {
        refreshClipboardHistory()
    }

    @objc private func timerTickFired() {
        refreshTimer()
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
