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
    @Published var isLoading = false
    @Published private(set) var canApprove: Bool
    
    private(set) var userGuid: String?
    private(set) var userId: String?
    private(set) var userType: Int?
    private(set) var role: String?
    private(set) var salesInfo: ERPSalesInfo?
    
    private let keychainTokenAccount = "xzx_quote_auth_token"
    private let keychainSecretAccount = "xzx_quote_app_secret"
    
    private enum UDKey {
        static let username = "xzx_quote_username"
        static let userGuid = "xzx_quote_user_guid"
        static let userId = "xzx_quote_user_id"
        static let userType = "xzx_quote_user_type"
        static let role = "xzx_quote_user_role"
        static let canApprove = "xzx_quote_can_approve"
        static let salesInfo = "xzx_quote_sales_info"
    }
    
    private init() {
        let token = Self.readKeychain(account: "xzx_quote_auth_token")
        let user = UserDefaults.standard.string(forKey: UDKey.username)
        let storedRole = UserDefaults.standard.string(forKey: UDKey.role)
        
        if token != nil && user != nil && storedRole != nil {
            self.isLoggedIn = true
            self.currentUser = user
            self.userGuid = UserDefaults.standard.string(forKey: UDKey.userGuid)
            self.userId = UserDefaults.standard.string(forKey: UDKey.userId)
            self.userType = UserDefaults.standard.object(forKey: UDKey.userType) as? Int
            self.role = storedRole
            self.canApprove = UserDefaults.standard.bool(forKey: UDKey.canApprove)
            self.salesInfo = Self.loadSalesInfo()
        } else {
            self.isLoggedIn = false
            self.currentUser = nil
            self.canApprove = false
            if token != nil {
                Self.deleteKeychain(account: "xzx_quote_auth_token")
                Self.clearAllUserDefaults()
            }
        }
    }
    
    var authToken: String? {
        Self.readKeychain(account: keychainTokenAccount)
    }

    var appSecret: String? {
        Self.readKeychain(account: keychainSecretAccount)
    }

    func saveAppSecret(_ secret: String) {
        let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Self.deleteKeychain(account: keychainSecretAccount)
        } else {
            Self.saveKeychain(account: keychainSecretAccount, value: trimmed)
        }
    }
    
    // MARK: - ERP Login
    
    func login(username: String, password: String) async -> Result<Void, AuthError> {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUser.isEmpty, !trimmedPass.isEmpty else {
            return .failure(.emptyFields)
        }
        
        let baseURL = QuoteAPIService.shared.baseURL
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            return .failure(.networkError("无效的服务器地址"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let appSecret = appSecret, !appSecret.isEmpty {
            request.addValue(appSecret, forHTTPHeaderField: "X-App-Secret")
        }
        
        let body = ["username": trimmedUser, "password": trimmedPass]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("无效的服务器响应"))
            }
            
            if httpResponse.statusCode == 401 {
                return .failure(.invalidCredentials)
            }
            
            if httpResponse.statusCode == 403 {
                let respBody = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
                if respBody["detail"]?.contains("密钥") == true {
                    return .failure(.invalidSecret)
                }
                return .failure(.accessDenied)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return .failure(.networkError("服务器错误 (\(httpResponse.statusCode)): \(body.prefix(200))"))
            }
            
            let loginResponse = try JSONDecoder().decode(ERPLoginResponse.self, from: data)
            
            await MainActor.run {
                Self.saveKeychain(account: keychainTokenAccount, value: loginResponse.token)
                
                UserDefaults.standard.set(loginResponse.userName, forKey: UDKey.username)
                UserDefaults.standard.set(loginResponse.userGuid, forKey: UDKey.userGuid)
                UserDefaults.standard.set(loginResponse.userId, forKey: UDKey.userId)
                UserDefaults.standard.set(loginResponse.userType, forKey: UDKey.userType)
                UserDefaults.standard.set(loginResponse.role, forKey: UDKey.role)
                UserDefaults.standard.set(loginResponse.canApprove, forKey: UDKey.canApprove)
                Self.saveSalesInfo(loginResponse.sales)
                
                isLoggedIn = true
                currentUser = loginResponse.userName
                userGuid = loginResponse.userGuid
                userId = loginResponse.userId
                userType = loginResponse.userType
                role = loginResponse.role
                canApprove = loginResponse.canApprove
                salesInfo = loginResponse.sales
            }
            
            return .success(())
            
        } catch is DecodingError {
            return .failure(.networkError("服务器响应格式异常"))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
    
    func logout() {
        Self.deleteKeychain(account: keychainTokenAccount)
        Self.clearAllUserDefaults()
        isLoggedIn = false
        currentUser = nil
        userGuid = nil
        userId = nil
        userType = nil
        role = nil
        canApprove = false
        salesInfo = nil
    }
    
    // MARK: - SalesInfo Persistence
    
    private static func saveSalesInfo(_ info: ERPSalesInfo?) {
        guard let info else {
            UserDefaults.standard.removeObject(forKey: UDKey.salesInfo)
            return
        }
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: UDKey.salesInfo)
        }
    }
    
    private static func loadSalesInfo() -> ERPSalesInfo? {
        guard let data = UserDefaults.standard.data(forKey: UDKey.salesInfo) else { return nil }
        return try? JSONDecoder().decode(ERPSalesInfo.self, from: data)
    }
    
    private static func clearAllUserDefaults() {
        for key in [UDKey.username, UDKey.userGuid, UDKey.userId,
                    UDKey.userType, UDKey.role, UDKey.canApprove, UDKey.salesInfo] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - Keychain Helpers
    
    static func saveKeychain(account: String, value: String) {
        deleteKeychain(account: account)
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func readKeychain(account: String) -> String? {
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
    
    static func deleteKeychain(account: String) {
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
        case invalidSecret
        case accessDenied
        case networkError(String)
        
        var errorDescription: String? {
            switch self {
            case .emptyFields: return "请输入用户名和密码"
            case .invalidCredentials: return "用户名或密码错误"
            case .invalidSecret: return "应用密钥无效，请检查后重试"
            case .accessDenied: return "您没有报价模块的访问权限，仅业务员和管理员可登录"
            case .networkError(let msg): return "网络错误: \(msg)"
            }
        }
    }
}

// MARK: - API Response Models

struct ERPSalesInfo: Codable {
    let salesGuid: String
    let salesNo: String
    let salesName: String
    let salesGroupGuid: String?
}

struct ERPLoginResponse: Codable {
    let token: String
    let userGuid: String
    let userId: String
    let userName: String
    let userType: Int
    let role: String
    let canApprove: Bool
    let sales: ERPSalesInfo?
}
