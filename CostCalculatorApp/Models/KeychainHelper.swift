import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "com.zishuoli.CostCalculatorApp"

    private enum Keys {
        static let apiKey = "openai_api_key"
        static let baseURL = "openai_base_url"
        static let model = "openai_model"
        static let visionModel = "openai_vision_model"
    }

    static let defaultBaseURL = "https://api.chatanywhere.tech"
    static let defaultModel = "gpt-4o-mini"
    static let defaultVisionModel = "gpt-4o"

    // MARK: - API Key

    var apiKey: String {
        get { read(key: Keys.apiKey) ?? "" }
        set { save(key: Keys.apiKey, value: newValue) }
    }

    // MARK: - Base URL

    var baseURL: String {
        get { read(key: Keys.baseURL) ?? Self.defaultBaseURL }
        set { save(key: Keys.baseURL, value: newValue) }
    }

    // MARK: - Model

    var selectedModel: String {
        get { read(key: Keys.model) ?? Self.defaultModel }
        set { save(key: Keys.model, value: newValue) }
    }

    var selectedVisionModel: String {
        get { read(key: Keys.visionModel) ?? Self.defaultVisionModel }
        set { save(key: Keys.visionModel, value: newValue) }
    }

    // MARK: - Generic Keychain Operations

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteAll() {
        for key in [Keys.apiKey, Keys.baseURL, Keys.model, Keys.visionModel] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
