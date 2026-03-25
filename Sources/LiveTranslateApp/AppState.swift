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

struct CapturedTextSnapshot: Equatable {
    let appName: String
    let bundleIdentifier: String?
    let role: String
    let text: String
}

struct TranslationResult {
    let translatedText: String
    let latencyMs: Int
}

struct AIProviderProfile: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var apiKey: String
    var baseURL: String
    var model: String

    func sanitizedForStorage() -> AIProviderProfile {
        var copy = self
        copy.apiKey = ""
        return copy
    }

    func sanitizedForExport(includeSecrets: Bool) -> AIProviderProfile {
        includeSecrets ? self : sanitizedForStorage()
    }
}

struct PromptProfile: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var prompt: String
}

struct SettingsTransferBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let selectedProvider: String
    let selectedProviderProfileID: String
    let selectedPromptProfileID: String
    let targetLanguage: String
    let overlayOpacity: Double
    let subtitleFontSize: Double
    let wakeShortcut: WakeShortcut
    let providerProfiles: [AIProviderProfile]
    let promptProfiles: [PromptProfile]
}

enum TranslationProviderKind: String, CaseIterable, Identifiable {
    case googleWeb
    case openAICompatible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleWeb:
            return "Google Web"
        case .openAICompatible:
            return "OpenAI-Compatible"
        }
    }
}

enum TargetLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-CN"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .spanish:
            return "Español"
        }
    }

    var emptyTranslationPlaceholder: String {
        switch self {
        case .english:
            return "Translation will appear here."
        case .simplifiedChinese:
            return "翻译结果会显示在这里。"
        case .japanese:
            return "翻訳結果がここに表示されます。"
        case .korean:
            return "번역 결과가 여기에 표시됩니다."
        case .spanish:
            return "La traduccion aparecera aqui."
        }
    }
}

