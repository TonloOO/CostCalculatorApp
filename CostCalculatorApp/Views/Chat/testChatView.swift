//
//  testChatView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-16.
//


import SwiftUI
import MarkdownUI

struct TestChatView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showHistory: Bool = false
    @State private var conversationHistory: [Conversation] = []
    @State private var selectedConversationID: String?
    @FocusState private var isInputActive: Bool

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
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
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
                    .padding()
                }
                .onChange(of: lastMessageText) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }


            HStack {
                TextField("请输入你的问题", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputActive)
                    .disabled(isSending)
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Text("发送")
                }
                .disabled(inputText.isEmpty || isSending)
            }
            .padding()
        }
    }

    func sendMessage() async {
        
//        guard !inputText.isEmpty else { return }
//
//        let userMessage = Message(id: UUID(), text: inputText, isUser: true, createdAt: Date().timeIntervalSince1970)
//        messages.append(userMessage)
//
//        let userInput = inputText
//        inputText = ""
//        isSending = true
//        isInputActive = false
//
//        let llamaManager = LlamaManager()
//
//        do {
//            // Call the runLlamaModel function from LlamaManager
//            try await llamaManager.runLlamaModel(prompt: userInput)
//        } catch {
//            print("Failed to run the LLaMA model: \(error)")
//        }
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

struct TestChatHistoryView: View {
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


struct TestChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
