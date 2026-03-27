struct LocalizedCopy {
    let language: InterfaceLanguage

    var generalTab: String { language == .simplifiedChinese ? "通用" : "General" }
    var providersTab: String { language == .simplifiedChinese ? "Provider" : "Providers" }
    var promptsTab: String { language == .simplifiedChinese ? "Prompt" : "Prompts" }
    var diagnosticsTab: String { language == .simplifiedChinese ? "诊断" : "Diagnostics" }

    var appTagline: String {
        language == .simplifiedChinese
            ? "一个面向 macOS 的实时字幕浮窗工具，监听当前聚焦输入框，边输入边翻译，适合演示、直播和双语沟通。"
            : "A live subtitle overlay for macOS that watches the focused text field, translates as you type, and stays lightweight enough for calls, streams, and demos."
    }

    var accessibilityReady: String { language == .simplifiedChinese ? "辅助功能已开启" : "Accessibility Ready" }
    var accessibilityNeeded: String { language == .simplifiedChinese ? "需要辅助功能权限" : "Accessibility Needed" }

    var quickControlsTitle: String { language == .simplifiedChinese ? "快捷控制" : "Quick Controls" }
    var quickControlsSubtitle: String {
        language == .simplifiedChinese
            ? "高频使用的浮窗和快捷键设置。"
            : "High-frequency controls for the overlay and wake shortcut."
    }

    var interfaceLanguage: String { language == .simplifiedChinese ? "界面语言" : "Interface Language" }
    var interfaceLanguageDetail: String {
        language == .simplifiedChinese
            ? "切换设置面板和浮窗关键文案的显示语言。"
            : "Switch the settings panel and overlay UI language."
    }

    var targetLanguage: String { language == .simplifiedChinese ? "目标语言" : "Target Language" }
    var targetLanguageDetail: String {
        language == .simplifiedChinese
            ? "所有捕获到的文本都会翻译成这个语言。"
            : "All captured text will be translated into this language."
    }

    var overlay: String { language == .simplifiedChinese ? "字幕浮窗" : "Overlay" }
    var overlayDetail: String {
        language == .simplifiedChinese
            ? "如果浮窗被关闭，可以手动重新显示。"
            : "Show the subtitle overlay manually if it was closed."
    }
    var showOverlay: String { language == .simplifiedChinese ? "显示浮窗" : "Show Overlay" }

    var wakeShortcutHint: String { language == .simplifiedChinese ? "也可以使用唤醒快捷键。" : "You can also use the wake shortcut." }
    var wakeShortcut: String { language == .simplifiedChinese ? "唤醒快捷键" : "Wake Shortcut" }
    var wakeShortcutDetail: String {
        language == .simplifiedChinese
            ? "按一次显示浮窗，再按一次隐藏浮窗。"
            : "Press once to show the subtitle overlay, press again to hide it."
    }
    var currentShortcutPrefix: String { language == .simplifiedChinese ? "当前快捷键：" : "Current shortcut:" }

    var backgroundOpacity: String { language == .simplifiedChinese ? "背景透明度" : "Background Opacity" }
    var subtitleSize: String { language == .simplifiedChinese ? "字幕字号" : "Subtitle Size" }

    var accessibilityPermissionTitle: String { language == .simplifiedChinese ? "辅助功能权限" : "Accessibility Permission" }
    var accessibilityPermissionSubtitle: String {
        language == .simplifiedChinese
            ? "读取其他应用中当前聚焦输入控件所必需的权限。"
            : "Required for reading the focused input control from other apps."
    }
    var accessibilityEnabled: String { language == .simplifiedChinese ? "辅助功能访问已开启" : "Accessibility access enabled" }
    var accessibilityRequired: String { language == .simplifiedChinese ? "需要开启辅助功能访问" : "Accessibility access required" }
    var accessibilityExplainer: String {
        language == .simplifiedChinese
            ? "没有辅助功能权限，应用无法读取其他应用里的输入变化，浮窗会保持空闲状态。"
            : "Without Accessibility permission, the app cannot see text changes in other applications, so the overlay will stay idle."
    }
    var requestPermission: String { language == .simplifiedChinese ? "请求权限" : "Request Permission" }
    var openSettings: String { language == .simplifiedChinese ? "打开设置" : "Open Settings" }
    var grantAccessibilityInSettings: String {
        language == .simplifiedChinese ? "请在系统设置中开启辅助功能权限" : "Grant Accessibility permission in System Settings"
    }
    var accessibilityPermissionRequired: String { language == .simplifiedChinese ? "需要辅助功能权限" : "Accessibility permission required" }
    var accessibilityEnabledStatus: String { language == .simplifiedChinese ? "辅助功能已开启" : "Accessibility enabled" }
    var grantPermissionOverlay: String { language == .simplifiedChinese ? "授予权限" : "Grant Permission" }

    var settingsBackupTitle: String { language == .simplifiedChinese ? "设置备份" : "Settings Backup" }
    var settingsBackupSubtitle: String {
        language == .simplifiedChinese
            ? "导出当前配置到 JSON 文件，或在另一台机器上导入。"
            : "Export your current setup to a JSON file, or import it on another machine."
    }
    var exportSettings: String { language == .simplifiedChinese ? "导出设置" : "Export Settings" }
    var exportWithAPIKeys: String { language == .simplifiedChinese ? "导出并包含 API Key" : "Export With API Keys" }
    var importSettings: String { language == .simplifiedChinese ? "导入设置" : "Import Settings" }
    var exportSettingsDetail: String {
        language == .simplifiedChinese
            ? "默认导出不包含 API key。只有在你信任目标设备时，才使用“导出并包含 API Key”。"
            : "Default export excludes API keys. Use `Export With API Keys` only when you trust the destination machine."
    }
    var noSettingsTransferYet: String { language == .simplifiedChinese ? "还没有导入或导出记录" : "No import or export yet" }
    var exportCancelled: String { language == .simplifiedChinese ? "已取消导出" : "Export cancelled" }
    var importCancelled: String { language == .simplifiedChinese ? "已取消导入" : "Import cancelled" }
    func exportFailed(detail: String) -> String {
        language == .simplifiedChinese ? "导出失败：\(detail)" : "Export failed: \(detail)"
    }
    func importFailed(detail: String) -> String {
        language == .simplifiedChinese ? "导入失败：\(detail)" : "Import failed: \(detail)"
    }
    func exportedSettings(fileName: String, includesSecrets: Bool) -> String {
        if language == .simplifiedChinese {
            return includesSecrets ? "已导出包含 API key 的设置到 \(fileName)" : "已导出设置到 \(fileName)"
        }
        return includesSecrets ? "Exported settings with API keys to \(fileName)" : "Exported settings to \(fileName)"
    }
    func importedSettings(fileName: String) -> String {
        language == .simplifiedChinese ? "已从 \(fileName) 导入设置" : "Imported settings from \(fileName)"
    }

    var translationProviderTitle: String { language == .simplifiedChinese ? "翻译 Provider" : "Translation Provider" }
    var translationProviderSubtitle: String {
        language == .simplifiedChinese
            ? "在 Google Web 和 OpenAI-compatible profile 之间切换。"
            : "Switch between Google Web and your OpenAI-compatible profiles."
    }
    var activeProvider: String { language == .simplifiedChinese ? "当前 Provider" : "Active Provider" }
    var testing: String { language == .simplifiedChinese ? "测试中..." : "Testing..." }
    var notTested: String { language == .simplifiedChinese ? "尚未测试" : "Not tested" }
    var googleWebProviderName: String { language == .simplifiedChinese ? "Google 网页版" : "Google Web" }
    var defaultLLMProviderName: String { language == .simplifiedChinese ? "LLM API" : "LLM API" }
    var testCurrentProvider: String { language == .simplifiedChinese ? "测试当前 Provider" : "Test Current Provider" }

    var apiProfilesTitle: String { language == .simplifiedChinese ? "API Profiles" : "API Profiles" }
    var apiProfilesSubtitle: String {
        language == .simplifiedChinese
            ? "这些 profile 仅在使用 OpenAI-compatible provider 时生效。"
            : "These profiles are used only when the provider is OpenAI-Compatible."
    }
    var activeAPIProfile: String { language == .simplifiedChinese ? "当前 API Profile" : "Active API Profile" }
    var activeAPIProfileDetail: String {
        language == .simplifiedChinese
            ? "选择当前生效的 LLM 接口配置。"
            : "Choose which LLM endpoint is currently active."
    }
    var addAPIProfile: String { language == .simplifiedChinese ? "新增 API Profile" : "Add API Profile" }
    var duplicate: String { language == .simplifiedChinese ? "复制" : "Duplicate" }
    var remove: String { language == .simplifiedChinese ? "删除" : "Remove" }
    var selectedAPIProfile: String { language == .simplifiedChinese ? "当前 API Profile 配置" : "Selected API Profile" }
    var profileName: String { language == .simplifiedChinese ? "Profile 名称" : "Profile Name" }
    var apiKey: String { language == .simplifiedChinese ? "API Key" : "API Key" }
    var baseURL: String { language == .simplifiedChinese ? "Base URL" : "Base URL" }
    var model: String { language == .simplifiedChinese ? "模型" : "Model" }
    var testSelectedAPIProfile: String { language == .simplifiedChinese ? "测试当前 API Profile" : "Test Selected API Profile" }

    var llmApiProfilePrefix: String { language == .simplifiedChinese ? "LLM API" : "LLM API" }
    func numberedLLMApiProfile(_ index: Int) -> String { "\(llmApiProfilePrefix) \(index)" }
    var copiedSuffix: String { language == .simplifiedChinese ? "副本" : "Copy" }
    func copiedProfileName(_ name: String) -> String { "\(name) \(copiedSuffix)" }
    var defaultLLMApiProfileName: String { language == .simplifiedChinese ? "默认 LLM API" : "Default LLM API" }

    var promptProfilesTitle: String { language == .simplifiedChinese ? "Prompt Profiles" : "Prompt Profiles" }
    var promptProfilesSubtitle: String {
        language == .simplifiedChinese
            ? "为不同字幕翻译场景保留独立的 system prompt。"
            : "Keep separate system prompts for different subtitle translation scenarios."
    }
    var activePrompt: String { language == .simplifiedChinese ? "当前 Prompt" : "Active Prompt" }
    var activePromptDetail: String {
        language == .simplifiedChinese
            ? "所选 profile 会用于 OpenAI-compatible 翻译。"
            : "The selected profile will be used for OpenAI-compatible translation."
    }
    var addPromptProfile: String { language == .simplifiedChinese ? "新增 Prompt Profile" : "Add Prompt Profile" }
    var resetToPreset: String { language == .simplifiedChinese ? "恢复预设" : "Reset to Preset" }
    var promptProfileName: String { language == .simplifiedChinese ? "Prompt Profile 名称" : "Prompt Profile Name" }
    var promptPlaceholderHelp: String {
        language == .simplifiedChinese
            ? "可使用 `{{target_language}}` 作为目标语言占位符。保留多个 prompt profile，便于在会议、直播和通用翻译场景间切换。"
            : "Use `{{target_language}}` as a placeholder for the selected target language. Keeping multiple prompt profiles makes it easier to switch between meeting, streaming, and general translation styles."
    }
    func numberedPromptProfile(_ index: Int) -> String { "Prompt \(index)" }
    var generalPromptProfileName: String { "General" }
    var meetingPromptProfileName: String { "Meeting" }
    var streamingPromptProfileName: String { "Streaming" }
    var migratedCustomPromptName: String { language == .simplifiedChinese ? "迁移的自定义 Prompt" : "Migrated Custom" }

    var liveStateTitle: String { language == .simplifiedChinese ? "实时状态" : "Live State" }
    var liveStateSubtitle: String {
        language == .simplifiedChinese
            ? "查看应用当前读取和翻译到的内容。"
            : "See what the app is currently reading and translating."
    }
    var focusedApp: String { language == .simplifiedChinese ? "当前应用" : "Focused App" }
    var focusedRole: String { language == .simplifiedChinese ? "当前角色" : "Focused Role" }
    var activePromptCard: String { language == .simplifiedChinese ? "当前 Prompt" : "Active Prompt" }
    var status: String { language == .simplifiedChinese ? "状态" : "Status" }
    var capturedText: String { language == .simplifiedChinese ? "捕获文本" : "Captured Text" }
    var translatedText: String { language == .simplifiedChinese ? "翻译结果" : "Translated Text" }
    var noCapturedText: String { language == .simplifiedChinese ? "还没有捕获到实时文本。" : "No live text captured yet." }
    var noTranslationYet: String { language == .simplifiedChinese ? "还没有翻译结果。" : "No translation yet." }
    var waitingForInput: String { language == .simplifiedChinese ? "等待输入" : "Waiting for input" }
    var currentPromptDiagnosticsFallback: String { "-" }
    var recording: String { language == .simplifiedChinese ? "录制中..." : "Recording..." }

    var prototypeNotesTitle: String { language == .simplifiedChinese ? "原型说明" : "Prototype Notes" }
    var prototypeNotesSubtitle: String {
        language == .simplifiedChinese
            ? "当前 Accessibility 方案已知的限制。"
            : "Known limitations of the current Accessibility-based approach."
    }
    var noteIME: String {
        language == .simplifiedChinese
            ? "Accessibility 无法稳定提供中文 IME 的组合态文本。通常只能拿到已上屏文本，而不是候选中的中间态字符串。"
            : "Chinese IME composition text is not guaranteed through Accessibility. You usually get committed text, not the in-progress candidate string."
    }
    var noteSecure: String { language == .simplifiedChinese ? "密码框和安全输入框会被有意忽略。" : "Password and secure fields are intentionally ignored." }
    var noteNearCaret: String {
        language == .simplifiedChinese
            ? "大型编辑器只会截取光标附近的文本，避免每次按键都整篇重译导致浮窗抖动。"
            : "Large editors are truncated to the text near the caret so the overlay stays stable instead of retranslating an entire document on every keystroke."
    }
    var noteIMEPath: String {
        language == .simplifiedChinese
            ? "长期方案是基于 InputMethodKit 的真正输入法扩展。"
            : "The long-term upgrade path is a true IME extension built with InputMethodKit."
    }

    var applyingShortcutPrefix: String { language == .simplifiedChinese ? "正在应用快捷键" : "Applying shortcut" }
    var providerKeychainPersistenceFailedPrefix: String { language == .simplifiedChinese ? "API Profile 的 Keychain 持久化失败" : "Keychain persistence failed for API profile" }
    var providerKeychainLoadFailedPrefix: String { language == .simplifiedChinese ? "读取 API Profile 的 Keychain 数据失败" : "Failed to load Keychain data for API profile" }
    var providerKeychainDeleteFailedPrefix: String { language == .simplifiedChinese ? "删除 API Profile 的 Keychain 凭证失败" : "Failed to delete Keychain credentials for API profile" }
    var wakeShortcutRegistrationFailedPrefix: String { language == .simplifiedChinese ? "唤醒快捷键注册失败" : "Wake shortcut registration failed" }
    var wakeShortcutRollbackFailedSuffix: String { language == .simplifiedChinese ? "回滚也失败了" : "Rollback also failed" }
    var providerTestEmptyResponseSuffix: String { language == .simplifiedChinese ? "失败：返回为空" : "failed: empty response" }
    var providerTestSuccessSeparator: String { " · " }

    var recordShortcut: String { language == .simplifiedChinese ? "录制快捷键" : "Record Shortcut" }
    var cancel: String { language == .simplifiedChinese ? "取消" : "Cancel" }
    var recordingCancelled: String { language == .simplifiedChinese ? "已取消录制。" : "Recording cancelled." }
    var unsupportedShortcutKey: String { language == .simplifiedChinese ? "暂不支持这个按键，请使用字母或数字键。" : "That key is not supported yet. Use letters or numbers." }
    var shortcutNeedsModifier: String { language == .simplifiedChinese ? "请至少加入一个修饰键，例如 Control、Command、Option 或 Shift。" : "Add at least one modifier key like Control, Command, Option, or Shift." }
    var shortcutRecorderIdleHint: String { language == .simplifiedChinese ? "点击“录制快捷键”，然后按下新的快捷键组合。" : "Click record, then press the new shortcut." }
    var shortcutRecorderRecordingHint: String { language == .simplifiedChinese ? "现在按下新的快捷键组合。按 Escape 可取消。" : "Press the new shortcut now. Press Escape to cancel." }

    func applyingShortcut(_ shortcut: WakeShortcut) -> String {
        let name = shortcut.localizedDisplayName(language: language)
        return language == .simplifiedChinese ? "\(applyingShortcutPrefix) \(name)。" : "\(applyingShortcutPrefix) \(name)."
    }

    func providerKeychainPersistenceFailed(profileName: String, detail: String) -> String {
        language == .simplifiedChinese
            ? "\(providerKeychainPersistenceFailedPrefix)（\(profileName)）：\(detail)"
            : "\(providerKeychainPersistenceFailedPrefix) \(profileName): \(detail)"
    }

    func providerKeychainLoadFailed(profileName: String, detail: String) -> String {
        language == .simplifiedChinese
            ? "\(providerKeychainLoadFailedPrefix)（\(profileName)）：\(detail)"
            : "\(providerKeychainLoadFailedPrefix) \(profileName): \(detail)"
    }

    func providerKeychainDeleteFailed(profileName: String, detail: String) -> String {
        language == .simplifiedChinese
            ? "\(providerKeychainDeleteFailedPrefix)（\(profileName)）：\(detail)"
            : "\(providerKeychainDeleteFailedPrefix) \(profileName): \(detail)"
    }

    func wakeShortcutRegistrationFailed(detail: String) -> String {
        language == .simplifiedChinese ? "\(wakeShortcutRegistrationFailedPrefix)：\(detail)" : "\(wakeShortcutRegistrationFailedPrefix): \(detail)"
    }

    func wakeShortcutRolledBack(requested: WakeShortcut, fallback: WakeShortcut, detail: String) -> String {
        let requestedName = requested.localizedDisplayName(language: language)
        let fallbackName = fallback.localizedDisplayName(language: language)
        return language == .simplifiedChinese
            ? "\(wakeShortcutRegistrationFailed(detail: detail))，已恢复为 \(fallbackName)（未使用 \(requestedName)）。"
            : "\(wakeShortcutRegistrationFailed(detail: detail)) Reverted to \(fallbackName) instead of \(requestedName)."
    }

    func wakeShortcutRollbackFailed(detail: String, rollbackDetail: String) -> String {
        language == .simplifiedChinese
            ? "\(wakeShortcutRegistrationFailed(detail: detail))，\(wakeShortcutRollbackFailedSuffix)：\(rollbackDetail)。"
            : "\(wakeShortcutRegistrationFailed(detail: detail)). \(wakeShortcutRollbackFailedSuffix): \(rollbackDetail)."
    }

    func providerTestingSuccess(providerName: String, latencyMs: Int, result: String) -> String {
        language == .simplifiedChinese
            ? "\(providerName) 成功\(providerTestSuccessSeparator)\(latencyMs)ms\(providerTestSuccessSeparator)\(result)"
            : "\(providerName) OK\(providerTestSuccessSeparator)\(latencyMs)ms\(providerTestSuccessSeparator)\(result)"
    }

    func providerTestingEmptyResponse(providerName: String) -> String {
        "\(providerName) \(providerTestEmptyResponseSuffix)"
    }

    func providerTestingFailure(providerName: String, detail: String) -> String {
        language == .simplifiedChinese
            ? "\(providerName) 失败\(providerTestSuccessSeparator)\(detail)"
            : "\(providerName) failed\(providerTestSuccessSeparator)\(detail)"
    }

    func translatingVia(providerName: String) -> String {
        language == .simplifiedChinese ? "正在通过 \(providerName) 翻译..." : "Translating via \(providerName)..."
    }

    func translationStatus(providerName: String, latencyMs: Int) -> String {
        "\(providerName) \(latencyMs)ms"
    }

    var translationFailed: String { language == .simplifiedChinese ? "翻译失败" : "Translation failed" }
}
