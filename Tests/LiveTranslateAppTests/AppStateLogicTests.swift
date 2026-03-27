import Carbon
import Foundation
import Testing
@testable import LiveTranslateApp

struct AppStateLogicTests {
    private func makeKeychainClient(
        save: @escaping @Sendable (_ value: String, _ profileID: String) throws -> Void = { _, _ in },
        load: @escaping @Sendable (_ profileID: String) throws -> String? = { _ in nil },
        delete: @escaping @Sendable (_ profileID: String) throws -> Void = { _ in }
    ) -> KeychainClient {
        KeychainClient(saveAPIKey: save, loadAPIKey: load, deleteAPIKey: delete)
    }

    private func makeProviderProfile(
        id: String,
        name: String = "Primary",
        apiKey: String,
        baseURL: String = "https://api.example.com/v1",
        model: String = "model-1"
    ) -> AIProviderProfile {
        AIProviderProfile(id: id, name: name, apiKey: apiKey, baseURL: baseURL, model: model)
    }

    private final class MockHotKeyManager: HotKeyRegistering {
        var nextResult: HotKeyRegistrationResult = .success
        private(set) var startedShortcuts: [WakeShortcut] = []
        private(set) var stopCallCount = 0

        func start(shortcut: WakeShortcut, copy: LocalizedCopy, action: @escaping () -> Void) -> HotKeyRegistrationResult {
            startedShortcuts.append(shortcut)
            return nextResult
        }

        func stop() {
            stopCallCount += 1
        }
    }

    private func makeSnapshot(
        appName: String,
        bundleIdentifier: String? = nil,
        role: String = "AXTextArea",
        text: String
    ) -> CapturedTextSnapshot {
        CapturedTextSnapshot(appName: appName, bundleIdentifier: bundleIdentifier, role: role, text: text)
    }

