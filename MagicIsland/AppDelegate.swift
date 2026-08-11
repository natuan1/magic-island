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
    private let launchAtLoginCoordinator = LaunchAtLoginCoordinator(controller: NativeLaunchAtLoginController())
    private let updaterRunner = UpdaterRunner(updater: SparkleApplicationUpdater())

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        featureLifecycleController = FeatureLifecycleController(settingsStore: settingsStore)
        statusBarController = StatusBarController(
            model: statusBarMenuModel(),
            onShowIsland: { [weak self] in
                self?.showIsland()
            },
            onOpenFeature: { [weak self] featureID in
                self?.showFeature(featureID)
            },
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onCheckUpdates: { [weak self] in
                self?.checkForUpdates()
            }
        )
        settingsWindowController = SettingsWindowController(
            settingsStore: settingsStore,
            onSettingsChanged: { [weak self] in
                self?.settingsChanged()
            },
            onCheckUpdates: { [weak self] in
                self?.checkForUpdates()
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

    private func showIsland() {
        islandWindowController?.show()
        islandWindowController?.refreshCurrentActivity()
    }

    private func showFeature(_ featureID: FeatureID) {
        islandWindowController?.showFeature(featureID)
    }

    private func checkForUpdates() {
        let result = updaterRunner.checkForUpdates()
        let alert = NSAlert()
        alert.messageText = "Updates"
        alert.informativeText = result.message
        alert.runModal()
    }

    private func settingsChanged() {
        syncFeatureLifecycles()
        applyLaunchAtLogin()
        applyClipboardRetention()
        statusBarController?.updateMenu(statusBarMenuModel())
        islandWindowController?.settingsChanged()
        islandWindowController?.refreshCurrentActivity()
    }

    private func applyClipboardRetention() {
        guard clipboardHistoryStore.purgeExpired(retentionDays: settingsStore.clipboardRetentionDays) else {
            return
        }

        islandWindowController?.refreshCurrentActivity()
    }

    private func applyLaunchAtLogin() {
        let desiredValue = settingsStore.launchAtLoginEnabled
        guard !launchAtLoginCoordinator.setEnabled(desiredValue) else {
            return
        }

        settingsStore.launchAtLoginEnabled = !desiredValue
        let alert = NSAlert()
        alert.messageText = "Launch at Login"
        alert.informativeText = "Could not update login item."
        alert.runModal()
    }

    private func statusBarMenuModel() -> StatusBarMenuModel {
        StatusBarMenuModel.core(featureIDs: [.media, .fileShelf, .clipboardHistory].filter {
            settingsStore.isFeatureEnabled($0)
        })
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

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
