import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let settingsStore: SettingsStore
    private let onSettingsChanged: @MainActor () -> Void
    private var window: NSWindow?

    init(
        settingsStore: SettingsStore,
        onSettingsChanged: @escaping @MainActor () -> Void
    ) {
        self.settingsStore = settingsStore
        self.onSettingsChanged = onSettingsChanged
    }

    func show() {
        if window == nil {
            let view = SettingsView(
                settingsStore: settingsStore,
                displays: DisplayOption.currentDisplays(),
                onSettingsChanged: onSettingsChanged
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Magic Island Settings"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            self.window = window
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct DisplayOption: Identifiable, Equatable {
    let id: String
    let title: String
    let preference: DisplayPreference

    static func currentDisplays() -> [DisplayOption] {
        let primary = DisplayOption(id: "primary", title: "Primary Display", preference: .primary)
        let screens = NSScreen.screens.compactMap { screen -> DisplayOption? in
            guard let displayID = screen.displayID else {
                return nil
            }

            return DisplayOption(
                id: String(displayID),
                title: screen.localizedName,
                preference: .specificDisplay(displayID)
            )
        }

        return [primary] + screens
    }
}

private struct SettingsView: View {
    let settingsStore: SettingsStore
    let displays: [DisplayOption]
    let onSettingsChanged: () -> Void

    @State private var mediaEnabled: Bool
    @State private var fileShelfEnabled: Bool
    @State private var clipboardHistoryEnabled: Bool
    @State private var quickActionsEnabled: Bool
    @State private var hoverDelay: Double
    @State private var displayRawValue: String
    @State private var clipboardRetentionDays: Int

    init(
        settingsStore: SettingsStore,
        displays: [DisplayOption],
        onSettingsChanged: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.displays = displays
        self.onSettingsChanged = onSettingsChanged
        _mediaEnabled = State(initialValue: settingsStore.isFeatureEnabled(.media))
        _fileShelfEnabled = State(initialValue: settingsStore.isFeatureEnabled(.fileShelf))
        _clipboardHistoryEnabled = State(initialValue: settingsStore.isFeatureEnabled(.clipboardHistory))
        _quickActionsEnabled = State(initialValue: settingsStore.isFeatureEnabled(.quickActions))
        _hoverDelay = State(initialValue: settingsStore.hoverDelay)
        _displayRawValue = State(initialValue: settingsStore.displayPreference.rawValue)
        _clipboardRetentionDays = State(initialValue: settingsStore.clipboardRetentionDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))

            featureSection
            placementSection
            clipboardSection
            shortcutsSection
            updaterSection
            permissionSection

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Feature Toggles")
            Toggle("Media", isOn: $mediaEnabled)
                .onChange(of: mediaEnabled) { _, value in
                    settingsStore.setFeature(.media, enabled: value)
                    onSettingsChanged()
                }
            Toggle("File Shelf", isOn: $fileShelfEnabled)
                .onChange(of: fileShelfEnabled) { _, value in
                    settingsStore.setFeature(.fileShelf, enabled: value)
                    onSettingsChanged()
                }
            Toggle("Clipboard History", isOn: $clipboardHistoryEnabled)
                .onChange(of: clipboardHistoryEnabled) { _, value in
                    settingsStore.setFeature(.clipboardHistory, enabled: value)
                    onSettingsChanged()
                }
            Toggle("Quick Actions", isOn: $quickActionsEnabled)
                .onChange(of: quickActionsEnabled) { _, value in
                    settingsStore.setFeature(.quickActions, enabled: value)
                    onSettingsChanged()
                }
        }
    }

    private var placementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Island")
            Picker("Display", selection: $displayRawValue) {
                ForEach(displays) { display in
                    Text(display.title).tag(display.preference.rawValue)
                }
            }
            .onChange(of: displayRawValue) { _, value in
                settingsStore.displayPreference = DisplayPreference(rawValue: value)
                onSettingsChanged()
            }

            HStack {
                Text("Hover Delay")
                Slider(value: $hoverDelay, in: 0...1, step: 0.05)
                    .onChange(of: hoverDelay) { _, value in
                        settingsStore.hoverDelay = value
                        onSettingsChanged()
                    }
                Text(String(format: "%.2fs", hoverDelay))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }
        }
    }

    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Clipboard")
            Stepper("Retention: \(clipboardRetentionDays) days", value: $clipboardRetentionDays, in: 1...30)
                .onChange(of: clipboardRetentionDays) { _, value in
                    settingsStore.clipboardRetentionDays = value
                    onSettingsChanged()
                }
        }
    }

    private var shortcutsSection: some View {
        Button("Shortcuts: Option-Space") {}
            .disabled(true)
    }

    private var updaterSection: some View {
        Button("Check for Updates") {}
            .disabled(true)
    }

    private var permissionSection: some View {
        Button("Permission Status") {}
            .disabled(true)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}
