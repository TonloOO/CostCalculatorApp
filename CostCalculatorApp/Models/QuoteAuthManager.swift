//
//  QuoteAuthManager.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import Foundation
import Security

final class QuoteAuthManager: ObservableObject {
    static let shared = QuoteAuthManager()
    
    @Published var isLoggedIn: Bool
    @Published var currentUser: String?
    
    private let keychainAccount = "xzx_quote_auth"
    private let userDefaultsKey = "xzx_quote_username"
    
    /// Hardcoded credentials for enterprise internal use.
    /// Replace with API-based auth when ready.
    private let validCredentials: [String: String] = [
        "admin": "xzx2026",
        "manager": "xzx2026",
        "viewer": "xzx2026"
    ]
    
    private init() {
        let hasToken = Self.readKeychain(account: keychainAccount) != nil
        let user = UserDefaults.standard.string(forKey: userDefaultsKey)
        self.isLoggedIn = hasToken && user != nil
        self.currentUser = user
    }
    
    func login(username: String, password: String) -> Result<Void, AuthError> {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUser.isEmpty, !trimmedPass.isEmpty else {
            return .failure(.emptyFields)
        }
        
        guard let expected = validCredentials[trimmedUser.lowercased()],
              expected == trimmedPass else {
            return .failure(.invalidCredentials)
        }
        
        let token = UUID().uuidString
        Self.saveKeychain(account: keychainAccount, value: token)
        UserDefaults.standard.set(trimmedUser, forKey: userDefaultsKey)
        
        isLoggedIn = true
        currentUser = trimmedUser
        return .success(())
    }
    
    func logout() {
        Self.deleteKeychain(account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        isLoggedIn = false
        currentUser = nil
    }
    
    // MARK: - Keychain Helpers
    
    private static func saveKeychain(account: String, value: String) {
        deleteKeychain(account: account)
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private static func deleteKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Error
    
    enum AuthError: LocalizedError {
        case emptyFields
        case invalidCredentials
        
        var errorDescription: String? {
            switch self {
            case .emptyFields: return "请输入用户名和密码"
            case .invalidCredentials: return "用户名或密码错误"
            }
        }
    }
}
