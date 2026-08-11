import AppKit
import Carbon

final class IslandShortcutController: @unchecked Sendable {
    private static let hotKeySignature = fourCharacterCode("MgIl")
    private static let expansionHotKeyID = UInt32(1)
    private static let escapeKeyCode = UInt16(kVK_Escape)

    private let onShortcut: @MainActor () -> Void
    private let shortcut: ExpansionShortcut
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private var localMonitor: Any?
    private(set) var expansionShortcutIsRegistered = false

    init(
        shortcut: ExpansionShortcut = .commandOptionSpace,
        onShortcut: @escaping @MainActor () -> Void,
        onEscape: @escaping @MainActor () -> Void
    ) {
        self.shortcut = shortcut
        self.onShortcut = onShortcut

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Self.isEscape(event) {
                Task { @MainActor in
                    onEscape()
                }
                return nil
            }

            if Self.isExpansionShortcut(event, shortcut: shortcut) {
                Task { @MainActor in
                    onShortcut()
                }
                return nil
            }

            return event
        }

        registerExpansionHotKey()
    }

    deinit {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private static func isExpansionShortcut(_ event: NSEvent, shortcut: ExpansionShortcut) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == shortcut.keyCode && modifiers == shortcut.eventModifiers && !event.isARepeat
    }

    private static func isEscape(_ event: NSEvent) -> Bool {
        event.keyCode == escapeKeyCode && !event.isARepeat
    }

    private func registerExpansionHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard
                    let event,
                    let userData
                else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard
                    status == noErr,
                    hotKeyID.signature == IslandShortcutController.hotKeySignature,
                    hotKeyID.id == IslandShortcutController.expansionHotKeyID
                else {
                    return noErr
                }

                let controller = Unmanaged<IslandShortcutController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                controller.handleExpansionHotKey()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
        guard handlerStatus == noErr else {
            eventHandler = nil
            return
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.hotKeySignature,
            id: Self.expansionHotKeyID
        )
        let registrationStatus = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        expansionShortcutIsRegistered = registrationStatus == noErr
    }

    private func handleExpansionHotKey() {
        Task { @MainActor in
            onShortcut()
        }
    }
}

private func fourCharacterCode(_ string: String) -> FourCharCode {
    precondition(string.utf8.count == 4)

    return string.utf8.reduce(0) { result, character in
        (result << 8) + FourCharCode(character)
    }
}
