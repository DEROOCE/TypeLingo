import Foundation

struct TranslationService {
    let provider: TranslationProviderKind
    let configuration: TranslationConfiguration
    let session: URLSession
    let requestTimeout: TimeInterval?

    init(
        provider: TranslationProviderKind,
        configuration: TranslationConfiguration,
        session: URLSession = .shared,
        requestTimeout: TimeInterval? = nil
    ) {
        self.provider = provider
        self.configuration = configuration
        self.session = session
        self.requestTimeout = requestTimeout
    }

    private func applyTimeout(to request: inout URLRequest) {
        if let requestTimeout {
            request.timeoutInterval = requestTimeout
        }
    }

    func translate(
        text: String,
        targetLanguage: TargetLanguage
    ) async throws -> TranslationResult {
        switch provider {
        case .googleWeb:
            return try await translateWithGoogleWeb(
                text: text,
                targetLanguage: targetLanguage
            )
        case .openAICompatible:
            return try await translateWithOpenAICompatible(
                text: text,
                targetLanguage: targetLanguage
            )
        }
    }

    private func translateWithGoogleWeb(
        text: String,
        targetLanguage: TargetLanguage
    ) async throws -> TranslationResult {
        let started = ContinuousClock.now

        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: "auto"),
            URLQueryItem(name: "tl", value: targetLanguage.rawValue),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]

        guard let url = components?.url else {
            throw TranslationError.invalidRequest("Unable to build Google Translate URL")
        }

        var request = URLRequest(url: url)
        applyTimeout(to: &request)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)

        guard let object = try JSONSerialization.jsonObject(with: data) as? [Any],
              let chunks = object.first as? [Any] else {
            throw TranslationError.invalidResponse("Unexpected Google Translate response")
        }

        let translated = chunks.compactMap { chunk -> String? in
            guard let values = chunk as? [Any], let text = values.first as? String else {
                return nil
            }
            return text
        }.joined()
        let latency = started.duration(to: .now)

        return TranslationResult(
            translatedText: translated.isEmpty ? text : translated,
            latencyMs: milliseconds(from: latency)
        )
    }

    private func translateWithOpenAICompatible(
        text: String,
        targetLanguage: TargetLanguage
    ) async throws -> TranslationResult {
        guard let profile = configuration.openAIProfile else {
            throw TranslationError.invalidRequest("No LLM API profile selected")
        }

        let apiKey = profile.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw TranslationError.invalidRequest("OpenAI-compatible API key is not set")
        }

        let started = ContinuousClock.now
        let baseURL = profile.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = profile.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw TranslationError.invalidRequest("Invalid OpenAI-compatible base URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyTimeout(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let promptTemplate = configuration.promptProfile?.prompt.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedPrompt = (promptTemplate.isEmpty
            ? defaultOpenAISystemPrompt
            : promptTemplate
        ).replacingOccurrences(of: "{{target_language}}", with: targetLanguage.displayName)

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: resolvedPrompt),
                .init(role: "user", content: text)
            ],
            temperature: 0.2
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw TranslationError.invalidResponse("Model returned no content")
        }

        let latency = started.duration(to: .now)

        return TranslationResult(
            translatedText: content.trimmingCharacters(in: .whitespacesAndNewlines),
            latencyMs: milliseconds(from: latency)
        )
    }

    private func milliseconds(from duration: Duration) -> Int {
        let components = duration.components
        let seconds = components.seconds * 1000
        let millisecondsFromAttoseconds = Int(components.attoseconds / 1_000_000_000_000_000)
        return Int(seconds) + millisecondsFromAttoseconds
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse("Missing HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TranslationError.server("HTTP \(httpResponse.statusCode)")
        }
    }
}

struct TranslationConfiguration {
    let openAIProfile: AIProviderProfile?
    let promptProfile: PromptProfile?
}

struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

enum TranslationError: LocalizedError {
    case invalidRequest(String)
    case invalidResponse(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case let .invalidRequest(message):
            return message
        case let .invalidResponse(message):
            return message
        case let .server(message):
            return message
        }
    }
}
