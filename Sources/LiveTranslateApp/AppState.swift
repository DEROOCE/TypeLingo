import AppKit
import Carbon
import Foundation
import SwiftUI
import UniformTypeIdentifiers

let defaultOpenAISystemPrompt = """
You are a live subtitle translator.
Translate the user's text into {{target_language}}.
Keep the meaning accurate and natural.
Preserve tone.
Return only the translated text.
Do not add explanations, labels, quotes, or markdown.
"""

let meetingOpenAISystemPrompt = """
You are translating live meeting subtitles into {{target_language}}.
Prioritize clarity and professional tone.
Keep terminology consistent.
Return only the translated text.
"""

let streamingOpenAISystemPrompt = """
You are translating live stream subtitles into {{target_language}}.
Keep the output short, punchy, and easy to read quickly on screen.
Return only the translated text.
"""

enum ShortcutKey: String, CaseIterable, Identifiable, Codable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    init?(keyCode: UInt16) {
        switch Int(keyCode) {
        case kVK_ANSI_A: self = .a
        case kVK_ANSI_B: self = .b
        case kVK_ANSI_C: self = .c
        case kVK_ANSI_D: self = .d
        case kVK_ANSI_E: self = .e
        case kVK_ANSI_F: self = .f
        case kVK_ANSI_G: self = .g
        case kVK_ANSI_H: self = .h
        case kVK_ANSI_I: self = .i
        case kVK_ANSI_J: self = .j
        case kVK_ANSI_K: self = .k
        case kVK_ANSI_L: self = .l
        case kVK_ANSI_M: self = .m
        case kVK_ANSI_N: self = .n
        case kVK_ANSI_O: self = .o
        case kVK_ANSI_P: self = .p
        case kVK_ANSI_Q: self = .q
        case kVK_ANSI_R: self = .r
        case kVK_ANSI_S: self = .s
        case kVK_ANSI_T: self = .t
        case kVK_ANSI_U: self = .u
        case kVK_ANSI_V: self = .v
        case kVK_ANSI_W: self = .w
        case kVK_ANSI_X: self = .x
        case kVK_ANSI_Y: self = .y
        case kVK_ANSI_Z: self = .z
        case kVK_ANSI_0: self = .zero
        case kVK_ANSI_1: self = .one
        case kVK_ANSI_2: self = .two
        case kVK_ANSI_3: self = .three
        case kVK_ANSI_4: self = .four
        case kVK_ANSI_5: self = .five
        case kVK_ANSI_6: self = .six
        case kVK_ANSI_7: self = .seven
        case kVK_ANSI_8: self = .eight
        case kVK_ANSI_9: self = .nine
        default:
            return nil
        }
    }

    var keyCode: UInt32 {
        switch self {
        case .a: return UInt32(kVK_ANSI_A)
        case .b: return UInt32(kVK_ANSI_B)
        case .c: return UInt32(kVK_ANSI_C)
        case .d: return UInt32(kVK_ANSI_D)
        case .e: return UInt32(kVK_ANSI_E)
        case .f: return UInt32(kVK_ANSI_F)
        case .g: return UInt32(kVK_ANSI_G)
        case .h: return UInt32(kVK_ANSI_H)
        case .i: return UInt32(kVK_ANSI_I)
        case .j: return UInt32(kVK_ANSI_J)
        case .k: return UInt32(kVK_ANSI_K)
        case .l: return UInt32(kVK_ANSI_L)
        case .m: return UInt32(kVK_ANSI_M)
        case .n: return UInt32(kVK_ANSI_N)
        case .o: return UInt32(kVK_ANSI_O)
        case .p: return UInt32(kVK_ANSI_P)
        case .q: return UInt32(kVK_ANSI_Q)
        case .r: return UInt32(kVK_ANSI_R)
        case .s: return UInt32(kVK_ANSI_S)
        case .t: return UInt32(kVK_ANSI_T)
        case .u: return UInt32(kVK_ANSI_U)
        case .v: return UInt32(kVK_ANSI_V)
        case .w: return UInt32(kVK_ANSI_W)
        case .x: return UInt32(kVK_ANSI_X)
        case .y: return UInt32(kVK_ANSI_Y)
        case .z: return UInt32(kVK_ANSI_Z)
        case .zero: return UInt32(kVK_ANSI_0)
        case .one: return UInt32(kVK_ANSI_1)
        case .two: return UInt32(kVK_ANSI_2)
        case .three: return UInt32(kVK_ANSI_3)
        case .four: return UInt32(kVK_ANSI_4)
        case .five: return UInt32(kVK_ANSI_5)
        case .six: return UInt32(kVK_ANSI_6)
        case .seven: return UInt32(kVK_ANSI_7)
        case .eight: return UInt32(kVK_ANSI_8)
        case .nine: return UInt32(kVK_ANSI_9)
        }
    }
}

enum ShortcutModifier: String, CaseIterable, Identifiable {
    case control
    case option
    case command
    case shift

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .control:
            return "⌃"
        case .option:
            return "⌥"
        case .command:
            return "⌘"
        case .shift:
            return "⇧"
        }
    }

    var displayName: String {
        switch self {
        case .control:
            return "Control"
        case .option:
            return "Option"
        case .command:
            return "Command"
        case .shift:
            return "Shift"
        }
    }

    func localizedDisplayName(language: InterfaceLanguage) -> String {
        guard language == .simplifiedChinese else {
            return displayName
        }

        switch self {
        case .control:
            return "Control"
        case .option:
            return "Option"
        case .command:
            return "Command"
        case .shift:
            return "Shift"
        }
    }
}

