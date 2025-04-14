import Foundation
import Security

class SecureStorage {
    static let shared = SecureStorage()

    private init() {}

    func saveAPIKey(_ key: String, for service: String) throws {
        // Check if the key already exists
        if hasAPIKey(for: service) {
            // Update the existing key
            try updateAPIKey(key, for: service)
            return
        }

        // Create a new key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: key.data(using: .utf8)!
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Failed to save API key for \(service). Status: \(status)")
            throw KeychainError.unableToSave
        }
    }

    func updateAPIKey(_ key: String, for service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: key.data(using: .utf8)!
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            print("Failed to update API key for \(service). Status: \(status)")
            throw KeychainError.unableToSave
        }
    }

    func getAPIKey(for service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            print("Failed to get API key for \(service). Status: \(status)")
            throw KeychainError.notFound
        }

        return key
    }

    func hasAPIKey(for service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func deleteAPIKey(for service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("Failed to delete API key for \(service). Status: \(status)")
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: LocalizedError {
    case notFound
    case unableToSave
    case unableToDelete

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "API key not found in keychain"
        case .unableToSave:
            return "Unable to save API key to keychain"
        case .unableToDelete:
            return "Unable to delete API key from keychain"
        }
    }
}