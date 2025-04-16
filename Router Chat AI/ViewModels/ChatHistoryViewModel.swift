import SwiftUI
import SwiftData

class ChatHistoryViewModel: ObservableObject {
    @Published var chatHistory: [ChatSession] = []
    private let userDefaults = UserDefaults.standard
    private let chatHistoryKey = "savedChatHistory"

    init() {
        // Load saved chat history
        loadChatHistory()

        // Listen for new chats to be saved
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewChat),
            name: Notification.Name("SaveChatToHistory"),
            object: nil
        )
    }

    private func loadChatHistory() {
        // Load from UserDefaults
        if let savedData = userDefaults.data(forKey: chatHistoryKey),
           let decodedSessions = try? JSONDecoder().decode([ChatSessionData].self, from: savedData) {
            // Convert the decoded data to ChatSession objects
            chatHistory = decodedSessions.map { data in
                return ChatSession(
                    id: data.id,
                    title: data.title,
                    lastMessage: data.lastMessage,
                    date: data.date,
                    messages: data.messages.map { messageData in
                        return Message(
                            id: messageData.id,
                            content: messageData.content,
                            role: MessageRole(rawValue: messageData.role) ?? .user,
                            timestamp: messageData.timestamp,
                            provider: Provider(rawValue: messageData.providerType) ?? .openAI,
                            model: messageData.model
                        )
                    }
                )
            }
            print("Loaded \(chatHistory.count) chats from history")
        } else {
            // If no saved data, start with an empty array
            chatHistory = []
            print("No saved chat history found")
        }
    }

    private func saveChatHistory() {
        // Convert ChatSession objects to encodable ChatSessionData
        let sessionData = chatHistory.map { session -> ChatSessionData in
            let messageData = session.messages.map { message -> MessageData in
                return MessageData(
                    id: message.id,
                    content: message.content,
                    role: message.role.rawValue,
                    timestamp: message.timestamp,
                    providerType: message.providerType,
                    model: message.model
                )
            }

            return ChatSessionData(
                id: session.id,
                title: session.title,
                lastMessage: session.lastMessage,
                date: session.date,
                messages: messageData
            )
        }

        // Encode and save to UserDefaults
        if let encodedData = try? JSONEncoder().encode(sessionData) {
            userDefaults.set(encodedData, forKey: chatHistoryKey)
            print("Saved \(chatHistory.count) chats to history")
        }
    }

    @objc private func handleNewChat(_ notification: Notification) {
        print("handleNewChat: Received notification to save chat to history")

        if let chatSession = notification.object as? ChatSession {
            print("handleNewChat: Processing chat session with ID \(chatSession.id) and \(chatSession.messages.count) messages")

            // Check if a chat with the same ID already exists
            if let existingIndex = chatHistory.firstIndex(where: { $0.id == chatSession.id }) {
                // Replace the existing chat
                chatHistory[existingIndex] = chatSession
                print("handleNewChat: Updated existing chat in history: \(chatSession.title)")
            } else {
                // Add to the beginning of the array
                chatHistory.insert(chatSession, at: 0)
                print("handleNewChat: Added new chat to history: \(chatSession.title)")
            }

            // Save the updated chat history
            saveChatHistory()
            print("handleNewChat: Saved updated chat history with \(chatHistory.count) chats")
        } else {
            print("handleNewChat: Error - notification object is not a ChatSession")
        }
    }

    func deleteChats(at indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)
        saveChatHistory()
        print("Deleted chat(s) from history")
    }

    // Add a chat directly to history
    func addChat(_ chatSession: ChatSession) {
        print("addChat: Adding chat session with ID \(chatSession.id) and \(chatSession.messages.count) messages")

        // Check if a chat with the same ID already exists
        if let existingIndex = chatHistory.firstIndex(where: { $0.id == chatSession.id }) {
            // Replace the existing chat
            chatHistory[existingIndex] = chatSession
            print("addChat: Updated existing chat in history: \(chatSession.title)")
        } else {
            // Add to the beginning of the array
            chatHistory.insert(chatSession, at: 0)
            print("addChat: Added new chat to history: \(chatSession.title)")
        }

        // Save the updated chat history
        saveChatHistory()
        print("addChat: Saved updated chat history with \(chatHistory.count) chats")
    }
}

// Encodable version of ChatSession for persistence
struct ChatSessionData: Codable {
    let id: UUID
    let title: String
    let lastMessage: String
    let date: Date
    let messages: [MessageData]
}

// Encodable version of Message for persistence
struct MessageData: Codable {
    let id: UUID
    let content: String
    let role: String
    let timestamp: Date
    let providerType: String
    let model: String
}

struct ChatSession: Identifiable {
    let id: UUID
    let title: String
    let lastMessage: String
    let date: Date
    let messages: [Message] // Store the messages for this chat session

    init(id: UUID = UUID(), title: String, lastMessage: String, date: Date, messages: [Message]) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.date = date
        self.messages = messages
    }
}