struct WakeShortcut: Codable, Equatable {
    var key: ShortcutKey
    var includesControl: Bool
    var includesOption: Bool
    var includesCommand: Bool
    var includesShift: Bool

    static let defaultValue = WakeShortcut(
        key: .t,
        includesControl: true,
        includesOption: true,
        includesCommand: false,
        includesShift: false
    )

    var carbonModifiers: UInt32 {
        var value: UInt32 = 0
        if includesControl {
            value |= UInt32(controlKey)
        }
        if includesOption {
            value |= UInt32(optionKey)
        }
        if includesCommand {
            value |= UInt32(cmdKey)
        }
        if includesShift {
            value |= UInt32(shiftKey)
        }
        return value
    }

    var displayName: String {
        let parts = [
            includesControl ? ShortcutModifier.control.displayName : nil,
            includesOption ? ShortcutModifier.option.displayName : nil,
            includesCommand ? ShortcutModifier.command.displayName : nil,
            includesShift ? ShortcutModifier.shift.displayName : nil,
            key.displayName
        ]
        return parts.compactMap { $0 }.joined(separator: " + ")
    }

    func localizedDisplayName(language: InterfaceLanguage) -> String {
        let parts = [
            includesControl ? ShortcutModifier.control.localizedDisplayName(language: language) : nil,
            includesOption ? ShortcutModifier.option.localizedDisplayName(language: language) : nil,
            includesCommand ? ShortcutModifier.command.localizedDisplayName(language: language) : nil,
            includesShift ? ShortcutModifier.shift.localizedDisplayName(language: language) : nil,
            key.displayName
        ]
        return parts.compactMap { $0 }.joined(separator: " + ")
    }

    var symbolDisplayName: String {
        let symbols = [
            includesControl ? ShortcutModifier.control.symbol : nil,
            includesOption ? ShortcutModifier.option.symbol : nil,
            includesCommand ? ShortcutModifier.command.symbol : nil,
            includesShift ? ShortcutModifier.shift.symbol : nil,
            key.displayName
        ]
        return symbols.compactMap { $0 }.joined(separator: " ")
    }

    var hasAnyModifier: Bool {
        includesControl || includesOption || includesCommand || includesShift
    }

    func includes(_ modifier: ShortcutModifier) -> Bool {
        switch modifier {
        case .control:
            return includesControl
        case .option:
            return includesOption
        case .command:
            return includesCommand
        case .shift:
            return includesShift
        }
    }

    func updating(modifier: ShortcutModifier, enabled: Bool) -> WakeShortcut {
        var copy = self
        switch modifier {
        case .control:
            copy.includesControl = enabled
        case .option:
            copy.includesOption = enabled
        case .command:
            copy.includesCommand = enabled
        case .shift:
            copy.includesShift = enabled
        }
        return copy
    }

    static func from(event: NSEvent) -> WakeShortcut? {
        guard let key = ShortcutKey(keyCode: event.keyCode) else {
            return nil
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return WakeShortcut(
            key: key,
            includesControl: flags.contains(.control),
            includesOption: flags.contains(.option),
            includesCommand: flags.contains(.command),
            includesShift: flags.contains(.shift)
        )
    }
}

@MainActor
final class AppState: ObservableObject {
    enum DefaultsDomain {
        static let primary = "io.github.derooce.typelingo"
        static let legacyBundle = "com.codex.live-translate"
        static let legacyCLI = "live-translate"
    }

    enum DefaultsKey {
        static let interfaceLanguage = "LiveTranslate.InterfaceLanguage"
        static let selectedProvider = "LiveTranslate.SelectedProvider"
        static let selectedProviderProfileID = "LiveTranslate.SelectedProviderProfileID"
        static let selectedPromptProfileID = "LiveTranslate.SelectedPromptProfileID"
        static let targetLanguage = "LiveTranslate.TargetLanguage"
        static let providerProfiles = "LiveTranslate.ProviderProfiles"
        static let promptProfiles = "LiveTranslate.PromptProfiles"
        static let subtitleFontSize = "LiveTranslate.SubtitleFontSize"
        static let overlayOpacity = "LiveTranslate.OverlayOpacity"
        static let wakeShortcut = "LiveTranslate.WakeShortcut"
        static let didPromptAccessibilityOnboarding = "LiveTranslate.DidPromptAccessibilityOnboarding"

        static let legacyOpenAIAPIKey = "LiveTranslate.OpenAIAPIKey"
        static let legacyOpenAIBaseURL = "LiveTranslate.OpenAIBaseURL"
        static let legacyOpenAIModel = "LiveTranslate.OpenAIModel"
        static let legacyOpenAISystemPrompt = "LiveTranslate.OpenAISystemPrompt"
    }

