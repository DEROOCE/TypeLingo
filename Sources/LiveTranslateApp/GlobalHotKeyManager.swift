import Carbon
import Foundation

@MainActor
final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var action: (() -> Void)?

    private init() {}

    func start(shortcut: WakeShortcut, action: @escaping () -> Void) {
        self.action = action
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return noErr
                }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
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

                guard status == noErr, hotKeyID.id == 1 else {
                    return noErr
                }

                Task { @MainActor in
                    manager.action?()
                }
                return noErr
            },
            1,
            &eventSpec,
            userData,
            &eventHandler
        )

        guard installStatus == noErr else {
            NSLog("Failed to install global hotkey handler: \(installStatus)")
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4C545247), id: 1)
        let registerStatus = RegisterEventHotKey(
            shortcut.key.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            NSLog("Failed to register global hotkey: \(registerStatus)")
        }
    }

    func stop() {
        unregister()
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
