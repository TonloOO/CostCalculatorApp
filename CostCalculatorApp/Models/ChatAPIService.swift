import Foundation
import UIKit

final class LLMChatService {
    static let shared = LLMChatService()
    private init() {}

    private let keychain = KeychainHelper.shared

    private var apiKey: String { keychain.apiKey }
    private var baseURL: String { keychain.baseURL }

    static let textileRecognitionPrompt = """
你是纺织品规格识别专家。请仔细分析这张图片，从中提取所有可能的纺织品制造参数。
请以严格的 JSON 格式返回识别结果。不要包含任何其他文字，只返回 JSON。
字段说明：
- 数值字段请只返回数字字符串（不要包含单位）
- 如果无法识别某个字段，设为 null
- warpYarnType 只能是 "D数" 或 "支数"，如果识别到 75D/72F 则只取D数75，忽略72F
- 如果有多种材料，在 materials 数组中列出
JSON 格式：
{
  "customerName": "客户名称或null",
  "boxNumber": "筘号",
  "threading": "穿入",
  "fabricWidth": "门幅数值",
  "edgeFinishing": "修边数值",
  "fabricShrinkage": "缩率数值",
  "weftDensity": "纬密数值",
  "machineSpeed": "车速数值",
  "efficiency": "效率数值",
  "dailyLaborCost": "日工费数值",
  "fixedCost": "固定费用数值",
  "materials": [
    {
      "name": "材料名称",
      "warpYarnType": "D数或支数",
      "warpYarnValue": "经纱规格值",
      "weftYarnType": "D数或支数",
      "weftYarnValue": "纬纱规格值",
      "warpYarnPrice": "经纱纱价",
      "weftYarnPrice": "纬纱纱价",
      "warpRatio": "经纱占比",
      "weftRatio": "纬纱占比"
    }
  ],
  "confidence": "high/medium/low",
  "notes": "备注或不确定的信息"
}
"""

    private static let textileAssistantSystemPrompt = """
你是一个纺织品制造领域的专业助手，名叫"织梦"。你擅长解答关于纱线规格、织造工艺、成本计算等问题。
请用简洁专业的中文回答用户的问题。如果用户的问题不属于纺织领域，你仍然可以友好地回答。
"""

    // MARK: - Streaming Text Chat

    func streamChat(
        messages: [LLMMessage],
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        let model = keychain.selectedModel
        let request = LLMChatRequest(model: model, messages: messages, stream: true)
        performStreamRequest(request: request, onChunk: onChunk, onComplete: onComplete, onError: onError)
    }

    func buildMessagesForChat(history: [ChatDisplayMessage], systemPrompt: String? = nil) -> [LLMMessage] {
        var apiMessages: [LLMMessage] = []
        apiMessages.append(LLMMessage(role: "system", text: systemPrompt ?? Self.textileAssistantSystemPrompt))

        let recentHistory = history.suffix(20)
        for msg in recentHistory {
            if msg.isRecognitionCard { continue }
            let role = msg.role == .user ? "user" : "assistant"
            if let imgData = msg.imageData, let image = UIImage(data: imgData) {
                let resized = resizeImage(image, maxDimension: 512)
                if let jpegData = resized.jpegData(compressionQuality: 0.7) {
                    let base64 = jpegData.base64EncodedString()
                    let parts: [LLMContentPart] = [
                        .textPart(msg.text.isEmpty ? "请看这张图片" : msg.text),
                        .imagePart(base64: base64)
                    ]
                    apiMessages.append(LLMMessage(role: role, parts: parts))
                }
            } else {
                apiMessages.append(LLMMessage(role: role, text: msg.text))
            }
        }
        return apiMessages
    }

    // MARK: - Vision Image Recognition