enum InterfaceLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case simplifiedChinese = "zh-CN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

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
    var quickControlsSubtitle: String { language == .simplifiedChinese ? "高频使用的浮窗和快捷键设置。" : "High-frequency controls for the overlay and wake shortcut." }
    var interfaceLanguage: String { language == .simplifiedChinese ? "界面语言" : "Interface Language" }
    var interfaceLanguageDetail: String { language == .simplifiedChinese ? "切换设置面板和浮窗关键文案的显示语言。" : "Switch the settings panel and overlay UI language." }
    var targetLanguage: String { language == .simplifiedChinese ? "目标语言" : "Target Language" }
    var targetLanguageDetail: String { language == .simplifiedChinese ? "所有捕获到的文本都会翻译成这个语言。" : "All captured text will be translated into this language." }
    var overlay: String { language == .simplifiedChinese ? "字幕浮窗" : "Overlay" }
    var overlayDetail: String { language == .simplifiedChinese ? "如果浮窗被关闭，可以手动重新显示。" : "Show the subtitle overlay manually if it was closed." }
    var showOverlay: String { language == .simplifiedChinese ? "显示浮窗" : "Show Overlay" }
    var wakeShortcutHint: String { language == .simplifiedChinese ? "也可以使用唤醒快捷键。" : "You can also use the wake shortcut." }
    var wakeShortcut: String { language == .simplifiedChinese ? "唤醒快捷键" : "Wake Shortcut" }
    var wakeShortcutDetail: String { language == .simplifiedChinese ? "按一次显示浮窗，再按一次隐藏浮窗。" : "Press once to show the subtitle overlay, press again to hide it." }
    var currentShortcutPrefix: String { language == .simplifiedChinese ? "当前快捷键：" : "Current shortcut:" }
    var backgroundOpacity: String { language == .simplifiedChinese ? "背景透明度" : "Background Opacity" }
    var subtitleSize: String { language == .simplifiedChinese ? "字幕字号" : "Subtitle Size" }
    var accessibilityPermissionTitle: String { language == .simplifiedChinese ? "辅助功能权限" : "Accessibility Permission" }
    var accessibilityPermissionSubtitle: String { language == .simplifiedChinese ? "读取其他应用中当前聚焦输入控件所必需的权限。" : "Required for reading the focused input control from other apps." }
    var accessibilityEnabled: String { language == .simplifiedChinese ? "辅助功能访问已开启" : "Accessibility access enabled" }
    var accessibilityRequired: String { language == .simplifiedChinese ? "需要开启辅助功能访问" : "Accessibility access required" }
    var accessibilityExplainer: String { language == .simplifiedChinese ? "没有辅助功能权限，应用无法读取其他应用里的输入变化，浮窗会保持空闲状态。" : "Without Accessibility permission, the app cannot see text changes in other applications, so the overlay will stay idle." }
    var requestPermission: String { language == .simplifiedChinese ? "请求权限" : "Request Permission" }
    var openSettings: String { language == .simplifiedChinese ? "打开设置" : "Open Settings" }
    var settingsBackupTitle: String { language == .simplifiedChinese ? "设置备份" : "Settings Backup" }
    var settingsBackupSubtitle: String { language == .simplifiedChinese ? "导出当前配置到 JSON 文件，或在另一台机器上导入。" : "Export your current setup to a JSON file, or import it on another machine." }
    var exportSettings: String { language == .simplifiedChinese ? "导出设置" : "Export Settings" }
    var exportWithAPIKeys: String { language == .simplifiedChinese ? "导出并包含 API Key" : "Export With API Keys" }
    var importSettings: String { language == .simplifiedChinese ? "导入设置" : "Import Settings" }
    var exportSettingsDetail: String { language == .simplifiedChinese ? "默认导出不包含 API key。只有在你信任目标设备时，才使用“导出并包含 API Key”。" : "Default export excludes API keys. Use `Export With API Keys` only when you trust the destination machine." }
    var translationProviderTitle: String { language == .simplifiedChinese ? "翻译 Provider" : "Translation Provider" }
    var translationProviderSubtitle: String { language == .simplifiedChinese ? "在 Google Web 和 OpenAI-compatible profile 之间切换。" : "Switch between Google Web and your OpenAI-compatible profiles." }
    var activeProvider: String { language == .simplifiedChinese ? "当前 Provider" : "Active Provider" }
    var testing: String { language == .simplifiedChinese ? "测试中..." : "Testing..." }
    var testCurrentProvider: String { language == .simplifiedChinese ? "测试当前 Provider" : "Test Current Provider" }
    var apiProfilesTitle: String { language == .simplifiedChinese ? "API Profiles" : "API Profiles" }
    var apiProfilesSubtitle: String { language == .simplifiedChinese ? "这些 profile 仅在使用 OpenAI-compatible provider 时生效。" : "These profiles are used only when the provider is OpenAI-Compatible." }
    var activeAPIProfile: String { language == .simplifiedChinese ? "当前 API Profile" : "Active API Profile" }
    var activeAPIProfileDetail: String { language == .simplifiedChinese ? "选择当前生效的 LLM 接口配置。" : "Choose which LLM endpoint is currently active." }
    var addAPIProfile: String { language == .simplifiedChinese ? "新增 API Profile" : "Add API Profile" }
    var duplicate: String { language == .simplifiedChinese ? "复制" : "Duplicate" }
    var remove: String { language == .simplifiedChinese ? "删除" : "Remove" }
    var selectedAPIProfile: String { language == .simplifiedChinese ? "当前 API Profile 配置" : "Selected API Profile" }
    var profileName: String { language == .simplifiedChinese ? "Profile 名称" : "Profile Name" }
    var apiKey: String { language == .simplifiedChinese ? "API Key" : "API Key" }
    var baseURL: String { language == .simplifiedChinese ? "Base URL" : "Base URL" }
    var model: String { language == .simplifiedChinese ? "模型" : "Model" }
    var testSelectedAPIProfile: String { language == .simplifiedChinese ? "测试当前 API Profile" : "Test Selected API Profile" }
    var promptProfilesTitle: String { language == .simplifiedChinese ? "Prompt Profiles" : "Prompt Profiles" }
    var promptProfilesSubtitle: String { language == .simplifiedChinese ? "为不同字幕翻译场景保留独立的 system prompt。" : "Keep separate system prompts for different subtitle translation scenarios." }
    var activePrompt: String { language == .simplifiedChinese ? "当前 Prompt" : "Active Prompt" }
    var activePromptDetail: String { language == .simplifiedChinese ? "所选 profile 会用于 OpenAI-compatible 翻译。" : "The selected profile will be used for OpenAI-compatible translation." }
    var addPromptProfile: String { language == .simplifiedChinese ? "新增 Prompt Profile" : "Add Prompt Profile" }
    var resetToPreset: String { language == .simplifiedChinese ? "恢复预设" : "Reset to Preset" }
    var promptProfileName: String { language == .simplifiedChinese ? "Prompt Profile 名称" : "Prompt Profile Name" }
    var promptPlaceholderHelp: String { language == .simplifiedChinese ? "可使用 `{{target_language}}` 作为目标语言占位符。保留多个 prompt profile，便于在会议、直播和通用翻译场景间切换。" : "Use `{{target_language}}` as a placeholder for the selected target language. Keeping multiple prompt profiles makes it easier to switch between meeting, streaming, and general translation styles." }
    var liveStateTitle: String { language == .simplifiedChinese ? "实时状态" : "Live State" }
    var liveStateSubtitle: String { language == .simplifiedChinese ? "查看应用当前读取和翻译到的内容。" : "See what the app is currently reading and translating." }
    var focusedApp: String { language == .simplifiedChinese ? "当前应用" : "Focused App" }
    var focusedRole: String { language == .simplifiedChinese ? "当前角色" : "Focused Role" }
    var activePromptCard: String { language == .simplifiedChinese ? "当前 Prompt" : "Active Prompt" }
    var status: String { language == .simplifiedChinese ? "状态" : "Status" }
    var capturedText: String { language == .simplifiedChinese ? "捕获文本" : "Captured Text" }
    var translatedText: String { language == .simplifiedChinese ? "翻译结果" : "Translated Text" }
    var noCapturedText: String { language == .simplifiedChinese ? "还没有捕获到实时文本。" : "No live text captured yet." }
    var noTranslationYet: String { language == .simplifiedChinese ? "还没有翻译结果。" : "No translation yet." }
    var prototypeNotesTitle: String { language == .simplifiedChinese ? "原型说明" : "Prototype Notes" }
    var prototypeNotesSubtitle: String { language == .simplifiedChinese ? "当前 Accessibility 方案已知的限制。" : "Known limitations of the current Accessibility-based approach." }
    var noteIME: String { language == .simplifiedChinese ? "Accessibility 无法稳定提供中文 IME 的组合态文本。通常只能拿到已上屏文本，而不是候选中的中间态字符串。" : "Chinese IME composition text is not guaranteed through Accessibility. You usually get committed text, not the in-progress candidate string." }
    var noteSecure: String { language == .simplifiedChinese ? "密码框和安全输入框会被有意忽略。" : "Password and secure fields are intentionally ignored." }
    var noteNearCaret: String { language == .simplifiedChinese ? "大型编辑器只会截取光标附近的文本，避免每次按键都整篇重译导致浮窗抖动。" : "Large editors are truncated to the text near the caret so the overlay stays stable instead of retranslating an entire document on every keystroke." }
    var noteIMEPath: String { language == .simplifiedChinese ? "长期方案是基于 InputMethodKit 的真正输入法扩展。" : "The long-term upgrade path is a true IME extension built with InputMethodKit." }
    var waitingForInput: String { language == .simplifiedChinese ? "等待输入" : "Waiting for input" }
    var accessibilityPermissionRequired: String { language == .simplifiedChinese ? "需要辅助功能权限" : "Accessibility permission required" }
    var accessibilityEnabledStatus: String { language == .simplifiedChinese ? "辅助功能已开启" : "Accessibility enabled" }
    var grantAccessibilityInSettings: String { language == .simplifiedChinese ? "请在系统设置中开启辅助功能权限" : "Grant Accessibility permission in System Settings" }
    var grantPermissionOverlay: String { language == .simplifiedChinese ? "授予权限" : "Grant Permission" }
}

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
    private enum DefaultsDomain {
        static let primary = "io.github.derooce.typelingo"
        static let legacyBundle = "com.codex.live-translate"
        static let legacyCLI = "live-translate"
    }

    private enum DefaultsKey {
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

        // Legacy single-config keys for migration.
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
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private var translationTask: Task<Void, Never>?
    private var revision = 0

    init(defaults: UserDefaults = AppState.makeDefaults()) {
        self.defaults = defaults
        Self.migrateLegacyDefaultsIfNeeded(into: defaults)

        let loadedProviderProfiles = Self.loadProviderProfiles(from: defaults)
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

        self.providerTestStatus = (InterfaceLanguage(rawValue: savedInterfaceLanguage) ?? .english) == .simplifiedChinese ? "尚未测试" : "Not tested"
        self.isTestingProvider = false
        self.settingsTransferStatus = (InterfaceLanguage(rawValue: savedInterfaceLanguage) ?? .english) == .simplifiedChinese ? "还没有导入或导出记录" : "No import or export yet"
        self.errorMessage = nil
        self.providerStatus = isAccessibilityTrusted ? copy.waitingForInput : copy.accessibilityPermissionRequired

        saveProviderProfiles()
        savePromptProfiles()
        defaults.set(selectedProviderProfileID, forKey: DefaultsKey.selectedProviderProfileID)
        defaults.set(selectedPromptProfileID, forKey: DefaultsKey.selectedPromptProfileID)
        Self.cleanupLegacyDefaults(in: defaults)
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
            return currentProviderProfile?.name ?? "LLM API"
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
        lastObservedApp = snapshot.appName
        lastObservedRole = snapshot.role
        errorMessage = nil

        guard snapshot.text != sourceText else {
            return
        }

        sourceText = snapshot.text
        scheduleTranslation()
    }

    func clearCapturedText() {
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

    func setWakeShortcutModifier(_ modifier: ShortcutModifier, enabled: Bool) {
        wakeShortcut = wakeShortcut.updating(modifier: modifier, enabled: enabled)
    }

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
            settingsTransferStatus = interfaceLanguage == .simplifiedChinese ? "已取消导出" : "Export cancelled"
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
            settingsTransferStatus = includeSecrets
                ? (interfaceLanguage == .simplifiedChinese ? "已导出包含 API key 的设置到 \(url.lastPathComponent)" : "Exported settings with API keys to \(url.lastPathComponent)")
                : (interfaceLanguage == .simplifiedChinese ? "已导出设置到 \(url.lastPathComponent)" : "Exported settings to \(url.lastPathComponent)")
        } catch {
            settingsTransferStatus = interfaceLanguage == .simplifiedChinese ? "导出失败：\(error.localizedDescription)" : "Export failed: \(error.localizedDescription)"
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
            settingsTransferStatus = interfaceLanguage == .simplifiedChinese ? "已取消导入" : "Import cancelled"
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(SettingsTransferBundle.self, from: data)
            applyImportedSettings(payload)
            settingsTransferStatus = interfaceLanguage == .simplifiedChinese ? "已从 \(url.lastPathComponent) 导入设置" : "Imported settings from \(url.lastPathComponent)"
        } catch {
            settingsTransferStatus = interfaceLanguage == .simplifiedChinese ? "导入失败：\(error.localizedDescription)" : "Import failed: \(error.localizedDescription)"
        }
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
            name: "LLM API \(index)",
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
        duplicate.name = "\(profile.name) Copy"
        providerProfiles.append(duplicate)
        selectedProviderProfileID = duplicate.id
        selectedProvider = .openAICompatible
    }

    func removeSelectedProviderProfile() {
        guard providerProfiles.count > 1,
              let index = providerProfiles.firstIndex(where: { $0.id == selectedProviderProfileID }) else {
            return
        }

        let removedProfileID = providerProfiles[index].id
        providerProfiles.remove(at: index)
        KeychainStore.deleteAPIKey(profileID: removedProfileID)
        selectedProviderProfileID = providerProfiles[min(index, providerProfiles.count - 1)].id
        if selectedProvider == .openAICompatible {
            scheduleTranslation()
        }
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
            name: "Prompt \(promptProfiles.count + 1)",
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
        duplicate.name = "\(profile.name) Copy"
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
        guard !isTestingProvider else {
            return
        }

        isTestingProvider = true
        providerTestStatus = copy.testing

        let config = TranslationConfiguration(
            openAIProfile: providerProfiles.first(where: { $0.id == providerProfileID }),
            promptProfile: promptProfiles.first(where: { $0.id == promptProfileID })
        )

        Task {
            do {
                let service = TranslationService(provider: provider, configuration: config)
                let result = try await service.translate(text: "你好，世界", targetLanguage: .english)

                await MainActor.run {
                    self.isTestingProvider = false
                    self.providerTestStatus = result.translatedText.isEmpty
                        ? "\(provider == .googleWeb ? "Google Web" : self.currentProviderDisplayName) failed: empty response"
                        : "\(provider == .googleWeb ? "Google Web" : self.currentProviderDisplayName) OK · \(result.latencyMs)ms · \(result.translatedText)"
                }
            } catch {
                await MainActor.run {
                    self.isTestingProvider = false
                    self.providerTestStatus = "\(provider == .googleWeb ? "Google Web" : self.currentProviderDisplayName) failed · \(error.localizedDescription)"
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

        providerStatus = "Translating via \(currentProviderDisplayName)..."
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
                    self.providerStatus = "\(self.currentProviderDisplayName) \(result.latencyMs)ms"
                    self.errorMessage = nil
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard currentRevision == self.revision else {
                        return
                    }

                    self.providerStatus = "Translation failed"
                    self.errorMessage = error.localizedDescription
                    self.translatedText = ""
                }
            }
        }
    }

    private func saveProviderProfiles() {
        for profile in providerProfiles {
            let apiKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if apiKey.isEmpty {
                KeychainStore.deleteAPIKey(profileID: profile.id)
            } else {
                KeychainStore.saveAPIKey(apiKey, profileID: profile.id)
            }
        }

        let sanitizedProfiles = providerProfiles.map { $0.sanitizedForStorage() }
        if let data = try? JSONEncoder().encode(sanitizedProfiles) {
            defaults.set(data, forKey: DefaultsKey.providerProfiles)
        }
        Self.cleanupLegacyDefaults(in: defaults)
    }

    private func saveWakeShortcut() {
        if let data = try? JSONEncoder().encode(wakeShortcut) {
            defaults.set(data, forKey: DefaultsKey.wakeShortcut)
        }
    }

    private func savePromptProfiles() {
        if let data = try? JSONEncoder().encode(promptProfiles) {
            defaults.set(data, forKey: DefaultsKey.promptProfiles)
        }
    }

    private static func loadProviderProfiles(from defaults: UserDefaults) -> [AIProviderProfile] {
        if let data = defaults.data(forKey: DefaultsKey.providerProfiles),
           let profiles = try? JSONDecoder().decode([AIProviderProfile].self, from: data),
           !profiles.isEmpty {
            return profiles.map { profile in
                var hydrated = profile.sanitizedForStorage()
                let existingKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                if !existingKey.isEmpty {
                    KeychainStore.saveAPIKey(existingKey, profileID: profile.id)
                }
                hydrated.apiKey = KeychainStore.loadAPIKey(profileID: profile.id)
                return hydrated
            }
        }

        let legacyKey = defaults.string(forKey: DefaultsKey.legacyOpenAIAPIKey) ?? ""
        let legacyBase = defaults.string(forKey: DefaultsKey.legacyOpenAIBaseURL) ?? "https://api.openai.com/v1"
        let legacyModel = defaults.string(forKey: DefaultsKey.legacyOpenAIModel) ?? "gpt-4.1-mini"
        let profile = AIProviderProfile(
            id: UUID().uuidString,
            name: "Default LLM API",
            apiKey: legacyKey,
            baseURL: legacyBase,
            model: legacyModel
        )
        if !legacyKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            KeychainStore.saveAPIKey(legacyKey, profileID: profile.id)
        }
        return [
            AIProviderProfile(
                id: profile.id,
                name: profile.name,
                apiKey: KeychainStore.loadAPIKey(profileID: profile.id),
                baseURL: profile.baseURL,
                model: profile.model
            )
        ]
    }

    private static func loadWakeShortcut(from defaults: UserDefaults) -> WakeShortcut {
        if let data = defaults.data(forKey: DefaultsKey.wakeShortcut),
           let shortcut = try? JSONDecoder().decode(WakeShortcut.self, from: data) {
            return shortcut
        }
        return .defaultValue
    }

    private static func defaultPromptProfiles() -> [PromptProfile] {
        [
            PromptProfile(id: UUID().uuidString, name: "General", prompt: defaultOpenAISystemPrompt),
            PromptProfile(id: UUID().uuidString, name: "Meeting", prompt: meetingOpenAISystemPrompt),
            PromptProfile(id: UUID().uuidString, name: "Streaming", prompt: streamingOpenAISystemPrompt)
        ]
    }

    private static func loadPromptProfiles(from defaults: UserDefaults) -> [PromptProfile] {
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
                    name: "Migrated Custom",
                    prompt: legacyPrompt
                )
            )
        }

        return profiles
    }

    private static func resolveProviderProfileID(_ savedID: String?, profiles: [AIProviderProfile]) -> String {
        if let savedID, profiles.contains(where: { $0.id == savedID }) {
            return savedID
        }
        return profiles.first?.id ?? UUID().uuidString
    }

    private static func resolvePromptProfileID(_ savedID: String?, profiles: [PromptProfile]) -> String {
        if let savedID, profiles.contains(where: { $0.id == savedID }) {
            return savedID
        }
        return profiles.first?.id ?? UUID().uuidString
    }

    private func applyImportedSettings(_ payload: SettingsTransferBundle) {
        let importedProviders = payload.providerProfiles.isEmpty ? Self.loadProviderProfiles(from: defaults) : payload.providerProfiles
        let importedPrompts = payload.promptProfiles.isEmpty ? Self.defaultPromptProfiles() : payload.promptProfiles
        let removedProfileIDs = Set(providerProfiles.map(\.id)).subtracting(importedProviders.map(\.id))
        for removedProfileID in removedProfileIDs {
            KeychainStore.deleteAPIKey(profileID: removedProfileID)
        }

        providerProfiles = importedProviders
        promptProfiles = importedPrompts
        selectedProviderProfileID = Self.resolveProviderProfileID(payload.selectedProviderProfileID, profiles: importedProviders)
        selectedPromptProfileID = Self.resolvePromptProfileID(payload.selectedPromptProfileID, profiles: importedPrompts)
        selectedProvider = TranslationProviderKind(rawValue: payload.selectedProvider) ?? .googleWeb
        targetLanguage = TargetLanguage(rawValue: payload.targetLanguage) ?? .english
        overlayOpacity = min(max(payload.overlayOpacity, 0.22), 0.96)
        subtitleFontSize = min(max(payload.subtitleFontSize, 22), 52)
        wakeShortcut = payload.wakeShortcut.hasAnyModifier ? payload.wakeShortcut : .defaultValue
        errorMessage = nil
    }

    private static func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: DefaultsDomain.primary) ?? .standard
    }

    private static func migrateLegacyDefaultsIfNeeded(into defaults: UserDefaults) {
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

    private static func cleanupLegacyDefaults(in defaults: UserDefaults) {
        sanitizeStoredProviderProfiles(in: defaults)
        clearLegacySingleProviderKeys(in: defaults)
        defaults.synchronize()

        let legacyDomains = [DefaultsDomain.legacyBundle, DefaultsDomain.legacyCLI]
        for domain in legacyDomains {
            guard let legacyDefaults = UserDefaults(suiteName: domain),
                  legacyDefaults != defaults else {
                continue
            }

            sanitizeStoredProviderProfiles(in: legacyDefaults)
            clearLegacySingleProviderKeys(in: legacyDefaults)
            legacyDefaults.synchronize()
        }
    }

    private static func sanitizeStoredProviderProfiles(in defaults: UserDefaults) {
        guard let data = defaults.data(forKey: DefaultsKey.providerProfiles),
              let profiles = try? JSONDecoder().decode([AIProviderProfile].self, from: data),
              !profiles.isEmpty else {
            return
        }

        let sanitizedProfiles = profiles.map { profile in
            let apiKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !apiKey.isEmpty {
                KeychainStore.saveAPIKey(apiKey, profileID: profile.id)
            }
            return profile.sanitizedForStorage()
        }

        guard let sanitizedData = try? JSONEncoder().encode(sanitizedProfiles),
              sanitizedData != data else {
            return
        }

        defaults.set(sanitizedData, forKey: DefaultsKey.providerProfiles)
    }

    private static func clearLegacySingleProviderKeys(in defaults: UserDefaults) {
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAIAPIKey)
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAIBaseURL)
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAIModel)
        defaults.removeObject(forKey: DefaultsKey.legacyOpenAISystemPrompt)
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
        VStack(alignment: .leading, spacing: 14) {
            Text("TypeLingo")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(copy.appTagline)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                SummaryPill(
                    title: appState.isAccessibilityTrusted ? copy.accessibilityReady : copy.accessibilityNeeded,
                    symbolName: appState.isAccessibilityTrusted ? "checkmark.shield" : "exclamationmark.triangle",
                    tint: appState.isAccessibilityTrusted ? .green : .orange
                )
                SummaryPill(
                    title: appState.currentProviderDisplayName,
                    symbolName: "network",
                    tint: .blue
                )
                SummaryPill(
                    title: appState.wakeShortcut.symbolDisplayName,
                    symbolName: "keyboard",
                    tint: .pink
                )
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
                    .disabled(appState.providerProfiles.count <= 1)
                }
                .buttonStyle(.bordered)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text(copy.selectedAPIProfile)
                        .font(.system(size: 16, weight: .semibold))

                    TextField(copy.profileName, text: providerProfileBinding(\.name))
                        .textFieldStyle(.roundedBorder)

                    SecureField(copy.apiKey, text: providerProfileBinding(\.apiKey))
                        .textFieldStyle(.roundedBorder)

                    TextField(copy.baseURL, text: providerProfileBinding(\.baseURL))
                        .textFieldStyle(.roundedBorder)

                    TextField(copy.model, text: providerProfileBinding(\.model))
                        .textFieldStyle(.roundedBorder)

                    Button(copy.testSelectedAPIProfile) {
                        appState.testSelectedLLMProfile()
                    }
                    .disabled(appState.isTestingProvider)
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var promptsContent: some View {
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
                .disabled(appState.promptProfiles.count <= 1)
                Spacer()
                Button(copy.resetToPreset) {
                    appState.resetSelectedPromptProfileToPreset()
                }
            }
            .buttonStyle(.bordered)

            TextField(copy.promptProfileName, text: promptProfileBinding(\.name))
                .textFieldStyle(.roundedBorder)

            TextEditor(text: promptProfileBinding(\.prompt))
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 280)
                .padding(10)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(copy.promptPlaceholderHelp)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
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
                    diagnosticValueCard(copy.activePromptCard, value: appState.currentPromptProfile?.name ?? "-")
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

    private func diagnosticValueCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(14)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func textPanel(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            ScrollView {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 110)
            .padding(12)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
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
                    Button(copy.testing) {
                        toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(appState.interfaceLanguage == .simplifiedChinese ? "录制快捷键" : "Record Shortcut") {
                        toggleRecording()
                    }
                    .buttonStyle(.bordered)
                }

                if isRecording {
                    Button(appState.interfaceLanguage == .simplifiedChinese ? "取消" : "Cancel") {
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
            hintText = appState.interfaceLanguage == .simplifiedChinese ? "已取消录制。" : "Recording cancelled."
            stopRecording()
            return nil
        }

        guard let shortcut = WakeShortcut.from(event: event) else {
            hintText = appState.interfaceLanguage == .simplifiedChinese ? "暂不支持这个按键，请使用字母或数字键。" : "That key is not supported yet. Use letters or numbers."
            return nil
        }

        guard shortcut.hasAnyModifier else {
            hintText = appState.interfaceLanguage == .simplifiedChinese ? "请至少加入一个修饰键，例如 Control、Command、Option 或 Shift。" : "Add at least one modifier key like Control, Command, Option, or Shift."
            return nil
        }

        appState.updateWakeShortcut(shortcut)
        hintText = appState.interfaceLanguage == .simplifiedChinese
            ? "快捷键已更新为 \(shortcut.localizedDisplayName(language: appState.interfaceLanguage))."
            : "Shortcut updated to \(shortcut.localizedDisplayName(language: appState.interfaceLanguage))."
        stopRecording()
        return nil
    }

    private var idleHint: String {
        appState.interfaceLanguage == .simplifiedChinese
            ? "点击“录制快捷键”，然后按下新的快捷键组合。"
            : "Click record, then press the new shortcut."
    }

    private var recordingHint: String {
        appState.interfaceLanguage == .simplifiedChinese
            ? "现在按下新的快捷键组合。按 Escape 可取消。"
            : "Press the new shortcut now. Press Escape to cancel."
    }
}

struct ShortcutModifierButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(configuration.isPressed ? 0.75 : 0.95) : Color.black.opacity(configuration.isPressed ? 0.10 : 0.05))
            )
    }
}
