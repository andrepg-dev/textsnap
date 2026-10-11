import Carbon.HIToolbox

/// System-wide shortcut backed by Carbon's `RegisterEventHotKey`.
///
/// Unlike an event tap it needs no Accessibility permission and costs nothing
/// while idle: the window server only wakes the app when the combo is pressed.
@MainActor
final class GlobalHotKey {
    struct Shortcut {
        let keyCode: UInt32
        let modifiers: UInt32

        static let commandShift2 = Shortcut(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey))
    }

    struct RegistrationError: LocalizedError {
        let status: OSStatus
        var errorDescription: String? { "Carbon hotkey registration failed (OSStatus \(status))" }
    }

    private static let signature: OSType = 0x5453_6E70 // "TSnp"

    private let action: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(_ shortcut: Shortcut, action: @escaping @MainActor () -> Void) throws {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        var status = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(context).takeUnretainedValue()
            // Carbon dispatches application events on the main run loop.
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &eventType, context, &handlerRef)
        guard status == noErr else { throw RegistrationError(status: status) }

        let id = EventHotKeyID(signature: Self.signature, id: 1)
        status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else {
            unregister()
            throw RegistrationError(status: status)
        }
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        hotKeyRef = nil
        handlerRef = nil
    }
}