    @Published var isAccessibilityTrusted: Bool
    @Published var sourceText: String
    @Published var translatedText: String
    @Published var providerStatus: String
    @Published var interfaceLanguage: InterfaceLanguage {
        didSet {
            defaults.set(interfaceLanguage.rawValue, forKey: DefaultsKey.interfaceLanguage)
            providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired
        }
    }
    @Published var selectedProvider: TranslationProviderKind {
        didSet {
            defaults.set(selectedProvider.rawValue, forKey: DefaultsKey.selectedProvider)
            scheduleTranslation()
        }
    }
    @Published var selectedProviderProfileID: String {
        didSet {
            defaults.set(selectedProviderProfileID, forKey: DefaultsKey.selectedProviderProfileID)
            scheduleTranslation()
        }
    }
    @Published var selectedPromptProfileID: String {
        didSet {
            defaults.set(selectedPromptProfileID, forKey: DefaultsKey.selectedPromptProfileID)
            scheduleTranslation()
        }
    }
    @Published var targetLanguage: TargetLanguage {
        didSet {
            defaults.set(targetLanguage.rawValue, forKey: DefaultsKey.targetLanguage)
            scheduleTranslation()
        }
    }
    @Published var lastObservedApp: String
    @Published var lastObservedRole: String
    @Published var overlayOpacity: Double {
        didSet {
            defaults.set(overlayOpacity, forKey: DefaultsKey.overlayOpacity)
            NotificationCenter.default.post(name: .overlaySettingsDidChange, object: nil)
        }
    }
    @Published var subtitleFontSize: Double {
        didSet {
            defaults.set(subtitleFontSize, forKey: DefaultsKey.subtitleFontSize)
        }
    }
    @Published var wakeShortcut: WakeShortcut {
        didSet {
            saveWakeShortcut()
            NotificationCenter.default.post(name: .wakeShortcutDidChange, object: nil)
        }
    }
    @Published var providerProfiles: [AIProviderProfile] {
        didSet {
            saveProviderProfiles()
        }
    }
    @Published var promptProfiles: [PromptProfile] {
        didSet {
            savePromptProfiles()
        }
    }
    @Published var providerTestStatus: String
    @Published var isTestingProvider: Bool
    @Published var settingsTransferStatus: String
    @Published var providerConfigurationWarning: String?
    @Published var wakeShortcutWarning: String?
    @Published var errorMessage: String?

    let defaults: UserDefaults
    let keychainClient: KeychainClient
    private var translationTask: Task<Void, Never>?
    private var providerTestTask: Task<Void, Never>?
    private var lastCapturedSnapshot: CapturedTextSnapshot?
    private var revision = 0
    private var providerTestRevision = 0

    init(
        defaults: UserDefaults = AppState.makeDefaults(),
        keychainClient: KeychainClient = .live
    ) {
        self.defaults = defaults
        self.keychainClient = keychainClient
        Self.migrateLegacyDefaultsIfNeeded(into: defaults)

        let initialCopy = LocalizedCopy(language: InterfaceLanguage(rawValue: defaults.string(forKey: DefaultsKey.interfaceLanguage) ?? InterfaceLanguage.english.rawValue) ?? .english)
        let loadedProviders = Self.loadProviderProfiles(from: defaults, keychainClient: keychainClient, copy: initialCopy)
        let loadedProviderProfiles = loadedProviders.profiles
        let loadedPromptProfiles = Self.loadPromptProfiles(from: defaults)
        let savedInterfaceLanguage = defaults.string(forKey: DefaultsKey.interfaceLanguage) ?? InterfaceLanguage.english.rawValue

        self.isAccessibilityTrusted = AccessibilityAuthorizer.isTrusted(prompt: false)
        self.sourceText = ""
        self.translatedText = ""
        self.providerStatus = ""
        self.interfaceLanguage = InterfaceLanguage(rawValue: savedInterfaceLanguage) ?? .english

        let selectedProviderRaw = defaults.string(forKey: DefaultsKey.selectedProvider) ?? TranslationProviderKind.googleWeb.rawValue
        self.selectedProvider = TranslationProviderKind(rawValue: selectedProviderRaw) ?? .googleWeb

        self.providerProfiles = loadedProviderProfiles
        self.promptProfiles = loadedPromptProfiles
        self.selectedProviderProfileID = Self.resolveProviderProfileID(
            defaults.string(forKey: DefaultsKey.selectedProviderProfileID),
            profiles: loadedProviderProfiles
        )
        self.selectedPromptProfileID = Self.resolvePromptProfileID(
            defaults.string(forKey: DefaultsKey.selectedPromptProfileID),
            profiles: loadedPromptProfiles
        )

        let savedTargetLanguage = defaults.string(forKey: DefaultsKey.targetLanguage) ?? TargetLanguage.english.rawValue
        self.targetLanguage = TargetLanguage(rawValue: savedTargetLanguage) ?? .english

        self.lastObservedApp = "-"
        self.lastObservedRole = "-"

        let savedOpacity = defaults.object(forKey: DefaultsKey.overlayOpacity) as? Double
        self.overlayOpacity = savedOpacity ?? 0.92

        let savedSubtitleSize = defaults.double(forKey: DefaultsKey.subtitleFontSize)
        self.subtitleFontSize = savedSubtitleSize == 0 ? 30 : savedSubtitleSize
        self.wakeShortcut = Self.loadWakeShortcut(from: defaults)

        self.providerTestStatus = initialCopy.notTested
        self.isTestingProvider = false
        self.settingsTransferStatus = initialCopy.noSettingsTransferYet
        self.providerConfigurationWarning = loadedProviders.warningMessage
        self.wakeShortcutWarning = nil
        self.errorMessage = nil
        self.lastCapturedSnapshot = nil
        self.providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired

        saveProviderProfiles()
        savePromptProfiles()
        defaults.set(selectedProviderProfileID, forKey: DefaultsKey.selectedProviderProfileID)
        defaults.set(selectedPromptProfileID, forKey: DefaultsKey.selectedPromptProfileID)
        Self.cleanupLegacyDefaults(in: defaults, keychainClient: keychainClient)
        if let warningMessage = loadedProviders.warningMessage {
            providerConfigurationWarning = warningMessage
        }
    }

