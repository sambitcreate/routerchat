import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var aiClient: AIClient
    
    init(aiClient: AIClient) {
        self.aiClient = aiClient
    }
    
    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, role: .user)
        messages.append(userMessage)
        
        let messageToSend = inputMessage
        inputMessage = ""
        isLoading = true
        
        do {
            let response = try await aiClient.sendMessage(messageToSend, model: "gpt-4")
            let assistantMessage = Message(content: response, role: .assistant)
            messages.append(assistantMessage)
        } catch {
            print("Error: \(error.localizedDescription)")
            // Here you might want to show an error message to the user
        }
        
        isLoading = false
    }
}