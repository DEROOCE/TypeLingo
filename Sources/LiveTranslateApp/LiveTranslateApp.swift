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
    private let appState = AppState()
    private let overlayWindowManager = OverlayWindowManager()
    private let hotKeyManager = GlobalHotKeyManager.shared
    private var accessibilityMonitor: AccessibilityMonitor?
    private var settingsWindowController: SettingsWindowController?
    private var showSettingsObserver: NSObjectProtocol?
    private var wakeShortcutObserver: NSObjectProtocol?
    private var wakeShortcutRecordingObserver: NSObjectProtocol?
    private var isRecordingWakeShortcut = false

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
                self?.registerWakeShortcut()
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

    private func registerWakeShortcut() {
        guard !isRecordingWakeShortcut else {
            return
        }

        hotKeyManager.start(shortcut: appState.wakeShortcut) {
            NotificationCenter.default.post(name: .overlayToggleRequested, object: nil)
        }
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