    func recognizeTextile(
        image: UIImage,
        onComplete: @escaping (Result<TextileRecognitionResult, Error>) -> Void
    ) {
        let resized = resizeImage(image, maxDimension: 1024)
        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else {
            onComplete(.failure(ChatError.imageEncodingFailed))
            return
        }
        let base64 = jpegData.base64EncodedString()

        let messages: [LLMMessage] = [
            LLMMessage(role: "user", parts: [
                .textPart(Self.textileRecognitionPrompt),
                .imagePart(base64: base64)
            ])
        ]

        let request = LLMChatRequest(
            model: keychain.selectedVisionModel,
            messages: messages,
            stream: false,
            max_tokens: 2000
        )

        performNonStreamRequest(request: request) { result in
            switch result {
            case .success(let text):
                do {
                    let cleaned = Self.extractJSON(from: text)
                    guard let data = cleaned.data(using: .utf8) else {
                        onComplete(.failure(ChatError.invalidResponse))
                        return
                    }
                    let recognition = try JSONDecoder().decode(TextileRecognitionResult.self, from: data)
                    onComplete(.success(recognition))
                } catch {
                    onComplete(.failure(ChatError.jsonParseFailed(text)))
                }
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }

    // MARK: - Private Helpers

    private func performStreamRequest(
        request: LLMChatRequest,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            onError(ChatError.invalidURL)
            return
        }

        guard let body = try? JSONEncoder().encode(request) else {
            onError(ChatError.encodingFailed)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = body

        Task {
            do {
                let (stream, response) = try await URLSession.shared.bytes(for: urlRequest)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    var errorBody = ""
                    for try await line in stream.lines { errorBody += line }
                    await MainActor.run { onError(ChatError.apiError(httpResponse.statusCode, errorBody)) }
                    return
                }

                for try await line in stream.lines {
                    guard line.hasPrefix("data:") else { continue }
                    let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    if jsonString == "[DONE]" { break }
                    guard let jsonData = jsonString.data(using: .utf8),
                          let chunk = try? JSONDecoder().decode(LLMChatChunk.self, from: jsonData),
                          let content = chunk.choices?.first?.delta?.content else { continue }
                    await MainActor.run { onChunk(content) }
                }
                await MainActor.run { onComplete() }
            } catch {
                await MainActor.run { onError(error) }
            }
        }
    }

    private func performNonStreamRequest(
        request: LLMChatRequest,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            completion(.failure(ChatError.invalidURL))
            return
        }

        guard let body = try? JSONEncoder().encode(request) else {
            completion(.failure(ChatError.encodingFailed))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = body
        urlRequest.timeoutInterval = 60

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(ChatError.invalidResponse)) }
                return
            }
            do {
                let apiResponse = try JSONDecoder().decode(LLMChatResponse.self, from: data)
                if let errorInfo = apiResponse.error {
                    DispatchQueue.main.async {
                        completion(.failure(ChatError.apiError(0, errorInfo.message ?? "Unknown error")))
                    }
                    return
                }
                if let content = apiResponse.choices?.first?.message?.content {
                    DispatchQueue.main.async { completion(.success(content)) }
                } else {
                    DispatchQueue.main.async { completion(.failure(ChatError.invalidResponse)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```json") {
            let lines = trimmed.components(separatedBy: "\n")
            let jsonLines = lines.dropFirst().dropLast()
            return jsonLines.joined(separator: "\n")
        }
        if trimmed.hasPrefix("```") {
            let lines = trimmed.components(separatedBy: "\n")
            let jsonLines = lines.dropFirst().dropLast()
            return jsonLines.joined(separator: "\n")
        }
        return trimmed
    }

    // MARK: - Fetch Available Models

    struct ModelsResponse: Decodable {
        let data: [ModelInfo]
    }

    struct ModelInfo: Decodable, Identifiable {
        let id: String
        let object: String?
        let owned_by: String?
    }

    func fetchModels(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/models") else {
            completion(.failure(ChatError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(ChatError.invalidResponse)) }
                return
            }
            do {
                let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
                let modelIDs = modelsResponse.data
                    .map(\.id)
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .sorted()
                DispatchQueue.main.async { completion(.success(modelIDs)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Error Types

    enum ChatError: LocalizedError {
        case invalidURL
        case encodingFailed
        case imageEncodingFailed
        case invalidResponse
        case jsonParseFailed(String)
        case apiError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的 API URL"
            case .encodingFailed: return "请求编码失败"
            case .imageEncodingFailed: return "图片编码失败"
            case .invalidResponse: return "服务器返回了无效响应"
            case .jsonParseFailed(let raw): return "JSON 解析失败: \(raw.prefix(200))"
            case .apiError(let code, let msg): return "API 错误 (\(code)): \(msg)"
            }
        }
    }
}
