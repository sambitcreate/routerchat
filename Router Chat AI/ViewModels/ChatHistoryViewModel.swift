import SwiftUI

class ChatHistoryViewModel: ObservableObject {
    @Published var chatHistory: [ChatSession] = []
    
    func deleteChats(at indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)
    }
}

struct ChatSession: Identifiable {
    let id = UUID()
    let title: String
    let lastMessage: String
    let date: Date
}