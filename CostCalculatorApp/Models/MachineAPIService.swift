//
//  MachineAPIService.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-04-29.
//

import Foundation
import Observation

@Observable
@MainActor
final class MachineAPIService {
    static let shared = MachineAPIService()

    private init() {}

    /// Reuses the base URL configured in QuoteAPIService so the user only
    /// configures the API endpoint in one place.
    private var baseURL: String {
        QuoteAPIService.shared.baseURL
    }

    func fetchOverview() async throws -> MachineOverview {
        let url = URL(string: "\(baseURL)/api/machine/overview")!
        return try await performRequest(url: url)
    }

    func fetchList(bucket: MachineBucket?) async throws -> [MachineListItem] {
        var components = URLComponents(string: "\(baseURL)/api/machine/list")!
        let bucketValue = bucket?.rawValue ?? "all"
        components.queryItems = [URLQueryItem(name: "bucket", value: bucketValue)]
        return try await performRequest(url: components.url!)
    }

    func fetchDetail(equipmentNo: String, days: Int = 14) async throws -> MachineDetail {
        let encoded = equipmentNo.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? equipmentNo
        var components = URLComponents(string: "\(baseURL)/api/machine/\(encoded)/detail")!
        components.queryItems = [URLQueryItem(name: "days", value: "\(days)")]
        return try await performRequest(url: components.url!)
    }

    // MARK: - Private

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        if let token = AuthManager.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let secret = AuthManager.shared.appSecret, !secret.isEmpty {
            request.addValue(secret, forHTTPHeaderField: "X-App-Secret")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw MachineAPIError.invalidResponse
        }

        if http.statusCode == 401 {
            AuthManager.shared.logout()
            throw MachineAPIError.unauthorized
        }
        if http.statusCode == 403 {
            throw MachineAPIError.forbidden
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MachineAPIError.serverError(http.statusCode, body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw MachineAPIError.decodingFailed(error.localizedDescription)
        }
    }
}

enum MachineAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case serverError(Int, String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .forbidden:
            return "您没有权限访问机台数据（仅管理员）"
        case .serverError(let code, let body):
            return "服务器错误 (\(code)): \(body.prefix(120))"
        case .decodingFailed(let msg):
            return "数据解析失败: \(msg)"
        }
    }
}
