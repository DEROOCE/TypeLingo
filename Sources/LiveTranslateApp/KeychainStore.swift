import Foundation
import Security

enum KeychainStore {
    private static let service = "io.github.derooce.typelingo.provider-api-key"
    private static let legacyServices = [
        "com.codex.live-translate.provider-api-key"
    ]

    static func saveAPIKey(_ value: String, profileID: String) {
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
            SecItemAdd(createQuery as CFDictionary, nil)
        }
    }

    static func loadAPIKey(profileID: String) -> String {
        let account = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else {
            return ""
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess,
           let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        for legacyService in legacyServices {
            let legacyQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: legacyService,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var legacyItem: CFTypeRef?
            let legacyStatus = SecItemCopyMatching(legacyQuery as CFDictionary, &legacyItem)
            guard legacyStatus == errSecSuccess,
                  let legacyData = legacyItem as? Data,
                  let value = String(data: legacyData, encoding: .utf8) else {
                continue
            }

            saveAPIKey(value, profileID: profileID)
            return value
        }

        return ""
    }

    static func deleteAPIKey(profileID: String) {
        let account = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
