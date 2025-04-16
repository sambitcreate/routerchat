import Foundation
import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

// Import potentially missing types (adjust if needed)
// import Models // Assuming Models are in a module/namespace
// import Services // Assuming Services are in a module/namespace

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedProvider: Provider = .openAI
    @Published var selectedModel: String = "gpt-4"

    // Track if model was manually selected
    var modelManuallySelected: Bool = false
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedDocument: URL?

    // Streaming support
    @Published var isStreaming: Bool = false
    @Published var streamedText: String = ""
    @Published var streamingMessageId: UUID?

    // Track the ID of the currently loaded chat session
    @Published var chatSessionId: UUID? = nil

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

        // Network connectivity will be checked during the API call

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

        // Create a placeholder message for streaming
        let assistantMessage = Message(
            id: UUID(),
            content: "",  // Empty content initially
            role: .assistant,
            provider: selectedProvider,
            model: selectedModel
        )

        // Set up streaming state
        isStreaming = true
        streamedText = ""
        streamingMessageId = assistantMessage.id

        // Add the message to the UI but don't persist it yet
        messages.append(assistantMessage)

        // Get conversation history (excluding the current assistant message)
        let history = messages.filter { $0.id != assistantMessage.id }

        do {
            // Debug logging for model selection
            print("Using provider: \(selectedProvider.rawValue), model: \(selectedModel)")

            // Use streaming API
            let response = try await client.streamMessage(
                messageToSend,
                model: selectedModel,
                history: history
            ) { [weak self] updatedText in
                // Update the streamed text on the main thread
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.streamedText = updatedText
                }
            }

            // Update the assistant message with the final response
            assistantMessage.content = response

            // Now persist the message to the database
            modelContext.insert(assistantMessage)

            // Reset streaming state
            isStreaming = false
            streamingMessageId = nil

            // Provide success haptic feedback when message is received
            provideFeedback(type: .success)
        } catch AIError.apiError(let message) {
            // Remove the placeholder message
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages.remove(at: index)
            }

            errorMessage = "API Error: \(message)"
            showError = true
            print("API Error: \(message)")
            provideFeedback(type: .error)
        } catch AIError.networkError(let error) {
            // Remove the placeholder message
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages.remove(at: index)
            }

            errorMessage = "Network Error: Could not connect to the server. Please check your internet connection."

            showError = true
            print("Network Error: \(error)")
            provideFeedback(type: .error)
        } catch AIError.invalidResponse {
            // Remove the placeholder message
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages.remove(at: index)
            }

            errorMessage = "Invalid Response: The server returned an unexpected response. Please try again."
            showError = true
            print("Invalid Response")
            provideFeedback(type: .error)
        } catch AIError.streamingError(let message) {
            // Remove the placeholder message
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages.remove(at: index)
            }

            errorMessage = "Streaming Error: \(message)"
            showError = true
            print("Streaming Error: \(message)")
            provideFeedback(type: .error)
        } catch {
            // Remove the placeholder message
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages.remove(at: index)
            }

            errorMessage = "Error: \(error.localizedDescription)"

            showError = true
            print("Error: \(error.localizedDescription)")
            provideFeedback(type: .error)
        }

        // Reset streaming state if there was an error
        isStreaming = false
        streamingMessageId = nil
        isLoading = false
    }

    private func provideFeedback(type: FeedbackType) {
        // No need for try-catch as playFeedback doesn't throw
        HapticFeedbackManager.shared.playFeedback(for: type)
    }

    private func getCurrentClient() -> AIClient? {
        // Check if the model has a provider prefix (like "meta-llama/llama-4-scout:free")
        if selectedModel.contains("/") {
            // Models with provider prefixes should always use OpenRouter
            print("Model contains provider prefix, using OpenRouter client")
            if openRouterClient == nil {
                print("WARNING: OpenRouter client is nil, API key may be missing")
            }
            return openRouterClient
        }

        // Otherwise use the selected provider
        switch selectedProvider {
        case .openAI:
            print("Using OpenAI client for model: \(selectedModel)")
            if openAIClient == nil {
                print("WARNING: OpenAI client is nil, API key may be missing")
            }
            return openAIClient
        case .anthropic:
            print("Using Anthropic client for model: \(selectedModel)")
            if anthropicClient == nil {
                print("WARNING: Anthropic client is nil, API key may be missing")
            }
            return anthropicClient
        case .openRouter:
            print("Using OpenRouter client for model: \(selectedModel)")
            if openRouterClient == nil {
                print("WARNING: OpenRouter client is nil, API key may be missing")
            }
            return openRouterClient
        }
    }

    func clearMessages() {
        guard let modelContext = modelContext else {
            print("Model context not set")
            messages.removeAll()
            chatSessionId = nil // Reset session ID when clearing
            return
        }

        do {
            let descriptor = FetchDescriptor<Message>()
            let existingMessages = try modelContext.fetch(descriptor)
            existingMessages.forEach { modelContext.delete($0) }
            messages.removeAll()
            chatSessionId = nil // Reset session ID when clearing
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
        clearMessages() // This will also reset chatSessionId

        // Reset provider and model to defaults if needed
        if !modelManuallySelected {
            selectedProvider = .openAI
            selectedModel = "gpt-4"
        }

        // Provide haptic feedback
        provideFeedback(type: .success)
    }

    func saveCurrentChatToHistory() {
        // Only save if we have messages
        guard !messages.isEmpty else { return }

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

        print("Saved chat to history: \(chatTitle)")
    }

    func handleSelectedPhoto() {
        // Check if we have a selected photo and model context
        guard selectedPhoto != nil, let modelContext = modelContext else {
            print("Model context not set or no photo selected")
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

    func loadChatSession(_ session: ChatSession) {
        // Clear current state before loading
        messages.removeAll()
        inputMessage = ""
        isLoading = false
        isStreaming = false
        streamedText = ""
        streamingMessageId = nil
        selectedPhoto = nil
        selectedDocument = nil
        errorMessage = nil
        showError = false

        // Load messages and ID from the session
        self.chatSessionId = session.id
        self.messages = session.messages

        // Optionally restore provider/model if stored in ChatSession
        // if let lastMessage = session.messages.last {
        //     self.selectedProvider = lastMessage.provider
        //     self.selectedModel = lastMessage.model
        //     self.modelManuallySelected = true // Assume model was selected for this session
        // }

        print("Loaded chat session: \(session.title)")
    }
}