    var currentProviderProfile: AIProviderProfile? {
        providerProfiles.first(where: { $0.id == selectedProviderProfileID })
    }

    var wakeShortcutDisplayName: String {
        wakeShortcut.localizedDisplayName(language: interfaceLanguage)
    }

    var currentPromptProfile: PromptProfile? {
        promptProfiles.first(where: { $0.id == selectedPromptProfileID })
    }

    var currentProviderDisplayName: String {
        switch selectedProvider {
        case .googleWeb:
            return TranslationProviderKind.googleWeb.displayName
        case .openAICompatible:
            return currentProviderProfile?.name ?? copy.defaultLLMProviderName
        }
    }

    var copy: LocalizedCopy {
        LocalizedCopy(language: interfaceLanguage)
    }

    func requestAccessibilityPermission() {
        isAccessibilityTrusted = AccessibilityAuthorizer.isTrusted(prompt: true)
        providerStatus = isAccessibilityTrusted
            ? copy.accessibilityEnabledStatus
            : copy.grantAccessibilityInSettings
    }

    func shouldPromptAccessibilityOnLaunch() -> Bool {
        guard !isAccessibilityTrusted else {
            defaults.set(true, forKey: DefaultsKey.didPromptAccessibilityOnboarding)
            return false
        }

        let hasPromptedBefore = defaults.bool(forKey: DefaultsKey.didPromptAccessibilityOnboarding)
        guard !hasPromptedBefore else {
            return false
        }

        defaults.set(true, forKey: DefaultsKey.didPromptAccessibilityOnboarding)
        return true
    }

    func openAccessibilitySettings() {
        AccessibilityAuthorizer.openAccessibilitySettings()
    }

    func updateAccessibilityTrust(_ trusted: Bool) {
        isAccessibilityTrusted = trusted
        if !trusted {
            providerStatus = copy.accessibilityPermissionRequired
            translatedText = ""
        }
    }

    func updateCapturedText(_ snapshot: CapturedTextSnapshot) {
        let didContextChange = lastCapturedSnapshot?.appName != snapshot.appName
            || lastCapturedSnapshot?.bundleIdentifier != snapshot.bundleIdentifier
            || lastCapturedSnapshot?.role != snapshot.role

        lastObservedApp = snapshot.appName
        lastObservedRole = snapshot.role
        errorMessage = nil
        lastCapturedSnapshot = snapshot

        guard snapshot.text != sourceText || didContextChange else {
            return
        }

        sourceText = snapshot.text
        scheduleTranslation()
    }

    func clearCapturedText() {
        lastCapturedSnapshot = nil
        guard !sourceText.isEmpty || !translatedText.isEmpty || errorMessage != nil else {
            providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired
            return
        }

        translationTask?.cancel()
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired
    }

    func chooseGoogleProvider() {
        selectedProvider = .googleWeb
    }

    func updateWakeShortcutKey(_ key: ShortcutKey) {
        var shortcut = wakeShortcut
        shortcut.key = key
        wakeShortcut = shortcut
    }

    func updateWakeShortcut(_ shortcut: WakeShortcut) {
        wakeShortcut = shortcut
    }

    func applyWakeShortcutRegistrationResult(_ result: HotKeyRegistrationResult) {
        switch result {
        case .success:
            wakeShortcutWarning = nil
        case let .rolledBack(activeShortcut, message):
            wakeShortcutWarning = message
            if activeShortcut != wakeShortcut {
                wakeShortcut = activeShortcut
            }
        case let .failure(activeShortcut, message):
            wakeShortcutWarning = message
            if let activeShortcut, activeShortcut != wakeShortcut {
                wakeShortcut = activeShortcut
            }
        }
    }

    func updateWakeShortcutRecorderHint(_ text: String) {
        wakeShortcutWarning = text.isEmpty ? nil : text
    }

    func setWakeShortcutModifier(_ modifier: ShortcutModifier, enabled: Bool) {
        wakeShortcut = wakeShortcut.updating(modifier: modifier, enabled: enabled)
    }


    func chooseProviderProfile(id: String) {
        guard providerProfiles.contains(where: { $0.id == id }) else {
            return
        }

        selectedProvider = .openAICompatible
        selectedProviderProfileID = id
    }

    func updateSelectedProviderProfile(_ mutate: (inout AIProviderProfile) -> Void) {
        guard let index = providerProfiles.firstIndex(where: { $0.id == selectedProviderProfileID }) else {
            return
        }

        var profile = providerProfiles[index]
        mutate(&profile)
        providerProfiles[index] = profile

        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }

    func addProviderProfile() {
        let index = providerProfiles.count + 1
        let profile = AIProviderProfile(
            id: UUID().uuidString,
            name: copy.numberedLLMApiProfile(index),
            apiKey: "",
            baseURL: "https://api.openai.com/v1",
            model: "gpt-4.1-mini"
        )
        providerProfiles.append(profile)
        selectedProviderProfileID = profile.id
        selectedProvider = .openAICompatible
    }

    func duplicateSelectedProviderProfile() {
        guard let profile = currentProviderProfile else {
            addProviderProfile()
            return
        }

        var duplicate = profile
        duplicate.id = UUID().uuidString
        duplicate.name = copy.copiedProfileName(profile.name)
        providerProfiles.append(duplicate)
        selectedProviderProfileID = duplicate.id
        selectedProvider = .openAICompatible
    }

    func removeSelectedProviderProfile() {
        guard providerProfiles.count > 1,
              let index = providerProfiles.firstIndex(where: { $0.id == selectedProviderProfileID }) else {
            return
        }

        let removedProfile = providerProfiles[index]
        providerProfiles.remove(at: index)
        do {
            try keychainClient.deleteAPIKey(removedProfile.id)
        } catch {
            appendProviderConfigurationWarning(providerConfigurationDeleteWarningMessage(for: removedProfile.name, error: error))
        }
        selectedProviderProfileID = providerProfiles[min(index, providerProfiles.count - 1)].id
        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }


    func clearWakeShortcutWarning() {
        wakeShortcutWarning = nil
    }

    func setWakeShortcutWarning(_ message: String) {
        wakeShortcutWarning = message
    }

    func updateSelectedPromptProfile(_ mutate: (inout PromptProfile) -> Void) {
        guard let index = promptProfiles.firstIndex(where: { $0.id == selectedPromptProfileID }) else {
            return
        }

        var profile = promptProfiles[index]
        mutate(&profile)
        promptProfiles[index] = profile

        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }

    func addPromptProfile() {
        let profile = PromptProfile(
            id: UUID().uuidString,
            name: copy.numberedPromptProfile(promptProfiles.count + 1),
            prompt: defaultOpenAISystemPrompt
        )
        promptProfiles.append(profile)
        selectedPromptProfileID = profile.id
        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }

    func duplicateSelectedPromptProfile() {
        guard let profile = currentPromptProfile else {
            addPromptProfile()
            return
        }

        var duplicate = profile
        duplicate.id = UUID().uuidString
        duplicate.name = copy.copiedProfileName(profile.name)
        promptProfiles.append(duplicate)
        selectedPromptProfileID = duplicate.id
        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }

    func removeSelectedPromptProfile() {
        guard promptProfiles.count > 1,
              let index = promptProfiles.firstIndex(where: { $0.id == selectedPromptProfileID }) else {
            return
        }

        promptProfiles.remove(at: index)
        selectedPromptProfileID = promptProfiles[min(index, promptProfiles.count - 1)].id
        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
    }

    func resetSelectedPromptProfileToPreset() {
        guard let current = currentPromptProfile else {
            return
        }

        let preset = Self.defaultPromptProfiles().first(where: { $0.name == current.name })?.prompt ?? defaultOpenAISystemPrompt
        updateSelectedPromptProfile { $0.prompt = preset }
    }

    func testCurrentProvider() {
        testProvider(provider: selectedProvider, providerProfileID: selectedProviderProfileID, promptProfileID: selectedPromptProfileID)
    }

    func testSelectedLLMProfile() {
        testProvider(provider: .openAICompatible, providerProfileID: selectedProviderProfileID, promptProfileID: selectedPromptProfileID)
    }

    private func testProvider(
        provider: TranslationProviderKind,
        providerProfileID: String,
        promptProfileID: String
    ) {
        providerTestTask?.cancel()
        providerTestRevision += 1
        let currentProviderTestRevision = providerTestRevision
        isTestingProvider = true
        providerTestStatus = copy.testing

        let config = TranslationConfiguration(
            openAIProfile: providerProfiles.first(where: { $0.id == providerProfileID }),
            promptProfile: promptProfiles.first(where: { $0.id == promptProfileID })
        )
        let testedProviderName = provider == .googleWeb
            ? copy.googleWebProviderName
            : (providerProfiles.first(where: { $0.id == providerProfileID })?.name ?? copy.defaultLLMProviderName)

        providerTestTask = Task {
            do {
                let service = TranslationService(
                    provider: provider,
                    configuration: config,
                    requestTimeout: 5
                )
                let result = try await service.translate(text: "你好，世界", targetLanguage: .english)

                await MainActor.run {
                    guard currentProviderTestRevision == self.providerTestRevision else {
                        return
                    }
                    self.isTestingProvider = false
                    self.providerTestTask = nil
                    self.providerTestStatus = result.translatedText.isEmpty
                        ? self.copy.providerTestingEmptyResponse(providerName: testedProviderName)
                        : self.copy.providerTestingSuccess(providerName: testedProviderName, latencyMs: result.latencyMs, result: result.translatedText)
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard currentProviderTestRevision == self.providerTestRevision else {
                        return
                    }
                    self.isTestingProvider = false
                    self.providerTestTask = nil
                    self.providerTestStatus = self.copy.notTested
                }
            } catch {
                await MainActor.run {
                    guard currentProviderTestRevision == self.providerTestRevision else {
                        return
                    }
                    self.isTestingProvider = false
                    self.providerTestTask = nil
                    self.providerTestStatus = self.copy.providerTestingFailure(providerName: testedProviderName, detail: error.localizedDescription)
                }
            }
        }
    }