    private final class NeverReturningURLProtocol: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {}
        override func stopLoading() {}
    }

    private func makeTimedOutSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NeverReturningURLProtocol.self]
        configuration.timeoutIntervalForRequest = 0.05
        configuration.timeoutIntervalForResource = 0.05
        return URLSession(configuration: configuration)
    }

    private func makeTestTranslationService(
        provider: TranslationProviderKind,
        configuration: TranslationConfiguration,
        timeout: TimeInterval = 0.05
    ) -> TranslationService {
        TranslationService(
            provider: provider,
            configuration: configuration,
            session: makeTimedOutSession(),
            requestTimeout: timeout
        )
    }

    @MainActor
    private func currentProviderConfig(from appState: AppState) -> TranslationConfiguration {
        TranslationConfiguration(
            openAIProfile: appState.currentProviderProfile,
            promptProfile: appState.currentPromptProfile
        )
    }

    @MainActor
    private func waitUntil(
        timeout: TimeInterval = 1,
        _ predicate: @escaping @MainActor () -> Bool
    ) async {
        let clock = ContinuousClock()
        let start = clock.now
        while await !predicate() {
            if clock.now - start > .seconds(timeout) {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @MainActor
    @Test func translationServiceTestTimeoutFailsFast() async throws {
        let profile = makeProviderProfile(id: "profile-1", apiKey: "sk-test")
        let service = makeTestTranslationService(
            provider: .openAICompatible,
            configuration: TranslationConfiguration(openAIProfile: profile, promptProfile: nil)
        )

        do {
            _ = try await service.translate(text: "你好", targetLanguage: .english)
            Issue.record("Expected provider test request to time out")
        } catch {
            #expect(error.localizedDescription.lowercased().contains("timed out") || error.localizedDescription.lowercased().contains("timeout"))
        }
    }

    @MainActor
    @Test func sameTextDifferentFocusContextUpdatesObservedState() {
        let appState = AppState(defaults: .standard, keychainClient: makeKeychainClient())
        let first = makeSnapshot(appName: "Notes", bundleIdentifier: "com.apple.Notes", text: "hello")
        let second = makeSnapshot(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", text: "hello")

        appState.updateCapturedText(first)
        appState.updateCapturedText(second)

        #expect(appState.lastObservedApp == "Slack")
        #expect(appState.lastObservedRole == "AXTextArea")
        #expect(appState.sourceText == "hello")
        #expect(appState.providerStatus != appState.copy.waitingForInput)
    }

    @MainActor
    @Test func sameTextSameFocusContextStaysStable() {
        let appState = AppState(defaults: .standard, keychainClient: makeKeychainClient())
        let snapshot = makeSnapshot(appName: "Notes", bundleIdentifier: "com.apple.Notes", text: "hello")

        appState.updateCapturedText(snapshot)
        let initialStatus = appState.providerStatus
        appState.updateCapturedText(snapshot)

        #expect(appState.lastObservedApp == "Notes")
        #expect(appState.lastObservedRole == "AXTextArea")
        #expect(appState.sourceText == "hello")
        #expect(appState.providerStatus == initialStatus)
    }

    @MainActor
    @Test func clearCapturedTextClearsFocusRefreshState() {
        let appState = AppState(defaults: .standard, keychainClient: makeKeychainClient())
        appState.updateCapturedText(makeSnapshot(appName: "Notes", bundleIdentifier: "com.apple.Notes", text: "hello"))
        appState.clearCapturedText()
        appState.updateCapturedText(makeSnapshot(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", text: "hello"))

        #expect(appState.lastObservedApp == "Slack")
        #expect(appState.sourceText == "hello")
    }

    @MainActor
    @Test func providerTestResultUsesCapturedProviderName() async throws {
        let defaults = try makeIsolatedDefaults()
        let profiles = [
            makeProviderProfile(id: "profile-1", name: "Profile A", apiKey: "sk-a"),
            makeProviderProfile(id: "profile-2", name: "Profile B", apiKey: "sk-b")
        ]
        try persistProfiles(profiles.map { $0.sanitizedForStorage() }, to: defaults)
        let appState = AppState(
            defaults: defaults,
            keychainClient: makeKeychainClient(load: { profileID in
                switch profileID {
                case "profile-1": return "sk-a"
                case "profile-2": return "sk-b"
                default: return nil
                }
            })
        )

        appState.selectedProvider = .openAICompatible
        appState.selectedProviderProfileID = "profile-1"

        let testedProviderName = appState.currentProviderDisplayName
        appState.providerTestStatus = appState.copy.providerTestingFailure(providerName: testedProviderName, detail: "timed out")
        appState.selectedProviderProfileID = "profile-2"

        #expect(appState.providerTestStatus.contains("Profile A"))
        #expect(!appState.providerTestStatus.contains("Profile B"))
    }

    enum TestFailure: Error {
        case keychainUnavailable
    }

    @MainActor
    private func makeTestAppDelegate(appState: AppState, hotKeyManager: HotKeyRegistering) -> AppDelegate {
        AppDelegate(appState: appState, hotKeyManager: hotKeyManager)
    }

    @MainActor
    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "LiveTranslateAppTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func persistProfiles(_ profiles: [AIProviderProfile], to defaults: UserDefaults) throws {
        let data = try JSONEncoder().encode(profiles)
        defaults.set(data, forKey: "LiveTranslate.ProviderProfiles")
    }

    @MainActor
    private func readPersistedProfiles(from defaults: UserDefaults) throws -> [AIProviderProfile] {
        let data = try #require(defaults.data(forKey: "LiveTranslate.ProviderProfiles"))
        return try JSONDecoder().decode([AIProviderProfile].self, from: data)
    }

    @MainActor
    @Test func appStateInitializationSurvivesKeychainLoadFailure() throws {
        let defaults = try makeIsolatedDefaults()
        let profile = makeProviderProfile(id: "profile-1", apiKey: "sk-secret")
        try persistProfiles([profile], to: defaults)

        let appState = AppState(
            defaults: defaults,
            keychainClient: makeKeychainClient(
                save: { _, _ in },
                load: { _ in throw TestFailure.keychainUnavailable },
                delete: { _ in }
            )
        )

        #expect(appState.providerProfiles.count == 1)
        #expect(appState.providerProfiles[0].name == "Primary")
        #expect(appState.providerProfiles[0].apiKey.isEmpty)
        #expect(appState.providerConfigurationWarning?.contains("Failed to load Keychain data") == true)

        let sanitizedProfiles = try readPersistedProfiles(from: defaults)
        #expect(sanitizedProfiles.count == 1)
        #expect(sanitizedProfiles[0].apiKey.isEmpty)
    }

    @MainActor
    @Test func saveProviderProfilesSanitizesDefaultsEvenWhenKeychainSaveFails() throws {
        let defaults = try makeIsolatedDefaults()
        let profile = makeProviderProfile(id: "profile-1", apiKey: "")
        try persistProfiles([profile.sanitizedForStorage()], to: defaults)

        let appState = AppState(
            defaults: defaults,
            keychainClient: makeKeychainClient(
                save: { _, _ in throw TestFailure.keychainUnavailable },
                load: { _ in nil },
                delete: { _ in }
            )
        )

        appState.updateSelectedProviderProfile { $0.apiKey = "sk-secret" }

        let sanitizedProfiles = try readPersistedProfiles(from: defaults)
        #expect(sanitizedProfiles.count == 1)
        #expect(sanitizedProfiles[0].apiKey.isEmpty)
        #expect(appState.currentProviderProfile?.apiKey == "sk-secret")
        #expect(appState.providerConfigurationWarning?.contains("Keychain persistence failed") == true)
    }

    @MainActor
    @Test func removeSelectedProviderProfileStillRemovesProfileWhenKeychainDeleteFails() throws {
        let defaults = try makeIsolatedDefaults()
        let profiles = [
            makeProviderProfile(id: "profile-1", apiKey: ""),
            makeProviderProfile(id: "profile-2", name: "Backup", apiKey: "")
        ]
        try persistProfiles(profiles.map { $0.sanitizedForStorage() }, to: defaults)

        let appState = AppState(
            defaults: defaults,
            keychainClient: makeKeychainClient(
                save: { _, _ in },
                load: { _ in nil },
                delete: { _ in throw TestFailure.keychainUnavailable }
            )
        )

        appState.selectedProviderProfileID = "profile-1"
        appState.removeSelectedProviderProfile()

        #expect(appState.providerProfiles.count == 1)
        #expect(appState.providerProfiles[0].id == "profile-2")
        #expect(appState.selectedProviderProfileID == "profile-2")
        #expect(appState.providerConfigurationWarning?.contains("Failed to delete Keychain credentials") == true)
    }

    @MainActor
    @Test func legacyPlaintextKeyStaysUntilSecurePersistenceSucceeds() throws {
        let defaults = try makeIsolatedDefaults()
        defaults.set("legacy-secret", forKey: "LiveTranslate.OpenAIAPIKey")
        defaults.set("https://api.example.com/v1", forKey: "LiveTranslate.OpenAIBaseURL")
        defaults.set("model-1", forKey: "LiveTranslate.OpenAIModel")

        _ = AppState(
            defaults: defaults,
            keychainClient: makeKeychainClient(
                save: { _, _ in throw TestFailure.keychainUnavailable },
                load: { _ in nil },
                delete: { _ in }
            )
        )

        #expect(defaults.string(forKey: "LiveTranslate.OpenAIAPIKey") == "legacy-secret")
    }

    @MainActor
    @Test func registerWakeShortcutRecordsNonFatalFailureWhenRegistrationFails() throws {
        let defaults = try makeIsolatedDefaults()
        let appState = AppState(defaults: defaults, keychainClient: makeKeychainClient())
        let attemptedShortcut = WakeShortcut(key: .z, includesControl: true, includesOption: false, includesCommand: false, includesShift: false)
        appState.updateWakeShortcut(attemptedShortcut)
        let hotKeyManager = MockHotKeyManager()
        hotKeyManager.nextResult = .failure(activeShortcut: nil, message: "Wake shortcut registration failed")
        let appDelegate = makeTestAppDelegate(appState: appState, hotKeyManager: hotKeyManager)

        appDelegate.handleWakeShortcutRegistrationResult(hotKeyManager.nextResult)

        #expect(appState.wakeShortcutWarning == "Wake shortcut registration failed")
        #expect(appState.wakeShortcut == attemptedShortcut)
    }

    @MainActor
    @Test func successfulHotkeyRegistrationClearsPreviousFailure() throws {
        let defaults = try makeIsolatedDefaults()
        let appState = AppState(defaults: defaults, keychainClient: makeKeychainClient())
        appState.setWakeShortcutWarning("temporary failure")
        let hotKeyManager = MockHotKeyManager()
        hotKeyManager.nextResult = .success
        let appDelegate = makeTestAppDelegate(appState: appState, hotKeyManager: hotKeyManager)

        appDelegate.handleWakeShortcutRegistrationResult(.success)

        #expect(appState.wakeShortcutWarning == nil)
    }

    @MainActor
    @Test func rolledBackHotkeyRegistrationRestoresPreviousShortcut() throws {
        let defaults = try makeIsolatedDefaults()
        let appState = AppState(defaults: defaults, keychainClient: makeKeychainClient())
        let previousShortcut = WakeShortcut(key: .t, includesControl: true, includesOption: true, includesCommand: false, includesShift: false)
        let attemptedShortcut = WakeShortcut(key: .y, includesControl: true, includesOption: false, includesCommand: true, includesShift: false)
        appState.updateWakeShortcut(previousShortcut)
        let hotKeyManager = MockHotKeyManager()
        let appDelegate = makeTestAppDelegate(appState: appState, hotKeyManager: hotKeyManager)

        appState.updateWakeShortcut(attemptedShortcut)
        appDelegate.handleWakeShortcutRegistrationResult(
            .rolledBack(activeShortcut: previousShortcut, message: "Reverted to previous shortcut")
        )

        #expect(appState.wakeShortcut == previousShortcut)
        #expect(appState.wakeShortcutWarning == "Reverted to previous shortcut")
    }

    @Test func providerProfileSanitizedForStorageRemovesAPIKey() {
        let profile = AIProviderProfile(
            id: "p1",
            name: "Primary",
            apiKey: "sk-secret",
            baseURL: "https://api.example.com/v1",
            model: "model-1"
        )

        let sanitized = profile.sanitizedForStorage()

        #expect(sanitized.id == profile.id)
        #expect(sanitized.name == profile.name)
        #expect(sanitized.baseURL == profile.baseURL)
        #expect(sanitized.model == profile.model)
        #expect(sanitized.apiKey.isEmpty)
    }

    @Test func providerProfileSanitizedForExportDefaultsToNoSecrets() {
        let profile = AIProviderProfile(
            id: "p1",
            name: "Primary",
            apiKey: "sk-secret",
            baseURL: "https://api.example.com/v1",
            model: "model-1"
        )

        #expect(profile.sanitizedForExport(includeSecrets: false).apiKey.isEmpty)
        #expect(profile.sanitizedForExport(includeSecrets: true).apiKey == "sk-secret")
    }

    @Test func wakeShortcutDisplayFormatting() {
        let shortcut = WakeShortcut(
            key: .t,
            includesControl: true,
            includesOption: false,
            includesCommand: true,
            includesShift: false
        )

        #expect(shortcut.displayName == "Control + Command + T")
        #expect(shortcut.symbolDisplayName == "⌃ ⌘ T")
        #expect(shortcut.hasAnyModifier)
    }

    @Test func shortcutKeyMapsFromCarbonKeyCode() {
        #expect(ShortcutKey(keyCode: UInt16(kVK_ANSI_T)) == .t)
        #expect(ShortcutKey(keyCode: UInt16(kVK_ANSI_7)) == .seven)
        #expect(ShortcutKey(keyCode: UInt16(kVK_Return)) == nil)
    }

    @Test func emptyPlaceholderFollowsTargetLanguage() {
        #expect(TargetLanguage.english.emptyTranslationPlaceholder == "Translation will appear here.")
        #expect(TargetLanguage.simplifiedChinese.emptyTranslationPlaceholder == "翻译结果会显示在这里。")
    }

    @Test func wakeShortcutLocalizedDisplayNameStaysReadable() {
        let shortcut = WakeShortcut(
            key: .t,
            includesControl: true,
            includesOption: false,
            includesCommand: true,
            includesShift: false
        )

        #expect(shortcut.localizedDisplayName(language: .english) == "Control + Command + T")
        #expect(shortcut.localizedDisplayName(language: .simplifiedChinese) == "Control + Command + T")
    }

    @MainActor
    @Test func appStateInitializationMigratesPlaintextKeysOutOfDefaults() throws {
        let suiteName = "LiveTranslateAppTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let storedProfiles = [
            AIProviderProfile(
                id: "profile-1",
                name: "Primary",
                apiKey: "sk-secret",
                baseURL: "https://api.example.com/v1",
                model: "model-1"
            )
        ]
        let data = try JSONEncoder().encode(storedProfiles)
        defaults.set(data, forKey: "LiveTranslate.ProviderProfiles")
        defaults.set("legacy-secret", forKey: "LiveTranslate.OpenAIAPIKey")

        _ = AppState(defaults: defaults)

        let sanitizedData = try #require(defaults.data(forKey: "LiveTranslate.ProviderProfiles"))
        let sanitizedProfiles = try JSONDecoder().decode([AIProviderProfile].self, from: sanitizedData)

        #expect(sanitizedProfiles.count == 1)
        #expect(sanitizedProfiles[0].apiKey.isEmpty)
        #expect(defaults.string(forKey: "LiveTranslate.OpenAIAPIKey") == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func clearCapturedTextResetsVisibleTranslationState() {
        let appState = AppState()
        appState.updateCapturedText(
            CapturedTextSnapshot(
                appName: "Notes",
                bundleIdentifier: "com.apple.Notes",
                role: "AXTextArea",
                text: "hello"
            )
        )
        appState.translatedText = "你好"
        appState.errorMessage = "temporary"

        appState.clearCapturedText()

        #expect(appState.sourceText.isEmpty)
        #expect(appState.translatedText.isEmpty)
        #expect(appState.errorMessage == nil)
        #expect(appState.providerStatus == appState.copy.waitingForInput || appState.providerStatus == appState.copy.accessibilityPermissionRequired)
    }

    @MainActor
    @Test func accessibilityOnboardingPromptOnlyTriggersOnceWhenPermissionMissing() throws {
        let suiteName = "LiveTranslateAppTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let appState = AppState(defaults: defaults)

        let firstAttempt = appState.shouldPromptAccessibilityOnLaunch()
        let secondAttempt = appState.shouldPromptAccessibilityOnLaunch()

        if appState.isAccessibilityTrusted {
            #expect(firstAttempt == false)
            #expect(secondAttempt == false)
        } else {
            #expect(firstAttempt == true)
            #expect(secondAttempt == false)
        }

        defaults.removePersistentDomain(forName: suiteName)
    }
}
