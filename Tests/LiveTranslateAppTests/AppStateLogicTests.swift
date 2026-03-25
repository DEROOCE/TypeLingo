import Carbon
import Testing
@testable import LiveTranslateApp

struct AppStateLogicTests {
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
        #expect(appState.providerStatus == "Waiting for input" || appState.providerStatus == "Accessibility permission required")
    }
}
