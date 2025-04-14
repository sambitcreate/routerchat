import SwiftUI
import SwiftData

class ChatHistoryViewModel: ObservableObject {
    @Published var chatHistory: [ChatSession] = []

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
        // In a real app, this would load from persistent storage
        // For now, we'll just use sample data
        chatHistory = [
            ChatSession(title: "Sample Chat 1", lastMessage: "This is a sample chat message", date: Date(), messages: []),
            ChatSession(title: "Sample Chat 2", lastMessage: "Another sample chat", date: Date().addingTimeInterval(-3600), messages: [])
        ]
    }

    @objc private func handleNewChat(_ notification: Notification) {
        if let chatSession = notification.object as? ChatSession {
            // Add to the beginning of the array
            chatHistory.insert(chatSession, at: 0)

            // In a real app, this would save to persistent storage
        }
    }

    func deleteChats(at indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)

        // In a real app, this would update persistent storage
    }
}

struct ChatSession: Identifiable {
    let id = UUID()
    let title: String
    let lastMessage: String
    let date: Date
    let messages: [Message] // Store the messages for this chat session
}