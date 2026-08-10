import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandWindowController: IslandWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
        islandWindowController = IslandWindowController()
        islandWindowController?.show()
    }
}
