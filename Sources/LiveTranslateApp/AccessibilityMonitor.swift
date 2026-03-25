import AppKit
import ApplicationServices
import Foundation

enum AccessibilityAuthorizer {
    static func isTrusted(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

final class AccessibilityMonitor {
    private weak var appState: AppState?
    private let systemWideElement = AXUIElementCreateSystemWide()
    private let queue = DispatchQueue(label: "live.translate.accessibility")
    private var timer: DispatchSourceTimer?
    private var lastSnapshot: CapturedTextSnapshot?

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(120))
        timer.setEventHandler { [weak self] in
            self?.pollFocusedInput()
        }
        timer.resume()
        self.timer = timer
    }

    deinit {
        timer?.cancel()
    }

    private func pollFocusedInput() {
        let trusted = AccessibilityAuthorizer.isTrusted(prompt: false)
        Task { @MainActor [weak appState] in
            appState?.updateAccessibilityTrust(trusted)
        }

        guard trusted else {
            return
        }

        guard let element = focusedUIElement() else {
            clearSnapshotIfNeeded()
            return
        }

        guard let snapshot = snapshotForFocusedElement(element) else {
            clearSnapshotIfNeeded()
            return
        }

        guard snapshot != lastSnapshot else {
            return
        }

        lastSnapshot = snapshot
        Task { @MainActor [weak appState] in
            appState?.updateCapturedText(snapshot)
        }
    }

    private func clearSnapshotIfNeeded() {
        guard lastSnapshot != nil else {
            return
        }

        lastSnapshot = nil
        Task { @MainActor [weak appState] in
            appState?.clearCapturedText()
        }
    }

    private func focusedUIElement() -> AXUIElement? {
        var focusedElementRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard result == .success, let focusedElementRef else {
            return nil
        }

        return (focusedElementRef as! AXUIElement)
    }

    private func snapshotForFocusedElement(_ element: AXUIElement) -> CapturedTextSnapshot? {
        let role = stringAttribute(kAXRoleAttribute, element: element) ?? "unknown"
        let subrole = stringAttribute(kAXSubroleAttribute, element: element) ?? ""

        guard !subrole.localizedCaseInsensitiveContains("secure") else {
            return nil
        }

        guard isTextInput(role: role, element: element) else {
            return nil
        }

        guard let fullText = stringAttribute(kAXValueAttribute, element: element) else {
            return nil
        }

        let trimmedFullText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFullText.isEmpty else {
            return nil
        }

        let liveText = liveSegment(from: fullText, selectedRange: selectedTextRange(for: element))
        let trimmedLiveText = liveText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLiveText.isEmpty else {
            return nil
        }

        let pid = pid(for: element)
        let app = NSRunningApplication(processIdentifier: pid)

        return CapturedTextSnapshot(
            appName: app?.localizedName ?? "Unknown App",
            bundleIdentifier: app?.bundleIdentifier,
            role: role,
            text: trimmedLiveText
        )
    }

    private func stringAttribute(_ attribute: String, element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else {
            return nil
        }
        return value as? String
    }

    private func boolAttribute(_ attribute: String, element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let number = value as? NSNumber else {
            return nil
        }
        return number.boolValue
    }

    private func pid(for element: AXUIElement) -> pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return pid
    }

    private func isTextInput(role: String, element: AXUIElement) -> Bool {
        let textRoles = [
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            "AXSearchField",
            kAXComboBoxRole as String
        ]

        if textRoles.contains(role) {
            return true
        }

        return boolAttribute("AXEditable", element: element) ?? false
    }

    private func selectedTextRange(for element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value)
        guard result == .success, let rangeValue = value else {
            return nil
        }

        guard CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rangeValue as! AXValue
        guard AXValueGetType(axValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else {
            return nil
        }

        return range
    }

    private func liveSegment(from fullText: String, selectedRange: CFRange?) -> String {
        guard !fullText.isEmpty else {
            return fullText
        }

        let boundedText = fullText.replacingOccurrences(of: "\u{FFFC}", with: "")
        let utf16Count = boundedText.utf16.count
        let caretLocation = min(max(selectedRange?.location ?? utf16Count, 0), utf16Count)
        let utf16View = boundedText.utf16
        let caretUTF16Index = utf16View.index(utf16View.startIndex, offsetBy: caretLocation)

        guard let caretIndex = String.Index(caretUTF16Index, within: boundedText) else {
            return String(boundedText.suffix(220))
        }

        let prefix = boundedText[..<caretIndex]
        let nearCaret = String(prefix.suffix(260))
        let boundaryCharacters = CharacterSet(charactersIn: "\n.!?。！？;；")

        if let boundaryIndex = nearCaret.lastIndex(where: { scalar in
            scalar.unicodeScalars.allSatisfy(boundaryCharacters.contains)
        }) {
            let nextIndex = nearCaret.index(after: boundaryIndex)
            return String(nearCaret[nextIndex...])
        }

        return nearCaret
    }
}
