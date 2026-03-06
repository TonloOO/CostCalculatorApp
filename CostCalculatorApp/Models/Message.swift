import Foundation
import UIKit

// MARK: - Local Display Models

struct ChatDisplayMessage: Identifiable {
    let id: UUID
    var text: String
    let role: MessageRole
    let createdAt: Date
    var imageData: Data?
    var recognitionResult: TextileRecognitionResult?
    var isRecognitionCard: Bool

    init(id: UUID = UUID(), text: String, role: MessageRole, createdAt: Date = Date(),
         imageData: Data? = nil, recognitionResult: TextileRecognitionResult? = nil,
         isRecognitionCard: Bool = false) {
        self.id = id
        self.text = text
        self.role = role
        self.createdAt = createdAt
        self.imageData = imageData
        self.recognitionResult = recognitionResult
        self.isRecognitionCard = isRecognitionCard
    }

    var isUser: Bool { role == .user }

    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

enum MessageRole: String {
    case user
    case assistant
    case system
}

struct ChatConversationDisplay: Identifiable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - LLM API Models

struct LLMChatRequest: Encodable {
    let model: String
    let messages: [LLMMessage]
    let stream: Bool
    let max_tokens: Int?

    init(model: String, messages: [LLMMessage], stream: Bool = true, max_tokens: Int? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.max_tokens = max_tokens
    }
}

struct LLMMessage: Encodable {
    let role: String
    let content: LLMContent

    init(role: String, text: String) {
        self.role = role
        self.content = .text(text)
    }

    init(role: String, parts: [LLMContentPart]) {
        self.role = role
        self.content = .parts(parts)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        switch content {
        case .text(let text):
            try container.encode(text, forKey: .content)
        case .parts(let parts):
            try container.encode(parts, forKey: .content)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
    }
}

enum LLMContent {
    case text(String)
    case parts([LLMContentPart])
}

struct LLMContentPart: Encodable {
    let type: String
    let text: String?
    let image_url: ImageURL?

    static func textPart(_ text: String) -> LLMContentPart {
        LLMContentPart(type: "text", text: text, image_url: nil)
    }

    static func imagePart(base64: String, mediaType: String = "image/jpeg") -> LLMContentPart {
        LLMContentPart(
            type: "image_url",
            text: nil,
            image_url: ImageURL(url: "data:\(mediaType);base64,\(base64)")
        )
    }

    struct ImageURL: Encodable {
        let url: String
    }
}

// MARK: - LLM SSE Response Models

struct LLMChatChunk: Decodable {
    let id: String?
    let choices: [LLMChunkChoice]?
}

struct LLMChunkChoice: Decodable {
    let delta: LLMDelta?
    let finish_reason: String?
}

struct LLMDelta: Decodable {
    let role: String?
    let content: String?
}

struct LLMChatResponse: Decodable {
    let id: String?
    let choices: [LLMResponseChoice]?
    let error: LLMError?
}

struct LLMResponseChoice: Decodable {
    let message: LLMResponseMessage?
    let finish_reason: String?
}

struct LLMResponseMessage: Decodable {
    let role: String?
    let content: String?
}

struct LLMError: Decodable {
    let message: String?
    let type: String?
}