    private func scheduleTranslation() {
        translationTask?.cancel()
        revision += 1
        let currentRevision = revision

        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired
            errorMessage = nil
            return
        }

        providerStatus = copy.translatingVia(providerName: currentProviderDisplayName)
        let config = TranslationConfiguration(
            openAIProfile: currentProviderProfile,
            promptProfile: currentPromptProfile
        )

        translationTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(trimmed.count < 24 ? 180 : 280))
                try Task.checkCancellation()

                let service = TranslationService(
                    provider: selectedProvider,
                    configuration: config
                )
                let result = try await service.translate(
                    text: trimmed,
                    targetLanguage: targetLanguage
                )
                try Task.checkCancellation()

                await MainActor.run {
                    guard currentRevision == self.revision else {
                        return
                    }

                    self.translatedText = result.translatedText
                    self.providerStatus = self.copy.translationStatus(providerName: self.currentProviderDisplayName, latencyMs: result.latencyMs)
                    self.errorMessage = nil
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard currentRevision == self.revision else {
                        return
                    }

                    self.providerStatus = self.copy.translationFailed
                    self.errorMessage = error.localizedDescription
                    self.translatedText = ""
                }
            }
        }
    }

}

extension Notification.Name {
    static let overlaySettingsDidChange = Notification.Name("OverlaySettingsDidChange")
    static let overlayShowControlPanel = Notification.Name("OverlayShowControlPanel")
    static let overlayHideRequested = Notification.Name("OverlayHideRequested")
    static let overlayShowRequested = Notification.Name("OverlayShowRequested")
    static let overlayToggleRequested = Notification.Name("OverlayToggleRequested")
    static let wakeShortcutDidChange = Notification.Name("WakeShortcutDidChange")
    static let wakeShortcutRecordingDidChange = Notification.Name("WakeShortcutRecordingDidChange")
}

enum SettingsPanelTab: String, CaseIterable, Identifiable {
    case general
    case providers
    case prompts
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .providers:
            return "Providers"
        case .prompts:
            return "Prompts"
        case .diagnostics:
            return "Diagnostics"
        }
    }

    var symbolName: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .providers:
            return "network"
        case .prompts:
            return "text.quote"
        case .diagnostics:
            return "waveform.path.ecg"
        }
    }
}

