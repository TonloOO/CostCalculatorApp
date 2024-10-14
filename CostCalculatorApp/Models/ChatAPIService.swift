//
//  ChatAPIService.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//


// ChatAPIService.swift

import Foundation

class ChatAPIService {
    static let shared = ChatAPIService()
    private init() {}
    
    private let apiKey = "app-kZLrGeyOmfWYByNAz8FrA9cx"
    private let baseURL = "https://llm.shiran-tech.cn/v1"
    private let user = UserManager.shared.userID
    
    // Fetch list of conversations
    func fetchConversationHistory(completion: @escaping ([Conversation]?) -> Void) {
        let limit = 20
        
        var urlComponents = URLComponents(string: "\(baseURL)/conversations")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user", value: user),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching conversation history: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data returned from API")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(ConversationsResponse.self, from: data)
                
                let conversations = apiResponse.data.map { conversationData -> Conversation in
                    return Conversation(
                        id: UUID(uuidString: conversationData.id) ?? UUID(),
                        title: conversationData.name,
                        createdAt: conversationData.created_at
                    )
                }
                completion(conversations)
            } catch {
                print("Error parsing conversation history: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    // Fetch messages for a specific conversation
    func fetchMessagesForConversation(conversationID: String, completion: @escaping ([Message]?) -> Void) {
        let limit = 50 // Adjust as needed
        
        var urlComponents = URLComponents(string: "\(baseURL)/messages")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user", value: user),
            URLQueryItem(name: "conversation_id", value: conversationID),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data returned from API")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(MessagesResponse.self, from: data)
                
                var messages: [Message] = []
                
                // The API returns messages in reverse chronological order; reverse it to chronological
//                let sortedData = apiResponse.data.sorted { $0.created_at < $1.created_at }
                let sortedData = apiResponse.data
                
                for messageData in sortedData {
                    let userMessage = Message(
                        id: UUID(),
                        text: messageData.query!,
                        isUser: true,
                        createdAt: messageData.created_at
                    )
                    messages.append(userMessage)
                    let assistantMessage = Message(
                        id: UUID(),
                        text: messageData.answer!,
                        isUser: false,
                        createdAt: messageData.created_at
                    )
                    messages.append(assistantMessage)
                }
                completion(messages)
            } catch {
                print("Error parsing messages: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func deleteConversation(conversationID: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/conversations/\(conversationID)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["user": user]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error creating request body: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting conversation: \(error)")
                completion(false)
                return
            }
            
            guard data != nil else {
                print("No data returned from API")
                completion(false)
                return
            }
            
            do {
                completion(true)
            }
        }.resume()
    }

    
}
