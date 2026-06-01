import Foundation
import Security

final class APIKeyStore {
    enum StoreError: LocalizedError {
        case encodingFailed
        case decodingFailed
        case keychain(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Could not encode API key"
            case .decodingFailed:
                return "Could not decode API key"
            case .keychain(let status):
                return "Keychain error \(status)"
            }
        }
    }

    private let service = "com.watchmemo.app.openai-compatible"
    private let account = "transcription-api-key"

    func save(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw StoreError.encodingFailed
        }

        let query = baseQuery()
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StoreError.keychain(status)
        }
    }

    func load() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw StoreError.keychain(status)
        }
        guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw StoreError.decodingFailed
        }

        return key
    }

    func hasKey() -> Bool {
        (try? load())?.isEmpty == false
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.keychain(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
