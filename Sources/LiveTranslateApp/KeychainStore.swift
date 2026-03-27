import Foundation
import Security

enum KeychainStoreError: LocalizedError, Equatable {
    case invalidStoredData(service: String, profileID: String)
    case unexpectedStatus(operation: String, status: OSStatus)

    var errorDescription: String? {
        switch self {
        case let .invalidStoredData(service, profileID):
            return "Invalid API key data in Keychain for \(profileID) (service: \(service))."
        case let .unexpectedStatus(operation, status):
            let systemMessage = SecCopyErrorMessageString(status, nil) as String?
            return systemMessage.map { "\(operation) failed: \($0)" } ?? "\(operation) failed with OSStatus \(status)."
        }
    }
}

struct KeychainClient: Sendable {
    var saveAPIKey: @Sendable (_ value: String, _ profileID: String) throws -> Void
    var loadAPIKey: @Sendable (_ profileID: String) throws -> String?
    var deleteAPIKey: @Sendable (_ profileID: String) throws -> Void

    static let live = KeychainClient(
        saveAPIKey: { value, profileID in
            try KeychainStore.saveAPIKey(value, profileID: profileID)
        },
        loadAPIKey: { profileID in
            try KeychainStore.loadAPIKey(profileID: profileID)
        },
        deleteAPIKey: { profileID in
            try KeychainStore.deleteAPIKey(profileID: profileID)
        }
    )
}

enum KeychainStore {
    private static let service = "io.github.derooce.typelingo.provider-api-key"
    private static let legacyServices = [
        "com.codex.live-translate.provider-api-key"
    ]

    static func saveAPIKey(_ value: String, profileID: String) throws {
        let account = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else {
            return
        }

        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var createQuery = query
            createQuery[kSecValueData as String] = data
            let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
            guard createStatus == errSecSuccess else {
                throw KeychainStoreError.unexpectedStatus(operation: "Keychain save", status: createStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw KeychainStoreError.unexpectedStatus(operation: "Keychain save", status: status)
        }
    }

    static func loadAPIKey(profileID: String) throws -> String? {
        let account = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else {
            return nil
        }

        switch readAPIKey(service: service, account: account) {
        case let .success(value):
            return value
        case .notFound:
            break
        case let .failure(error):
            throw error
        }

        for legacyService in legacyServices {
            switch readAPIKey(service: legacyService, account: account) {
            case let .success(value):
                try? saveAPIKey(value, profileID: profileID)
                return value
            case .notFound:
                continue
            case let .failure(error):
                throw error
            }
        }

        return nil
    }

    static func deleteAPIKey(profileID: String) throws {
        let account = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(operation: "Keychain delete", status: status)
        }
    }

    private enum LookupResult {
        case success(String)
        case notFound
        case failure(KeychainStoreError)
    }

    private static func readAPIKey(service: String, account: String) -> LookupResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return .notFound
        }

        guard status == errSecSuccess else {
            return .failure(.unexpectedStatus(operation: "Keychain load", status: status))
        }

        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return .failure(.invalidStoredData(service: service, profileID: account))
        }

        return .success(value)
    }
}
