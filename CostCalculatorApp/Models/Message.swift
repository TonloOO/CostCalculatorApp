//
//  Message.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//


// Models.swift

import Foundation

struct Message: Identifiable {
    let id: UUID
    var text: String
    let isUser: Bool
    let createdAt: TimeInterval
}

struct Conversation: Identifiable {
    let id: UUID
    var title: String
    let createdAt: TimeInterval
}

// API Response Models
struct ConversationsResponse: Decodable {
    let limit: Int
    let has_more: Bool
    let data: [ConversationData]
}

struct ConversationData: Decodable {
    let id: String
    let name: String
    let inputs: [String: String]?
    let introduction: String?
    let created_at: TimeInterval
}

struct MessagesResponse: Decodable {
    let limit: Int
    let has_more: Bool
    let data: [MessageData]
}

struct MessageData: Decodable {
    let id: String
    let conversation_id: String
    let inputs: [String: String]?
    let query: String?
    let answer: String?
    let message_files: [MessageFile]?
    let feedback: Feedback?
    let retriever_resources: [RetrieverResource]?
    let created_at: TimeInterval
}

struct MessageFile: Decodable {
    let id: String
    let type: String
    let url: String
    let belongs_to: String
}

struct Feedback: Decodable {
    let rating: String
}

struct RetrieverResource: Decodable {
    let position: Int
    let dataset_id: String
    let dataset_name: String
    let document_id: String
    let document_name: String
    let segment_id: String
    let score: Double
    let content: String
}

struct ChunkChatCompletionResponse: Decodable {
    let task_id: String
    let message_id: String
    let conversation_id: String
    let answer: String
    let created_at: Int
}

struct DeleteResponse: Decodable {
    let result: String
}
