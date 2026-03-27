import AppKit
import SwiftUI

@main
struct LiveTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState: AppState
    private let overlayWindowManager: OverlayWindowManager
    private let hotKeyManager: HotKeyRegistering
    private var accessibilityMonitor: AccessibilityMonitor?
    private var settingsWindowController: SettingsWindowController?
    private var showSettingsObserver: NSObjectProtocol?
    private var wakeShortcutObserver: NSObjectProtocol?
    private var wakeShortcutRecordingObserver: NSObjectProtocol?
    private var isRecordingWakeShortcut = false
    private var isApplyingWakeShortcutRollback = false

    override init() {
        self.appState = AppState()
        self.overlayWindowManager = OverlayWindowManager()
        self.hotKeyManager = GlobalHotKeyManager.shared
        super.init()
    }

    init(
        appState: AppState,
        overlayWindowManager: OverlayWindowManager = OverlayWindowManager(),
        hotKeyManager: HotKeyRegistering
    ) {
        self.appState = appState
        self.overlayWindowManager = overlayWindowManager
        self.hotKeyManager = hotKeyManager
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        overlayWindowManager.bind(to: appState)

        let monitor = AccessibilityMonitor(appState: appState)
        monitor.start()
        accessibilityMonitor = monitor

        registerWakeShortcut()

        showSettingsObserver = NotificationCenter.default.addObserver(
            forName: .overlayShowControlPanel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showSettingsWindow()
            }
        }

        wakeShortcutObserver = NotificationCenter.default.addObserver(
            forName: .wakeShortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                if self.isApplyingWakeShortcutRollback {
                    self.isApplyingWakeShortcutRollback = false
                    return
                }
                self.registerWakeShortcut()
            }
        }

        wakeShortcutRecordingObserver = NotificationCenter.default.addObserver(
            forName: .wakeShortcutRecordingDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let isRecording = notification.userInfo?["isRecording"] as? Bool ?? false
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.isRecordingWakeShortcut = isRecording
                if isRecording {
                    self.hotKeyManager.stop()
                } else {
                    self.registerWakeShortcut()
                }
            }
        }

        showSettingsWindow()

        if appState.shouldPromptAccessibilityOnLaunch() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.appState.requestAccessibilityPermission()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let showSettingsObserver {
            NotificationCenter.default.removeObserver(showSettingsObserver)
            self.showSettingsObserver = nil
        }
        if let wakeShortcutObserver {
            NotificationCenter.default.removeObserver(wakeShortcutObserver)
            self.wakeShortcutObserver = nil
        }
        if let wakeShortcutRecordingObserver {
            NotificationCenter.default.removeObserver(wakeShortcutRecordingObserver)
            self.wakeShortcutRecordingObserver = nil
        }
    }

    private func shouldSuppressNextWakeShortcutRegistration(for activeShortcut: WakeShortcut?) -> Bool {
        guard let activeShortcut else {
            return false
        }
        return activeShortcut != appState.wakeShortcut
    }

    private func clearWakeShortcutRollbackGuardIfNeeded() {
        if isApplyingWakeShortcutRollback {
            isApplyingWakeShortcutRollback = false
        }
    }

    private func clearWakeShortcutWarningOnSuccess() {
        appState.clearWakeShortcutWarning()
    }

    private func applyWakeShortcutFailure(activeShortcut: WakeShortcut?, message: String) {
        isApplyingWakeShortcutRollback = shouldSuppressNextWakeShortcutRegistration(for: activeShortcut)
        appState.applyWakeShortcutRegistrationResult(.failure(activeShortcut: activeShortcut, message: message))
        if !isApplyingWakeShortcutRollback {
            clearWakeShortcutRollbackGuardIfNeeded()
        }
    }

    private func applyWakeShortcutRollback(activeShortcut: WakeShortcut, message: String) {
        isApplyingWakeShortcutRollback = shouldSuppressNextWakeShortcutRegistration(for: activeShortcut)
        appState.applyWakeShortcutRegistrationResult(.rolledBack(activeShortcut: activeShortcut, message: message))
        if !isApplyingWakeShortcutRollback {
            clearWakeShortcutRollbackGuardIfNeeded()
        }
    }

    private func handleWakeShortcutRegistrationSuccess() {
        clearWakeShortcutWarningOnSuccess()
        clearWakeShortcutRollbackGuardIfNeeded()
    }

    private func removeObserver(_ observer: NSObjectProtocol?) {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    deinit {}


    func handleWakeShortcutRegistrationResult(_ result: HotKeyRegistrationResult) {
        switch result {
        case .success:
            handleWakeShortcutRegistrationSuccess()
        case let .rolledBack(activeShortcut, message):
            applyWakeShortcutRollback(activeShortcut: activeShortcut, message: message)
        case let .failure(activeShortcut, message):
            applyWakeShortcutFailure(activeShortcut: activeShortcut, message: message)
        }
    }

    private func registerWakeShortcut() {
        guard !isRecordingWakeShortcut else {
            return
        }

        let result = hotKeyManager.start(shortcut: appState.wakeShortcut, copy: appState.copy) {
            NotificationCenter.default.post(name: .overlayToggleRequested, object: nil)
        }
        handleWakeShortcutRegistrationResult(result)
    }

    private func showSettingsWindow() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appState: appState)
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    init(appState: AppState) {
        let contentView = ControlPanelView(appState: appState)
            .frame(minWidth: 680, minHeight: 760)

        let window = NSWindow(
            contentRect: NSRect(x: 220, y: 160, width: 760, height: 840),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TypeLingo Settings"
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
