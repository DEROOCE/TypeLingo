import AppKit
import UniformTypeIdentifiers

extension AppState {
    func exportSettings(includeSecrets: Bool = false) {
        let panel = NSSavePanel()
        panel.title = interfaceLanguage == .simplifiedChinese ? "导出 TypeLingo 设置" : "Export TypeLingo Settings"
        panel.message = includeSecrets
            ? (interfaceLanguage == .simplifiedChinese ? "将当前所有设置（包含 API key）保存为 JSON 文件。" : "Save all current settings, including API keys, to a JSON file.")
            : (interfaceLanguage == .simplifiedChinese ? "将当前设置保存为不包含 API key 的 JSON 文件。" : "Save current settings to a JSON file without API keys.")
        panel.nameFieldStringValue = includeSecrets
            ? "typelingo-settings-with-secrets.json"
            : "typelingo-settings.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            settingsTransferStatus = copy.exportCancelled
            return
        }

        let payload = SettingsTransferBundle(
            schemaVersion: 1,
            exportedAt: Date(),
            selectedProvider: selectedProvider.rawValue,
            selectedProviderProfileID: selectedProviderProfileID,
            selectedPromptProfileID: selectedPromptProfileID,
            targetLanguage: targetLanguage.rawValue,
            overlayOpacity: overlayOpacity,
            subtitleFontSize: subtitleFontSize,
            wakeShortcut: wakeShortcut,
            providerProfiles: providerProfiles.map { $0.sanitizedForExport(includeSecrets: includeSecrets) },
            promptProfiles: promptProfiles
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            try data.write(to: url, options: .atomic)
            settingsTransferStatus = copy.exportedSettings(fileName: url.lastPathComponent, includesSecrets: includeSecrets)
        } catch {
            settingsTransferStatus = copy.exportFailed(detail: error.localizedDescription)
        }
    }

    func importSettings() {
        let panel = NSOpenPanel()
        panel.title = interfaceLanguage == .simplifiedChinese ? "导入 TypeLingo 设置" : "Import TypeLingo Settings"
        panel.message = interfaceLanguage == .simplifiedChinese ? "从 JSON 文件导入 provider、prompt、浮窗和快捷键设置。" : "Import provider, prompt, overlay, and shortcut settings from a JSON file."
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else {
            settingsTransferStatus = copy.importCancelled
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(SettingsTransferBundle.self, from: data)
            applyImportedSettings(payload)
            settingsTransferStatus = copy.importedSettings(fileName: url.lastPathComponent)
        } catch {
            settingsTransferStatus = copy.importFailed(detail: error.localizedDescription)
        }
    }

    func applyImportedWakeShortcut(_ shortcut: WakeShortcut) {
        wakeShortcut = shortcut.hasAnyModifier ? shortcut : .defaultValue
    }

    fileprivate func applyImportedSettings(_ payload: SettingsTransferBundle) {
        let importedProvidersResult = payload.providerProfiles.isEmpty
            ? Self.loadProviderProfiles(from: defaults, keychainClient: keychainClient, copy: copy)
            : LoadedProviderProfiles.plain(payload.providerProfiles)
        let importedProviders = importedProvidersResult.profiles
        let importedPrompts = payload.promptProfiles.isEmpty ? Self.defaultPromptProfiles() : payload.promptProfiles
        let removedProfiles = providerProfiles.filter { current in
            !importedProviders.contains(where: { $0.id == current.id })
        }
        clearProviderConfigurationWarning()
        if let warningMessage = importedProvidersResult.warningMessage {
            appendProviderConfigurationWarning(warningMessage)
        }
        for removedProfile in removedProfiles {
            do {
                try keychainClient.deleteAPIKey(removedProfile.id)
            } catch {
                appendProviderConfigurationWarning(providerConfigurationDeleteWarningMessage(for: removedProfile.name, error: error))
            }
        }

        providerProfiles = importedProviders
        promptProfiles = importedPrompts
        selectedProviderProfileID = Self.resolveProviderProfileID(payload.selectedProviderProfileID, profiles: importedProviders)
        selectedPromptProfileID = Self.resolvePromptProfileID(payload.selectedPromptProfileID, profiles: importedPrompts)
        selectedProvider = TranslationProviderKind(rawValue: payload.selectedProvider) ?? .googleWeb
        targetLanguage = TargetLanguage(rawValue: payload.targetLanguage) ?? .english
        overlayOpacity = min(max(payload.overlayOpacity, 0.22), 0.96)
        subtitleFontSize = min(max(payload.subtitleFontSize, 22), 52)
        applyImportedWakeShortcut(payload.wakeShortcut)
        errorMessage = nil
    }
}
