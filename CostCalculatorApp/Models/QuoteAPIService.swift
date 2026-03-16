//
//  QuoteAPIService.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import Foundation

final class QuoteAPIService: ObservableObject {
    static let shared = QuoteAPIService()
    
    /// Base URL for the XZX API, configurable via UserDefaults.
    /// Defaults to localhost for simulator development.
    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "xzx_api_base_url")
        }
    }
    
    private init() {
        self.baseURL = UserDefaults.standard.string(forKey: "xzx_api_base_url")
            ?? "http://1.94.161.134:8808"
    }
    
    // MARK: - Quote Overview
    
    func fetchQuoteOverview(
        status: Int? = nil,
        keyword: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil,
        page: Int = 1,
        pageSize: Int = 50
    ) async throws -> PaginatedResponse<QuoteOverview> {
        var components = URLComponents(string: "\(baseURL)/api/quote-overview")!
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: "\(status)"))
        }
        if let keyword = keyword, !keyword.isEmpty {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let dateFrom = dateFrom {
            queryItems.append(URLQueryItem(name: "date_from", value: dateFrom))
        }
        if let dateTo = dateTo {
            queryItems.append(URLQueryItem(name: "date_to", value: dateTo))
        }
        components.queryItems = queryItems
        
        return try await performRequest(url: components.url!)
    }

    func fetchQuoteApproval(
        status: Int? = nil,
        page: Int = 1,
        pageSize: Int = 50
    ) async throws -> PaginatedResponse<QuoteApproval> {
        var components = URLComponents(string: "\(baseURL)/api/quote-approval")!
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: "\(status)"))
        }
        components.queryItems = queryItems

        return try await performRequest(url: components.url!)
    }

    func performApprovalAction(
        quoteNo: String,
        action: QuoteApprovalAction,
        operatorName: String
    ) async throws -> QuoteApprovalActionResponse {
        let encodedQuoteNo = quoteNo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quoteNo
        let url = URL(string: "\(baseURL)/api/quote-approval/\(encodedQuoteNo)/action")!
        let payload = QuoteApprovalActionRequest(action: action, operatorName: operatorName)
        return try await performRequest(url: url, method: "POST", body: payload)
    }

    func fetchQuoteDetail(quoteNo: String) async throws -> QuoteDetail {
        let encodedQuoteNo = quoteNo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quoteNo
        let url = URL(string: "\(baseURL)/api/quote/\(encodedQuoteNo)/detail")!
        return try await performRequest(url: url)
    }

    // MARK: - Reference Data

    func searchCustomers(keyword: String) async throws -> [CustomerRef] {
        var components = URLComponents(string: "\(baseURL)/api/reference/customers")!
        components.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return try await performRequest(url: components.url!)
    }

    func fetchSalespeople() async throws -> [SalespersonRef] {
        let url = URL(string: "\(baseURL)/api/reference/salespeople")!
        return try await performRequest(url: url)
    }

    func searchSuppliers(keyword: String) async throws -> [SupplierRef] {
        var components = URLComponents(string: "\(baseURL)/api/reference/suppliers")!
        components.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return try await performRequest(url: components.url!)
    }

    func searchSizingProviders(keyword: String) async throws -> [SupplierRef] {
        var components = URLComponents(string: "\(baseURL)/api/reference/sizing-providers")!
        components.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return try await performRequest(url: components.url!)
    }

    func searchMaterials(keyword: String) async throws -> [MaterialRef] {
        var components = URLComponents(string: "\(baseURL)/api/reference/materials")!
        components.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return try await performRequest(url: components.url!)
    }

    func fetchDictionary(typeCode: String) async throws -> [DictionaryItem] {
        let encoded = typeCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? typeCode
        let url = URL(string: "\(baseURL)/api/reference/dictionary/\(encoded)")!
        return try await performRequest(url: url)
    }

    // MARK: - Quote Creation

    func createQuote(_ request: QuoteCreateRequest) async throws -> QuoteCreateResponse {
        let url = URL(string: "\(baseURL)/api/quote")!
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func updateQuote(quoteNo: String, request: QuoteCreateRequest) async throws -> QuoteCreateResponse {
        let encodedQuoteNo = quoteNo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quoteNo
        let url = URL(string: "\(baseURL)/api/quote/\(encodedQuoteNo)")!
        return try await performRequest(url: url, method: "PUT", body: request)
    }

    func fetchMaterialBOM(materialGuid: String) async throws -> BOMResponse {
        let encoded = materialGuid.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? materialGuid
        let url = URL(string: "\(baseURL)/api/reference/materials/\(encoded)/bom")!
        return try await performRequest(url: url)
    }

    func fetchWeavePattern(quoteNo: String) async throws -> WeavePatternResponse {
        let encodedQuoteNo = quoteNo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quoteNo
        let url = URL(string: "\(baseURL)/api/quote/\(encodedQuoteNo)/weave-pattern")!
        return try await performRequest(url: url)
    }
    
    // MARK: - Health Check
    
    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Private

    private func performRequest<T: Codable>(url: URL) async throws -> T {
        try await performRequest(url: url, method: "GET", body: Optional<EmptyRequestBody>.none)
    }
    
    private func performRequest<T: Codable, Body: Encodable>(
        url: URL,
        method: String = "GET",
        body: Body? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let token = QuoteAuthManager.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let secret = QuoteAuthManager.shared.appSecret, !secret.isEmpty {
            request.addValue(secret, forHTTPHeaderField: "X-App-Secret")
        }

        if let body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuoteAPIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            await MainActor.run { QuoteAuthManager.shared.logout() }
            throw QuoteAPIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QuoteAPIError.serverError(httpResponse.statusCode, body)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw QuoteAPIError.decodingFailed(error.localizedDescription)
        }
    }
}

private struct EmptyRequestBody: Encodable {}

// MARK: - Errors

enum QuoteAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case serverError(Int, String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .serverError(let code, let body):
            return "服务器错误 (\(code)): \(body.prefix(200))"
        case .decodingFailed(let detail):
            return "数据解析失败: \(detail)"
        }
    }
}
