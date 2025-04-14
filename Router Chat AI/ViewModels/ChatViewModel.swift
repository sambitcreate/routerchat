import Foundation
import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedProvider: Provider = .openAI
    @Published var selectedModel: String = "gpt-4"
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedDocument: URL?

    private var openAIClient: OpenAIClient?
    private var anthropicClient: AnthropicClient?
    private var openRouterClient: OpenRouterClient?
    private var modelContext: ModelContext?

    init(chatSession: ChatSession? = nil) {
        loadClients()

        // If a chat session was provided, load its messages
        if let session = chatSession {
            self.messages = session.messages
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchMessages()
    }

    @Published var authError: String? = nil

    private func loadClients() {
        var hasAnyCredentials = false

        do {
            // Try to load OpenAI client
            do {
                let openAIKey = try SecureStorage.shared.getAPIKey(for: Provider.openAI.keychainKey)
                openAIClient = OpenAIClient(apiKey: openAIKey)
                hasAnyCredentials = true
                print("Successfully loaded OpenAI client")
            } catch KeychainError.notFound {
                print("OpenAI API key not found in keychain")
            } catch {
                print("Error loading OpenAI client: \(error.localizedDescription)")
            }

            // Try to load Anthropic client
            do {
                let anthropicKey = try SecureStorage.shared.getAPIKey(for: Provider.anthropic.keychainKey)
                anthropicClient = AnthropicClient(apiKey: anthropicKey)
                hasAnyCredentials = true
                print("Successfully loaded Anthropic client")
            } catch KeychainError.notFound {
                print("Anthropic API key not found in keychain")
            } catch {
                print("Error loading Anthropic client: \(error.localizedDescription)")
            }

            // Try to load OpenRouter client
            do {
                let openRouterKey = try SecureStorage.shared.getAPIKey(for: Provider.openRouter.keychainKey)
                openRouterClient = OpenRouterClient(apiKey: openRouterKey)
                hasAnyCredentials = true
                print("Successfully loaded OpenRouter client")
            } catch KeychainError.notFound {
                print("OpenRouter API key not found in keychain")
            } catch {
                print("Error loading OpenRouter client: \(error.localizedDescription)")
            }

            // Check if we have any credentials
            if !hasAnyCredentials {
                authError = "No auth credentials found. Please add at least one API key in settings."
                print("Error: No auth credentials found for any provider")
            }
        }
    }

    private func fetchMessages() {
        // If we already have messages (from a ChatSession), don't fetch from the model context
        if !messages.isEmpty {
            return
        }

        guard let modelContext = modelContext else {
            print("Model context not set")
            return
        }

        let descriptor = FetchDescriptor<Message>(sortBy: [SortDescriptor(\.timestamp)])
        do {
            messages = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching messages: \(error)")
        }
    }

    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        guard let modelContext = modelContext else {
            errorMessage = "Model context not set"
            showError = true
            print("Error: Model context not set")
            provideFeedback(type: .error)
            return
        }

        // Check if we have a client for the selected provider
        guard let client = getCurrentClient() else {
            errorMessage = authError ?? "No API key found for \(selectedProvider.rawValue). Please add your API key in settings."
            showError = true
            print("Error: \(errorMessage ?? "Unknown error")")

            // Provide error haptic feedback
            provideFeedback(type: .error)
            return
        }

        let userMessage = Message(
            content: inputMessage,
            role: .user,
            provider: selectedProvider,
            model: selectedModel
        )

        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Provide selection haptic feedback when sending message
        provideFeedback(type: .selection)

        let messageToSend = inputMessage
        inputMessage = ""
        isLoading = true

        do {
            // Use Task with timeout to prevent long-running operations
            let response = try await Task.detached(priority: .userInitiated) {
                return try await client.sendMessage(messageToSend, model: self.selectedModel)
            }.value

            let assistantMessage = Message(
                content: response,
                role: .assistant,
                provider: selectedProvider,
                model: selectedModel
            )

            // We've already checked that modelContext is not nil at the beginning of this method
            // so we can safely use it here
            modelContext.insert(assistantMessage)
            messages.append(assistantMessage)

            // Provide success haptic feedback when message is received
            provideFeedback(type: .success)
        } catch AIError.apiError(let message) {
            errorMessage = "API Error: \(message)"
            showError = true
            print("API Error: \(message)")
            provideFeedback(type: .error)
        } catch AIError.networkError(let error) {
            errorMessage = "Network Error: Could not connect to the server. Please check your internet connection."
            showError = true
            print("Network Error: \(error)")
            provideFeedback(type: .error)
        } catch AIError.invalidResponse {
            errorMessage = "Invalid Response: The server returned an unexpected response. Please try again."
            showError = true
            print("Invalid Response")
            provideFeedback(type: .error)
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            print("Error: \(error.localizedDescription)")
            provideFeedback(type: .error)
        }

        isLoading = false
    }

    private func provideFeedback(type: FeedbackType) {
        // Wrap in a try-catch to prevent haptic feedback issues from affecting the app
        do {
            HapticFeedbackManager.shared.playFeedback(for: type)
        } catch {
            print("Failed to provide haptic feedback: \(error.localizedDescription)")
            // Silently fail - haptic feedback is non-critical
        }
    }

    private func getCurrentClient() -> AIClient? {
        switch selectedProvider {
        case .openAI:
            return openAIClient
        case .anthropic:
            return anthropicClient
        case .openRouter:
            return openRouterClient
        }
    }

    func clearMessages() {
        guard let modelContext = modelContext else {
            print("Model context not set")
            messages.removeAll()
            return
        }

        do {
            let descriptor = FetchDescriptor<Message>()
            let existingMessages = try modelContext.fetch(descriptor)
            existingMessages.forEach { modelContext.delete($0) }
            messages.removeAll()
        } catch {
            print("Error clearing messages: \(error)")
        }
    }

    func startNewChat() {
        // Save current chat to history if there are messages
        if !messages.isEmpty {
            saveCurrentChatToHistory()
        }

        // Clear current messages
        clearMessages()

        // Reset provider and model to defaults if needed
        selectedProvider = .openAI
        selectedModel = "gpt-4"

        // Provide haptic feedback
        provideFeedback(type: .success)
    }

    private func saveCurrentChatToHistory() {
        // Get the first few messages to create a title and preview
        let chatTitle = messages.first?.content.prefix(30).appending(messages.count > 1 ? "..." : "") ?? "New Chat"
        let lastMessage = messages.last?.content.prefix(50).appending("...") ?? ""

        // Create a new chat session
        let chatSession = ChatSession(
            title: String(chatTitle),
            lastMessage: String(lastMessage),
            date: Date(),
            messages: messages
        )

        // Save to persistent storage (this would be implemented in ChatHistoryViewModel)
        NotificationCenter.default.post(
            name: Notification.Name("SaveChatToHistory"),
            object: chatSession
        )
    }

    func handleSelectedPhoto() {
        guard let selectedPhoto = selectedPhoto else { return }
        guard let modelContext = modelContext else {
            print("Model context not set")
            return
        }

        // Process the selected photo
        // This would typically involve loading the image and sending it to the AI
        // For now, we'll just add a placeholder message
        let userMessage = Message(
            content: "[Image Attached]",
            role: .user,
            provider: selectedProvider,
            model: selectedModel
        )

        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Reset the selected photo
        self.selectedPhoto = nil
    }

    func handleSelectedDocument(url: URL) {
        guard let modelContext = modelContext else {
            print("Model context not set")
            return
        }

        // Process the selected document
        // This would typically involve reading the document and sending its content to the AI
        // For now, we'll just add a placeholder message
        let userMessage = Message(
            content: "[Document Attached: \(url.lastPathComponent)]",
            role: .user,
            provider: selectedProvider,
            model: selectedModel
        )

        modelContext.insert(userMessage)
        messages.append(userMessage)
    }
}
