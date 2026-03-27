import Foundation

extension AppState {
    func saveProviderProfiles() {
        var warnings: [String] = []

        for profile in providerProfiles {
            let apiKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                if apiKey.isEmpty {
                    try keychainClient.deleteAPIKey(profile.id)
                } else {
                    try keychainClient.saveAPIKey(apiKey, profile.id)
                }
            } catch {
                warnings.append(providerConfigurationWarningMessage(for: profile.name, error: error))
            }
        }

        let sanitizedProfiles = providerProfiles.map { $0.sanitizedForStorage() }
        if let data = try? JSONEncoder().encode(sanitizedProfiles) {
            defaults.set(data, forKey: DefaultsKey.providerProfiles)
        }
        Self.cleanupLegacyDefaults(in: defaults, keychainClient: keychainClient)
        setProviderConfigurationWarnings(warnings)
    }

    func providerConfigurationWarningMessage(for profileName: String, error: Error) -> String {
        copy.providerKeychainPersistenceFailed(profileName: profileName, detail: error.localizedDescription)
    }

    func providerConfigurationDeleteWarningMessage(for profileName: String, error: Error) -> String {
        copy.providerKeychainDeleteFailed(profileName: profileName, detail: error.localizedDescription)
    }

    func setProviderConfigurationWarnings(_ warnings: [String]) {
        providerConfigurationWarning = warnings.isEmpty ? nil : warnings.joined(separator: "\n")
    }

    func appendProviderConfigurationWarning(_ warning: String) {
        let warnings = [providerConfigurationWarning, warning]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        providerConfigurationWarning = warnings.isEmpty ? nil : warnings.joined(separator: "\n")
    }

    func clearProviderConfigurationWarning() {
        providerConfigurationWarning = nil
    }

    struct LoadedProviderProfiles {
        let profiles: [AIProviderProfile]
        let warningMessage: String?

        static func plain(_ profiles: [AIProviderProfile]) -> LoadedProviderProfiles {
            LoadedProviderProfiles(profiles: profiles, warningMessage: nil)
        }
    }

    func saveWakeShortcut() {
        if let data = try? JSONEncoder().encode(wakeShortcut) {
            defaults.set(data, forKey: DefaultsKey.wakeShortcut)
        }
    }

    func savePromptProfiles() {
        if let data = try? JSONEncoder().encode(promptProfiles) {
            defaults.set(data, forKey: DefaultsKey.promptProfiles)
        }
    }

    static func loadProviderProfiles(from defaults: UserDefaults, keychainClient: KeychainClient, copy: LocalizedCopy) -> LoadedProviderProfiles {
        var warnings: [String] = []

        if let data = defaults.data(forKey: DefaultsKey.providerProfiles),
           let profiles = try? JSONDecoder().decode([AIProviderProfile].self, from: data),
           !profiles.isEmpty {
            let hydratedProfiles = profiles.map { profile in
                var hydrated = profile.sanitizedForStorage()
                let existingKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                if !existingKey.isEmpty {
                    do {
                        try keychainClient.saveAPIKey(existingKey, profile.id)
                    } catch {
                        warnings.append(copy.providerKeychainPersistenceFailed(profileName: profile.name, detail: error.localizedDescription))
                    }
                }
                do {
                    hydrated.apiKey = try keychainClient.loadAPIKey(profile.id) ?? ""
                } catch {
                    hydrated.apiKey = ""
                    warnings.append(copy.providerKeychainLoadFailed(profileName: profile.name, detail: error.localizedDescription))
                }
                return hydrated
            }
            return LoadedProviderProfiles(
                profiles: hydratedProfiles,
                warningMessage: warnings.isEmpty ? nil : warnings.joined(separator: "\n")
            )
        }

        let legacyKey = defaults.string(forKey: DefaultsKey.legacyOpenAIAPIKey) ?? ""
        let legacyBase = defaults.string(forKey: DefaultsKey.legacyOpenAIBaseURL) ?? "https://api.openai.com/v1"
        let legacyModel = defaults.string(forKey: DefaultsKey.legacyOpenAIModel) ?? "gpt-4.1-mini"
        let profile = AIProviderProfile(
            id: UUID().uuidString,
            name: copy.defaultLLMApiProfileName,
            apiKey: legacyKey,
            baseURL: legacyBase,
            model: legacyModel
        )

        if !legacyKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try keychainClient.saveAPIKey(legacyKey, profile.id)
            } catch {
                warnings.append(copy.providerKeychainPersistenceFailed(profileName: profile.name, detail: error.localizedDescription))
            }
        }

        let loadedKey: String
        do {
            loadedKey = try keychainClient.loadAPIKey(profile.id) ?? ""
        } catch {
            loadedKey = ""
            warnings.append(copy.providerKeychainLoadFailed(profileName: profile.name, detail: error.localizedDescription))
        }

        return LoadedProviderProfiles(
            profiles: [
                AIProviderProfile(
                    id: profile.id,
                    name: profile.name,
                    apiKey: loadedKey,
                    baseURL: profile.baseURL,
                    model: profile.model
                )
            ],
            warningMessage: warnings.isEmpty ? nil : warnings.joined(separator: "\n")
        )
    }

    static func loadWakeShortcut(from defaults: UserDefaults) -> WakeShortcut {
        if let data = defaults.data(forKey: DefaultsKey.wakeShortcut),
           let shortcut = try? JSONDecoder().decode(WakeShortcut.self, from: data) {
            return shortcut
        }
        return .defaultValue
    }

    static func defaultPromptProfiles() -> [PromptProfile] {
        [
            PromptProfile(id: UUID().uuidString, name: LocalizedCopy(language: .english).generalPromptProfileName, prompt: defaultOpenAISystemPrompt),
            PromptProfile(id: UUID().uuidString, name: LocalizedCopy(language: .english).meetingPromptProfileName, prompt: meetingOpenAISystemPrompt),
            PromptProfile(id: UUID().uuidString, name: LocalizedCopy(language: .english).streamingPromptProfileName, prompt: streamingOpenAISystemPrompt)
        ]
    }

    static func loadPromptProfiles(from defaults: UserDefaults) -> [PromptProfile] {
        if let data = defaults.data(forKey: DefaultsKey.promptProfiles),
           let profiles = try? JSONDecoder().decode([PromptProfile].self, from: data),
           !profiles.isEmpty {
            return profiles
        }

        let legacyPrompt = defaults.string(forKey: DefaultsKey.legacyOpenAISystemPrompt)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var profiles = defaultPromptProfiles()

        if !legacyPrompt.isEmpty, legacyPrompt != defaultOpenAISystemPrompt {
            profiles.append(
                PromptProfile(
                    id: UUID().uuidString,
                    name: LocalizedCopy(language: .english).migratedCustomPromptName,
                    prompt: legacyPrompt
                )
            )
        }

        return profiles
    }

    static func resolveProviderProfileID(_ savedID: String?, profiles: [AIProviderProfile]) -> String {
        if let savedID, profiles.contains(where: { $0.id == savedID }) {
            return savedID
        }
        return profiles.first?.id ?? UUID().uuidString
    }

    static func resolvePromptProfileID(_ savedID: String?, profiles: [PromptProfile]) -> String {
        if let savedID, profiles.contains(where: { $0.id == savedID }) {
            return savedID
        }
        return profiles.first?.id ?? UUID().uuidString
    }

    static func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: DefaultsDomain.primary) ?? .standard
    }

    static func migrateLegacyDefaultsIfNeeded(into defaults: UserDefaults) {
        let keysToMigrate = [
            DefaultsKey.selectedProvider,
            DefaultsKey.selectedProviderProfileID,
            DefaultsKey.selectedPromptProfileID,
            DefaultsKey.targetLanguage,
            DefaultsKey.providerProfiles,
            DefaultsKey.promptProfiles,
            DefaultsKey.subtitleFontSize,
            DefaultsKey.overlayOpacity,
            DefaultsKey.wakeShortcut,
            DefaultsKey.legacyOpenAIAPIKey,
            DefaultsKey.legacyOpenAIBaseURL,
            DefaultsKey.legacyOpenAIModel,
            DefaultsKey.legacyOpenAISystemPrompt
        ]

        let legacyDomains = [DefaultsDomain.legacyBundle, DefaultsDomain.legacyCLI]
        for key in keysToMigrate where defaults.object(forKey: key) == nil {
            for domain in legacyDomains {
                guard let legacyDefaults = UserDefaults(suiteName: domain),
                      let value = legacyDefaults.object(forKey: key) else {
                    continue
                }
                defaults.set(value, forKey: key)
                break
            }
        }

        defaults.synchronize()
    }

    static func sanitizeStoredProviderProfiles(in defaults: UserDefaults, keychainClient: KeychainClient) {
        guard let data = defaults.data(forKey: DefaultsKey.providerProfiles),
              let profiles = try? JSONDecoder().decode([AIProviderProfile].self, from: data),
              !profiles.isEmpty else {
            return
        }

        let sanitizedProfiles = profiles.map { profile in
            let apiKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !apiKey.isEmpty {
                do {
                    try keychainClient.saveAPIKey(apiKey, profile.id)
                    return profile.sanitizedForStorage()
                } catch {
                    return profile
                }
            }
            return profile.sanitizedForStorage()
        }

        guard let sanitizedData = try? JSONEncoder().encode(sanitizedProfiles),
              sanitizedData != data else {
            return
        }

        defaults.set(sanitizedData, forKey: DefaultsKey.providerProfiles)
    }

    @discardableResult
    static func sanitizeLegacySingleProviderKey(in defaults: UserDefaults, keychainClient: KeychainClient) -> Bool {
        let legacyKey = defaults.string(forKey: DefaultsKey.legacyOpenAIAPIKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !legacyKey.isEmpty else {
            return true
        }

        let selectedProfileID = defaults.string(forKey: DefaultsKey.selectedProviderProfileID)
        let providerProfilesResult = loadProviderProfiles(from: defaults, keychainClient: keychainClient, copy: LocalizedCopy(language: .english))
        let profileID = resolveProviderProfileID(selectedProfileID, profiles: providerProfilesResult.profiles)
        guard !profileID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        do {
            try keychainClient.saveAPIKey(legacyKey, profileID)
            defaults.removeObject(forKey: DefaultsKey.legacyOpenAIAPIKey)
            return true
        } catch {
            return false
        }
    }

    static func cleanupLegacyDefaults(in defaults: UserDefaults, keychainClient: KeychainClient) {
        sanitizeStoredProviderProfiles(in: defaults, keychainClient: keychainClient)
        let didMigrateLegacyKey = sanitizeLegacySingleProviderKey(in: defaults, keychainClient: keychainClient)
        clearLegacySingleProviderMetadata(in: defaults)
        if didMigrateLegacyKey {
            defaults.removeObject(forKey: DefaultsKey.legacyOpenAIAPIKey)
        }
        defaults.synchronize()

        let legacyDomains = [DefaultsDomain.legacyBundle, DefaultsDomain.legacyCLI]
        for domain in legacyDomains {
            guard let legacyDefaults = UserDefaults(suiteName: domain),
                  legacyDefaults != defaults else {
                continue
            }

            sanitizeStoredProviderProfiles(in: legacyDefaults, keychainClient: keychainClient)
            let didMigrateLegacyKey = sanitizeLegacySingleProviderKey(in: legacyDefaults, keychainClient: keychainClient)
            clearLegacySingleProviderMetadata(in: legacyDefaults)
            if didMigrateLegacyKey {
                legacyDefaults.removeObject(forKey: DefaultsKey.legacyOpenAIAPIKey)
            }
            legacyDefaults.synchronize()
        }
    }

    static func clearLegacySingleProviderMetadata(in defaults: UserDefaults) {
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAIBaseURL)
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAIModel)
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAISystemPrompt)
    }
}
