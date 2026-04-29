import Foundation
import CoreData
import Observation
import UIKit

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatDisplayMessage] = []
    var conversations: [ChatConversationDisplay] = []
    var inputText: String = ""
    var isSending: Bool = false
    var selectedImage: UIImage?
    var isRecognizing: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    var navigateToCalculator: Bool = false
    var recognitionForCalculator: TextileRecognitionResult?
    var scrollToBottomTrigger: UUID = UUID()

    private var currentConversationID: UUID?
    private var lastScrollTime: Date = .distantPast
    private let viewContext: NSManagedObjectContext
    private let chatService = LLMChatService.shared

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadConversations()
    }

    // MARK: - Conversation Management

    func createNewConversation() {
        messages = []
        currentConversationID = nil
        selectedImage = nil
    }

    func loadConversations() {
        let request = NSFetchRequest<ChatConversation>(entityName: "ChatConversation")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        do {
            let results = try viewContext.fetch(request)
            conversations = results.map { conv in
                ChatConversationDisplay(
                    id: conv.id ?? UUID(),
                    title: conv.title ?? "新对话",
                    createdAt: conv.createdAt ?? Date(),
                    updatedAt: conv.updatedAt ?? Date()
                )
            }
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }

    func loadConversation(_ conversation: ChatConversationDisplay) {
        currentConversationID = conversation.id
        loadMessages(for: conversation.id)
    }

    func deleteConversation(_ conversation: ChatConversationDisplay) {
        let request = NSFetchRequest<ChatConversation>(entityName: "ChatConversation")
        request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
        do {
            let results = try viewContext.fetch(request)
            for conv in results {
                viewContext.delete(conv)
            }
            try viewContext.save()
            conversations.removeAll { $0.id == conversation.id }
            if currentConversationID == conversation.id {
                createNewConversation()
            }
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }

    // MARK: - Message Loading

    private func loadMessages(for conversationID: UUID) {
        let request = NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
        request.predicate = NSPredicate(format: "conversation.id == %@", conversationID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let results = try viewContext.fetch(request)
            messages = results.map { msg in
                var recognitionResult: TextileRecognitionResult?
                if let data = msg.extractedData {
                    recognitionResult = try? JSONDecoder().decode(TextileRecognitionResult.self, from: data)
                }
                return ChatDisplayMessage(
                    id: msg.id ?? UUID(),
                    text: msg.textContent ?? "",
                    role: MessageRole(rawValue: msg.role ?? "user") ?? .user,
                    createdAt: msg.createdAt ?? Date(),
                    imageData: msg.imageData,
                    recognitionResult: recognitionResult,
                    isRecognitionCard: msg.isRecognitionCard
                )
            }
        } catch {
            print("Failed to load messages: \(error)")
        }
    }

    // MARK: - Send Message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage
        guard !text.isEmpty || image != nil else { return }

        inputText = ""
        selectedImage = nil
        isSending = true

        ensureConversation(title: String(text.prefix(20)))

        let userMessage = ChatDisplayMessage(
            text: text,
            role: .user,
            imageData: image?.jpegData(compressionQuality: 0.8)
        )
        messages.append(userMessage)
        saveMessage(userMessage)
        requestScrollToBottom()

        if let image = image {
            recognizeImage(image, userText: text)
        } else {
            streamTextResponse()
        }
    }

    func sendImageForRecognition(_ image: UIImage) {
        selectedImage = nil
        isSending = true
        isRecognizing = true

        ensureConversation(title: "图片识别")

        let imageData = image.jpegData(compressionQuality: 0.8)
        let userMessage = ChatDisplayMessage(
            text: "请识别这张纺织品规格图片",
            role: .user,
            imageData: imageData
        )
        messages.append(userMessage)
        saveMessage(userMessage)

        recognizeImage(image, userText: "")
    }

    // MARK: - Image Recognition

    private func recognizeImage(_ image: UIImage, userText: String) {
        isRecognizing = true

        let processingMsg = ChatDisplayMessage(
            text: "正在识别图片中的纺织品参数...",
            role: .assistant
        )
        messages.append(processingMsg)
        requestScrollToBottom()

        chatService.recognizeTextile(image: image) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.messages.removeLast()
                self.isRecognizing = false

                switch result {
                case .success(let recognition):
                    let cardMessage = ChatDisplayMessage(
                        text: "识别完成",
                        role: .assistant,
                        recognitionResult: recognition,
                        isRecognitionCard: true
                    )
                    self.messages.append(cardMessage)
                    self.saveMessage(cardMessage)
                    self.requestScrollToBottom()

                    if !userText.isEmpty {
                        self.streamTextResponse()
                    } else {
                        self.isSending = false
                    }

                case .failure(let error):
                    let errorMsg = ChatDisplayMessage(
                        text: "识别失败: \(error.localizedDescription)",
                        role: .assistant
                    )
                    self.messages.append(errorMsg)
                    self.saveMessage(errorMsg)
                    self.requestScrollToBottom()
                    self.isSending = false
                }
            }
        }
    }

    // MARK: - Stream Text Response

    private func streamTextResponse() {
        let apiMessages = chatService.buildMessagesForChat(history: messages)

        let responseID = UUID()
        var responseMessage = ChatDisplayMessage(
            id: responseID,
            text: "",
            role: .assistant
        )
        messages.append(responseMessage)

        chatService.streamChat(
            messages: apiMessages,
            onChunk: { [weak self] content in
                guard let self = self else { return }
                responseMessage.text += content
                if let index = self.messages.firstIndex(where: { $0.id == responseID }) {
                    self.messages[index] = responseMessage
                }
                self.throttledScrollToBottom()
            },
            onComplete: { [weak self] in
                guard let self = self else { return }
                self.isSending = false
                self.saveMessage(responseMessage)
                self.updateConversationTimestamp()
                self.scrollToBottomTrigger = UUID()
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.isSending = false
                if let index = self.messages.firstIndex(where: { $0.id == responseID }) {
                    self.messages[index].text = "请求失败: \(error.localizedDescription)"
                    self.saveMessage(self.messages[index])
                }
                self.scrollToBottomTrigger = UUID()
            }
        )
    }

    // MARK: - Scroll Control

    func requestScrollToBottom() {
        scrollToBottomTrigger = UUID()
    }

    private func throttledScrollToBottom() {
        let now = Date()
        guard now.timeIntervalSince(lastScrollTime) >= 0.08 else { return }
        lastScrollTime = now
        scrollToBottomTrigger = UUID()
    }

    // MARK: - Navigation

    func navigateToCalculator(with result: TextileRecognitionResult) {
        recognitionForCalculator = result
        navigateToCalculator = true
    }

    // MARK: - Core Data Persistence

    private func ensureConversation(title: String) {
        guard currentConversationID == nil else { return }
        let conversation = ChatConversation(context: viewContext)
        let id = UUID()
        conversation.id = id
        conversation.title = title.isEmpty ? "新对话" : title
        conversation.createdAt = Date()
        conversation.updatedAt = Date()
        currentConversationID = id

        do {
            try viewContext.save()
            loadConversations()
        } catch {
            print("Failed to save conversation: \(error)")
        }
    }

    private func saveMessage(_ message: ChatDisplayMessage) {
        guard let conversationID = currentConversationID else { return }

        let request = NSFetchRequest<ChatConversation>(entityName: "ChatConversation")
        request.predicate = NSPredicate(format: "id == %@", conversationID as CVarArg)

        do {
            guard let conversation = try viewContext.fetch(request).first else { return }

            let chatMessage = ChatMessage(context: viewContext)
            chatMessage.id = message.id
            chatMessage.role = message.role.rawValue
            chatMessage.textContent = message.text
            chatMessage.imageData = message.imageData
            chatMessage.isRecognitionCard = message.isRecognitionCard
            chatMessage.createdAt = message.createdAt
            chatMessage.conversation = conversation

            if let recognition = message.recognitionResult {
                chatMessage.extractedData = try? JSONEncoder().encode(recognition)
            }

            try viewContext.save()
        } catch {
            print("Failed to save message: \(error)")
        }
    }

    private func updateConversationTimestamp() {
        guard let conversationID = currentConversationID else { return }
        let request = NSFetchRequest<ChatConversation>(entityName: "ChatConversation")
        request.predicate = NSPredicate(format: "id == %@", conversationID as CVarArg)
        do {
            if let conversation = try viewContext.fetch(request).first {
                conversation.updatedAt = Date()
                try viewContext.save()
                loadConversations()
            }
        } catch {
            print("Failed to update conversation timestamp: \(error)")
        }
    }
}
