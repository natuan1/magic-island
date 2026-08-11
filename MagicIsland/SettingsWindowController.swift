import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let settingsStore: SettingsStore
    private let onSettingsChanged: @MainActor () -> Void
    private let onCheckUpdates: @MainActor () -> Void
    private var window: NSWindow?

    init(
        settingsStore: SettingsStore,
        onSettingsChanged: @escaping @MainActor () -> Void,
        onCheckUpdates: @escaping @MainActor () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.onSettingsChanged = onSettingsChanged
        self.onCheckUpdates = onCheckUpdates
    }

    func show() {
        if window == nil {
            let view = SettingsView(
                settingsStore: settingsStore,
                displays: DisplayOption.currentDisplays(),
                onSettingsChanged: onSettingsChanged,
                onCheckUpdates: onCheckUpdates
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
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
    let onCheckUpdates: () -> Void

    @State private var mediaEnabled: Bool
    @State private var fileShelfEnabled: Bool
    @State private var clipboardHistoryEnabled: Bool
    @State private var timerEnabled: Bool
    @State private var quickActionsEnabled: Bool
    @State private var hoverDelay: Double
    @State private var displayRawValue: String
    @State private var clipboardRetentionDays: Int
    @State private var launchAtLoginEnabled: Bool
    @State private var expansionShortcutRawValue: String

    init(
        settingsStore: SettingsStore,
        displays: [DisplayOption],
        onSettingsChanged: @escaping () -> Void,
        onCheckUpdates: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.displays = displays
        self.onSettingsChanged = onSettingsChanged
        self.onCheckUpdates = onCheckUpdates
        _mediaEnabled = State(initialValue: settingsStore.isFeatureEnabled(.media))
        _fileShelfEnabled = State(initialValue: settingsStore.isFeatureEnabled(.fileShelf))
        _clipboardHistoryEnabled = State(initialValue: settingsStore.isFeatureEnabled(.clipboardHistory))
        _timerEnabled = State(initialValue: settingsStore.isFeatureEnabled(.timer))
        _quickActionsEnabled = State(initialValue: settingsStore.isFeatureEnabled(.quickActions))
        _hoverDelay = State(initialValue: settingsStore.hoverDelay)
        _displayRawValue = State(initialValue: settingsStore.displayPreference.rawValue)
        _clipboardRetentionDays = State(initialValue: settingsStore.clipboardRetentionDays)
        _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
        _expansionShortcutRawValue = State(initialValue: settingsStore.expansionShortcut.rawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))

            featureSection
            placementSection
            clipboardSection
            shortcutsSection
            startupSection
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
                    refreshFeatureToggles()
                }
            Toggle("File Shelf", isOn: $fileShelfEnabled)
                .onChange(of: fileShelfEnabled) { _, value in
                    settingsStore.setFeature(.fileShelf, enabled: value)
                    onSettingsChanged()
                    refreshFeatureToggles()
                }
            Toggle("Clipboard History", isOn: $clipboardHistoryEnabled)
                .onChange(of: clipboardHistoryEnabled) { _, value in
                    settingsStore.setFeature(.clipboardHistory, enabled: value)
                    onSettingsChanged()
                    refreshFeatureToggles()
                }
            Toggle("Timer", isOn: $timerEnabled)
                .onChange(of: timerEnabled) { _, value in
                    settingsStore.setFeature(.timer, enabled: value)
                    onSettingsChanged()
                    refreshFeatureToggles()
                }
            Toggle("Quick Actions", isOn: $quickActionsEnabled)
                .onChange(of: quickActionsEnabled) { _, value in
                    settingsStore.setFeature(.quickActions, enabled: value)
                    onSettingsChanged()
                    refreshFeatureToggles()
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
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Shortcuts")
            Picker("Show Island", selection: $expansionShortcutRawValue) {
                ForEach(ExpansionShortcut.allCases) { shortcut in
                    Text(shortcut.title).tag(shortcut.rawValue)
                }
            }
            .onChange(of: expansionShortcutRawValue) { _, value in
                settingsStore.expansionShortcut = ExpansionShortcut(rawValue: value) ?? .commandOptionSpace
                onSettingsChanged()
            }
        }
    }

    private var startupSection: some View {
        Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
            .onChange(of: launchAtLoginEnabled) { _, value in
                settingsStore.launchAtLoginEnabled = value
                onSettingsChanged()
            }
    }

    private var updaterSection: some View {
        Button("Check for Updates", action: onCheckUpdates)
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Permission Center")
            ForEach(PermissionCenter.items(settingsStore: settingsStore)) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                        Text(item.state.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(item.state == .granted ? .green : .secondary)
                            .help(item.stateDescription)
                    }
                    Text("\(item.featureID.title): \(item.purpose)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.revokeGuidance)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.title), \(item.state.title), \(item.featureID.title). \(item.purpose) Revoke in \(item.revokeGuidance)")
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func refreshFeatureToggles() {
        mediaEnabled = settingsStore.isFeatureEnabled(.media)
        fileShelfEnabled = settingsStore.isFeatureEnabled(.fileShelf)
        clipboardHistoryEnabled = settingsStore.isFeatureEnabled(.clipboardHistory)
        timerEnabled = settingsStore.isFeatureEnabled(.timer)
        quickActionsEnabled = settingsStore.isFeatureEnabled(.quickActions)
    }
}
