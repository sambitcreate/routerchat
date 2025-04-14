import Foundation
import Security

class SecureStorage {
    static let shared = SecureStorage()
    
    private init() {}
    
    func saveAPIKey(_ key: String, for service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    func getAPIKey(for service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return key
    }
}

enum KeychainError: LocalizedError {
    case notFound
    case unableToSave
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "API key not found in keychain"
        case .unableToSave:
            return "Unable to save API key to keychain"
        }
    }
}