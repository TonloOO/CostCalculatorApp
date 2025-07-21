//
//  ChatView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//

// ChatView.swift

import SwiftUI
import MarkdownUI

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showHistory: Bool = false
    @State private var conversationHistory: [Conversation] = []
    @State private var selectedConversationID: String?
    @FocusState private var isInputActive: Bool
    @State private var scrollViewID = UUID()

    var lastMessageText: String {
        messages.last?.text ?? ""
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    fetchConversationHistory()
                    showHistory = true
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.gray)
                }
                .padding(.leading)
                .sheet(isPresented: $showHistory) {
                    ChatHistoryView(conversations: $conversationHistory,
                                    onSelectConversation: { selectedConversation in
                        loadConversation(selectedConversation)
                        showHistory = false
                    },
                                    onDeleteConversation: { conversation in
                        deleteConversation(conversation)
                    })
                    .presentationDetents([.fraction(0.7)])
                }
                Spacer()
                Text("织梦·雅集")
                    .font(.title2)
                Spacer()
                Button(action: createNewConversation) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            MessageRowView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: lastMessageText) {
                    // Use debounced scroll to improve performance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }


            HStack {
                TextField("请输入你的问题", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputActive)
                    .disabled(isSending)
                Button(action: sendMessage) {
                    Text("发送")
                }
                .disabled(inputText.isEmpty || isSending)
            }
            .padding()
        }
    }

    func sendMessage() {
        let baseURL = "https://zscy.space/api/v1/sse"
        let user = UserManager.shared.userID
        guard !inputText.isEmpty else { return }

        let userMessage = Message(id: UUID(), text: inputText, isUser: true, createdAt: Date().timeIntervalSince1970)
        messages.append(userMessage)

        let userInput = inputText
        inputText = ""
        isSending = true
        isInputActive = false

        // Prepare the response message placeholder to append the streamed response
        let responseMessageID = UUID()
        var responseMessage = Message(id: responseMessageID, text: "", isUser: false, createdAt: Date().timeIntervalSince1970)
        messages.append(responseMessage)  // Add it to the messages for rendering

        // API call logic directly in sendMessage
        guard let url = URL(string: "\(baseURL)/forward_sse") else {
            print("Invalid URL")
            isSending = false
            return
        }

        let parameters: [String: Any] = [
            "query": userInput,
            "inputs": [:],
            "response_mode": "streaming",
            "user": user,  // Replace with actual user ID
            "conversation_id": selectedConversationID ?? ""
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to serialize parameters")
            isSending = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        Task {
            do {
                let (stream, _) = try await URLSession.shared.bytes(for: request)
                
                for try await line in stream.lines {
                    if line.starts(with: "data:") {
                        let jsonString = String(line.dropFirst(5)) // Strip "data:" prefix
                        if let jsonData = jsonString.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(ChunkChatCompletionResponse.self, from: jsonData) {
                            if selectedConversationID == nil {
                                selectedConversationID = chunk.conversation_id
                            }

                            // Append the new chunk of response to the responseMessage
                            responseMessage.text += chunk.answer

                            // Update the UI on the main thread
                            await MainActor.run {
                                if let index = messages.firstIndex(where: { $0.id == responseMessageID }) {
                                    messages[index] = responseMessage
                                }
                            }
                        }
                    }
                }
                await MainActor.run {
                    isSending = false
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    isSending = false
                }
            }
        }
    }


    func fetchConversationHistory() {
        ChatAPIService.shared.fetchConversationHistory { conversations in
            if let conversations = conversations {
                DispatchQueue.main.async {
                    self.conversationHistory = conversations
                }
            } else {
                print("Failed to fetch conversation history")
            }
        }
    }

    func createNewConversation() {
        messages = []
        selectedConversationID = nil
    }

    func loadConversation(_ conversation: Conversation) {
        selectedConversationID = conversation.id.uuidString
        // Fetch messages for the selected conversation
        ChatAPIService.shared.fetchMessagesForConversation(conversationID: conversation.id.uuidString) { messages in
            if let messages = messages {
                DispatchQueue.main.async {
                    self.messages = messages
                }
            } else {
                print("Failed to fetch messages for conversation")
            }
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
            ChatAPIService.shared.deleteConversation(conversationID: conversation.id.uuidString) { success in
                if success {
                    DispatchQueue.main.async {
                        // Remove the conversation from local history
                        if let index = conversationHistory.firstIndex(where: { $0.id == conversation.id }) {
                            conversationHistory.remove(at: index)
                        }
                    }
                } else {
                    print("Failed to delete conversation")
                }
            }
    }
}

// MARK: - MessageRowView for optimized rendering
struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Markdown(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .frame(maxWidth: 350, alignment: .leading)
                Spacer()
            }
        }
    }
}

struct ChatHistoryView: View {
    @Binding var conversations: [Conversation]
    var onSelectConversation: (Conversation) -> Void
    var onDeleteConversation: (Conversation) -> Void  // New closure for deleting a conversation

    var body: some View {
        VStack(alignment: .leading) {
            Text("历史对话")
                .font(.headline)
                .padding()
            List {
                ForEach(conversations.sorted(by: { $0.createdAt > $1.createdAt })) { conversation in
                    HStack {
                        Button(action: {
                            onSelectConversation(conversation)
                        }) {
                            Text(conversation.title)
                        }
                        Spacer()
                        Button(action: {
                            onDeleteConversation(conversation)  // Call the delete action
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())  // Avoid the button affecting the row selection
                    }
                }
            }
        }
    }
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
