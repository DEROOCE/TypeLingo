import Carbon
import Foundation
import Security

enum HotKeyRegistrationResult: Equatable {
    case success
    case rolledBack(activeShortcut: WakeShortcut, message: String)
    case failure(activeShortcut: WakeShortcut?, message: String)
}

@MainActor
protocol HotKeyRegistering: AnyObject {
    func start(
        shortcut: WakeShortcut,
        copy: LocalizedCopy,
        action: @escaping () -> Void
    ) -> HotKeyRegistrationResult
    func stop()
}

@MainActor
final class GlobalHotKeyManager: HotKeyRegistering {
    static let shared = GlobalHotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var action: (() -> Void)?
    private var activeShortcut: WakeShortcut?
    private var lastValidShortcut: WakeShortcut?

    private init() {}

    func start(
        shortcut: WakeShortcut,
        copy: LocalizedCopy,
        action: @escaping () -> Void
    ) -> HotKeyRegistrationResult {
        self.action = action

        let installStatus = ensureEventHandlerInstalled()
        guard installStatus == noErr else {
            NSLog("Failed to install global hotkey handler: \(installStatus)")
            return .failure(
                activeShortcut: activeShortcut ?? lastValidShortcut,
                message: Self.hotKeyErrorMessage(status: installStatus, copy: copy)
            )
        }

        let previousShortcut = activeShortcut ?? lastValidShortcut
        unregisterHotKey()

        let registerStatus = register(shortcut: shortcut)
        guard registerStatus == noErr else {
            NSLog("Failed to register global hotkey: \(registerStatus)")

            if let previousShortcut {
                let rollbackStatus = register(shortcut: previousShortcut)
                if rollbackStatus == noErr {
                    activeShortcut = previousShortcut
                    lastValidShortcut = previousShortcut
                    return .rolledBack(
                        activeShortcut: previousShortcut,
                        message: Self.rollbackMessage(
                            requested: shortcut,
                            fallback: previousShortcut,
                            status: registerStatus,
                            copy: copy
                        )
                    )
                }

                NSLog("Failed to roll back global hotkey: \(rollbackStatus)")
                activeShortcut = nil
                return .failure(
                    activeShortcut: nil,
                    message: Self.rollbackFailureMessage(
                        registerStatus: registerStatus,
                        rollbackStatus: rollbackStatus,
                        copy: copy
                    )
                )
            }

            activeShortcut = nil
            return .failure(activeShortcut: nil, message: Self.hotKeyErrorMessage(status: registerStatus, copy: copy))
        }

        activeShortcut = shortcut
        lastValidShortcut = shortcut
        return .success
    }

    func stop() {
        unregisterHotKey()
        activeShortcut = nil
    }

    private func ensureEventHandlerInstalled() -> OSStatus {
        if eventHandler != nil {
            return noErr
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        return InstallEventHandler(
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
    }

    private func register(shortcut: WakeShortcut) -> OSStatus {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4C545247), id: 1)
        return RegisterEventHotKey(
            shortcut.key.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private static func osStatusMessage(_ status: OSStatus) -> String {
        let systemMessage = SecCopyErrorMessageString(status, nil) as String?
        return systemMessage ?? "OSStatus \(status)"
    }

    private static func hotKeyErrorMessage(status: OSStatus, copy: LocalizedCopy) -> String {
        copy.wakeShortcutRegistrationFailed(detail: osStatusMessage(status))
    }

    private static func rollbackMessage(
        requested: WakeShortcut,
        fallback: WakeShortcut,
        status: OSStatus,
        copy: LocalizedCopy
    ) -> String {
        copy.wakeShortcutRolledBack(
            requested: requested,
            fallback: fallback,
            detail: osStatusMessage(status)
        )
    }

    private static func rollbackFailureMessage(
        registerStatus: OSStatus,
        rollbackStatus: OSStatus,
        copy: LocalizedCopy
    ) -> String {
        copy.wakeShortcutRollbackFailed(
            detail: osStatusMessage(registerStatus),
            rollbackDetail: osStatusMessage(rollbackStatus)
        )
    }
}
