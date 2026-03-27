import Foundation

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
            return "La traducción aparecerá aquí."
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