struct ControlPanelView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: SettingsPanelTab = .general

    private var copy: LocalizedCopy { appState.copy }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                tabPicker
                tabContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TypeLingo")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(copy.appTagline)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    SummaryPill(
                        title: appState.isAccessibilityTrusted ? copy.accessibilityReady : copy.accessibilityNeeded,
                        symbolName: appState.isAccessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tint: appState.isAccessibilityTrusted ? .green : .orange
                    )
                    SummaryPill(
                        title: appState.currentProviderDisplayName,
                        symbolName: appState.selectedProvider == .googleWeb ? "globe" : "network",
                        tint: .blue
                    )
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlBackgroundColor),
                            Color(nsColor: .windowBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(SettingsPanelTab.allCases) { tab in
                Label(localizedTabTitle(tab), systemImage: tab.symbolName).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private func localizedTabTitle(_ tab: SettingsPanelTab) -> String {
        switch tab {
        case .general: return copy.generalTab
        case .providers: return copy.providersTab
        case .prompts: return copy.promptsTab
        case .diagnostics: return copy.diagnosticsTab
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            generalContent
        case .providers:
            providersContent
        case .prompts:
            promptsContent
        case .diagnostics:
            diagnosticsContent
        }
    }

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard(
                title: copy.quickControlsTitle,
                subtitle: copy.quickControlsSubtitle
            ) {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                    GridRow {
                        settingLabel(copy.interfaceLanguage, detail: copy.interfaceLanguageDetail)
                        Picker(copy.interfaceLanguage, selection: $appState.interfaceLanguage) {
                            ForEach(InterfaceLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 220, alignment: .leading)
                    }

                    GridRow {
                        settingLabel(copy.targetLanguage, detail: copy.targetLanguageDetail)
                        Picker(copy.targetLanguage, selection: $appState.targetLanguage) {
                            ForEach(TargetLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 220, alignment: .leading)
                    }

                    GridRow {
                        settingLabel(copy.overlay, detail: copy.overlayDetail)
                        HStack(spacing: 12) {
                            Button(copy.showOverlay) {
                                NotificationCenter.default.post(name: .overlayShowRequested, object: nil)
                            }
                            .buttonStyle(.borderedProminent)

                            Text(copy.wakeShortcutHint)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy.wakeShortcut)
                                .font(.system(size: 16, weight: .semibold))
                            Text(copy.wakeShortcutDetail)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(appState.wakeShortcut.symbolDisplayName)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.06), in: Capsule())
                    }

                    ShortcutRecorderCard(appState: appState)

                    Text("\(copy.currentShortcutPrefix) \(appState.wakeShortcutDisplayName)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if let wakeShortcutWarning = appState.wakeShortcutWarning {
                        Text(wakeShortcutWarning)
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 14) {
                    sliderRow(
                        title: copy.backgroundOpacity,
                        value: "\(Int(appState.overlayOpacity * 100))%"
                    ) {
                        Slider(value: $appState.overlayOpacity, in: 0.22...0.96)
                    }

                    sliderRow(
                        title: copy.subtitleSize,
                        value: "\(Int(appState.subtitleFontSize)) pt"
                    ) {
                        Slider(value: $appState.subtitleFontSize, in: 22...52, step: 1)
                    }
                }
            }

            settingsCard(
                title: copy.accessibilityPermissionTitle,
                subtitle: copy.accessibilityPermissionSubtitle
            ) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: appState.isAccessibilityTrusted ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(appState.isAccessibilityTrusted ? .green : .orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(appState.isAccessibilityTrusted ? copy.accessibilityEnabled : copy.accessibilityRequired)
                            .font(.system(size: 16, weight: .semibold))

                        Text(copy.accessibilityExplainer)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button(copy.requestPermission) {
                                appState.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)

                            Button(copy.openSettings) {
                                appState.openAccessibilitySettings()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            settingsCard(
                title: copy.settingsBackupTitle,
                subtitle: copy.settingsBackupSubtitle
            ) {
                HStack(spacing: 12) {
                    Button(copy.exportSettings) {
                        appState.exportSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(copy.exportWithAPIKeys) {
                        appState.exportSettings(includeSecrets: true)
                    }
                    .buttonStyle(.bordered)

                    Button(copy.importSettings) {
                        appState.importSettings()
                    }
                    .buttonStyle(.bordered)
                }

                Text(copy.exportSettingsDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(appState.settingsTransferStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var providersContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard(
                title: copy.translationProviderTitle,
                subtitle: copy.translationProviderSubtitle
            ) {
                Picker(copy.activeProvider, selection: $appState.selectedProvider) {
                    Text(TranslationProviderKind.googleWeb.displayName).tag(TranslationProviderKind.googleWeb)
                    Text(TranslationProviderKind.openAICompatible.displayName).tag(TranslationProviderKind.openAICompatible)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    Button(appState.isTestingProvider ? copy.testing : copy.testCurrentProvider) {
                        appState.testCurrentProvider()
                    }
                    .disabled(appState.isTestingProvider)
                    .buttonStyle(.borderedProminent)

                    Text(appState.providerTestStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if let providerConfigurationWarning = appState.providerConfigurationWarning {
                    Text(providerConfigurationWarning)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
            }

            settingsCard(
                title: copy.apiProfilesTitle,
                subtitle: copy.apiProfilesSubtitle
            ) {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                    GridRow {
                        settingLabel(copy.activeAPIProfile, detail: copy.activeAPIProfileDetail)
                        Picker(copy.activeAPIProfile, selection: $appState.selectedProviderProfileID) {
                            ForEach(appState.providerProfiles) { profile in
                                Text(profile.name).tag(profile.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 240, alignment: .leading)
                    }
                }

                HStack(spacing: 10) {
                    Button(copy.addAPIProfile) {
                        appState.addProviderProfile()
                    }
                    Button(copy.duplicate) {
                        appState.duplicateSelectedProviderProfile()
                    }
                    Button(copy.remove) {
                        appState.removeSelectedProviderProfile()
                    }
                    .disabled(appState.providerProfiles.count == 1)
                }

                if let currentProviderProfile = appState.currentProviderProfile {
                    Divider()

                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                        GridRow {
                            settingLabel(copy.profileName, detail: "")
                            TextField(copy.profileName, text: providerProfileBinding(\.name))
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            settingLabel(copy.apiKey, detail: "")
                            SecureField(copy.apiKey, text: providerProfileBinding(\.apiKey))
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            settingLabel(copy.baseURL, detail: "")
                            TextField(copy.baseURL, text: providerProfileBinding(\.baseURL))
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            settingLabel(copy.model, detail: "")
                            TextField(copy.model, text: providerProfileBinding(\.model))
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    HStack(spacing: 12) {
                        Button(appState.isTestingProvider ? copy.testing : copy.testSelectedAPIProfile) {
                            appState.testSelectedLLMProfile()
                        }
                        .disabled(appState.isTestingProvider)
                        .buttonStyle(.bordered)

                        Text(currentProviderProfile.id)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private var promptsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard(
                title: copy.promptProfilesTitle,
                subtitle: copy.promptProfilesSubtitle
            ) {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                    GridRow {
                        settingLabel(copy.activePrompt, detail: copy.activePromptDetail)
                        Picker(copy.activePrompt, selection: $appState.selectedPromptProfileID) {
                            ForEach(appState.promptProfiles) { profile in
                                Text(profile.name).tag(profile.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 240, alignment: .leading)
                    }
                }

                HStack(spacing: 10) {
                    Button(copy.addPromptProfile) {
                        appState.addPromptProfile()
                    }
                    Button(copy.duplicate) {
                        appState.duplicateSelectedPromptProfile()
                    }
                    Button(copy.remove) {
                        appState.removeSelectedPromptProfile()
                    }
                    .disabled(appState.promptProfiles.count == 1)
                    Button(copy.resetToPreset) {
                        appState.resetSelectedPromptProfileToPreset()
                    }
                }

                Divider()

                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                    GridRow {
                        settingLabel(copy.promptProfileName, detail: "")
                        TextField(copy.promptProfileName, text: promptProfileBinding(\.name))
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow(alignment: .top) {
                        settingLabel(copy.activePrompt, detail: copy.promptPlaceholderHelp)
                        TextEditor(text: promptProfileBinding(\.prompt))
                            .font(.system(size: 13, design: .monospaced))
                            .frame(minHeight: 220)
                            .padding(8)
                            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Text(copy.promptPlaceholderHelp)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var diagnosticsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard(
                title: copy.liveStateTitle,
                subtitle: copy.liveStateSubtitle
            ) {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 160), spacing: 12),
                    GridItem(.flexible(minimum: 160), spacing: 12)
                ], alignment: .leading, spacing: 12) {
                    diagnosticValueCard(copy.focusedApp, value: appState.lastObservedApp)
                    diagnosticValueCard(copy.focusedRole, value: appState.lastObservedRole)
                    diagnosticValueCard(copy.activeProvider, value: appState.currentProviderDisplayName)
                    diagnosticValueCard(copy.activePromptCard, value: appState.currentPromptProfile?.name ?? copy.currentPromptDiagnosticsFallback)
                    diagnosticValueCard(copy.status, value: appState.providerStatus)
                    diagnosticValueCard(copy.wakeShortcut, value: appState.wakeShortcut.symbolDisplayName)
                }

                textPanel(title: copy.capturedText, text: appState.sourceText.isEmpty ? copy.noCapturedText : appState.sourceText)
                textPanel(title: copy.translatedText, text: appState.translatedText.isEmpty ? copy.noTranslationYet : appState.translatedText)

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }

                if let providerConfigurationWarning = appState.providerConfigurationWarning {
                    Text(providerConfigurationWarning)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }

                if let wakeShortcutWarning = appState.wakeShortcutWarning {
                    Text(wakeShortcutWarning)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
            }

            settingsCard(
                title: copy.prototypeNotesTitle,
                subtitle: copy.prototypeNotesSubtitle
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    diagnosticNote(copy.noteIME)
                    diagnosticNote(copy.noteSecure)
                    diagnosticNote(copy.noteNearCaret)
                    diagnosticNote(copy.noteIMEPath)
                }
            }
        }
    }

    private func settingLabel(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sliderRow<Content: View>(title: String, value: String, @ViewBuilder slider: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(value)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            slider()
        }
    }

    private func textPanel(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            ScrollView {
                Text(text)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 110)
            .padding(12)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func diagnosticValueCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func diagnosticNote(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }

    private func settingsCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }

    private func providerProfileBinding(_ keyPath: WritableKeyPath<AIProviderProfile, String>) -> Binding<String> {
        Binding(
            get: { appState.currentProviderProfile?[keyPath: keyPath] ?? "" },
            set: { newValue in
                appState.updateSelectedProviderProfile { profile in
                    profile[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func promptProfileBinding(_ keyPath: WritableKeyPath<PromptProfile, String>) -> Binding<String> {
        Binding(
            get: { appState.currentPromptProfile?[keyPath: keyPath] ?? "" },
            set: { newValue in
                appState.updateSelectedPromptProfile { profile in
                    profile[keyPath: keyPath] = newValue
                }
            }
        )
    }
}

struct SummaryPill: View {
    let title: String
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
            Text(title)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10), in: Capsule())
    }
}

struct ShortcutRecorderCard: View {
    @ObservedObject var appState: AppState

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var hintText = ""

    private var copy: LocalizedCopy { appState.copy }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if isRecording {
                    Button(copy.recording) {
                        toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(copy.recordShortcut) {
                        toggleRecording()
                    }
                    .buttonStyle(.bordered)
                }

                if isRecording {
                    Button(copy.cancel) {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Text(appState.wakeShortcut.symbolDisplayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Text(hintText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear {
            if hintText.isEmpty {
                hintText = idleHint
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true
        hintText = recordingHint
        NotificationCenter.default.post(
            name: .wakeShortcutRecordingDidChange,
            object: nil,
            userInfo: ["isRecording": true]
        )

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        if isRecording {
            NotificationCenter.default.post(
                name: .wakeShortcutRecordingDidChange,
                object: nil,
                userInfo: ["isRecording": false]
            )
        }

        isRecording = false
        if hintText == recordingHint {
            hintText = idleHint
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isRecording else {
            return event
        }

        if event.keyCode == UInt16(kVK_Escape) {
            hintText = copy.recordingCancelled
            stopRecording()
            return nil
        }

        guard let shortcut = WakeShortcut.from(event: event) else {
            hintText = copy.unsupportedShortcutKey
            return nil
        }

        guard shortcut.hasAnyModifier else {
            hintText = copy.shortcutNeedsModifier
            return nil
        }

        appState.updateWakeShortcut(shortcut)
        hintText = appState.copy.applyingShortcut(shortcut)
        stopRecording()
        return nil
    }

    private var idleHint: String {
        copy.shortcutRecorderIdleHint
    }

    private var recordingHint: String {
        copy.shortcutRecorderRecordingHint
    }
}

struct ShortcutModifierButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 70)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.black.opacity(0.05))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
