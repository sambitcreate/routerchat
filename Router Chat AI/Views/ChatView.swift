import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showModelSelector = false
    @State private var showAttachmentMenu = false
    @FocusState private var isInputFocused: Bool

    // Store initial parameters
    private let initialChatSession: ChatSession?
    private let isFromChatHistory: Bool

    // Initialize with an optional chat session AND the shared viewModel
    init(viewModel: ChatViewModel, chatSession: ChatSession? = nil, isFromChatHistory: Bool = false) {
        self.viewModel = viewModel
        self.initialChatSession = chatSession
        self.isFromChatHistory = isFromChatHistory
    }

    var body: some View {
        ZStack {
            // Background gradient is now handled by the parent view

            VStack(spacing: 0) {
                messageListView

                inputAreaView
            }
        }
        // Use a simpler approach for keyboard dismissal
        .contentShape(Rectangle())
        .onTapGesture(perform: {
            // Dismiss keyboard when tapping outside text field
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(
                selectedProvider: $viewModel.selectedProvider,
                selectedModel: $viewModel.selectedModel,
                onModelSelected: {
                    // Set the flag to indicate model was manually selected
                    viewModel.modelManuallySelected = true
                }
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                Text("Select Photo")
            }
            .onChange(of: viewModel.selectedPhoto) { _, newValue in
                if newValue != nil {
                    viewModel.handleSelectedPhoto()
                }
            }
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .text, .plainText, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.handleSelectedDocument(url: url)
            case .failure(let error):
                print("Document picker error: \(error)")
            }
        }
        .onAppear {
            // Set the model context when the view appears
            viewModel.setModelContext(modelContext)
            print("ChatView appeared, model context set for shared viewModel")

            // Add chat loading logic here
            if let session = initialChatSession {
                viewModel.loadChatSession(session)
                print("ChatView onAppear: Loading session \(session.id)")
            } else if !isFromChatHistory {
                // Only clear messages if it's a new chat (not from history)
                // Avoid clearing if returning to an existing session managed by the viewModel
                if viewModel.messages.isEmpty || viewModel.chatSessionId == nil {
                    viewModel.clearMessages()
                    print("ChatView onAppear: Clearing messages for new chat")
                }
            }

            // Optimize keyboard performance
            UIImpactFeedbackGenerator.disableHapticsDuringKeyboardOperations()
            UIApplication.optimizeKeyboardPerformance()
        }
        // Add navigation title
        .navigationTitle("Router Chat")
        .navigationBarTitleDisplayMode(.large)

        // Add alert to display errors
        .alert(viewModel.errorMessage ?? "Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Computed Views

    private var messageListView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.messages.isEmpty {
                        Text("How can I help you")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(theme.primaryText)
                            .padding(.top, 40)
                            .padding(.bottom, 20)
                    }

                    // Messages
                    ForEach(viewModel.messages) { message in
                        if viewModel.isStreaming && message.id == viewModel.streamingMessageId {
                            // Show streaming message with animation
                            StreamingChatMessageView(
                                message: message,
                                isStreaming: true,
                                streamedText: viewModel.streamedText
                            )
                            .id(message.id)
                        } else {
                            // Show regular message
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                    }

                    // Spacer at the bottom to allow scrolling past the last message
                    if !viewModel.messages.isEmpty {
                        Color.clear.frame(height: 20)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamedText) { _, _ in
                if let streamingId = viewModel.streamingMessageId {
                    withAnimation {
                        scrollProxy.scrollTo(streamingId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.divider)

            HStack(alignment: .center, spacing: 12) {
                // Attachment button
                Button(action: {
                    showAttachmentMenu = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .confirmationDialog("Add Attachment", isPresented: $showAttachmentMenu) {
                    Button("Photo") {
                        showPhotoPicker = true
                    }
                    Button("Document") {
                        showDocumentPicker = true
                    }
                    Button("Cancel", role: .cancel) {}
                }

                // Text input field - optimized for better keyboard performance
                TextField("Ask Away...", text: $messageText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(theme.primaryText)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .autocorrectionDisabled()
                    .onSubmit {
                        sendMessageIfNotEmpty()
                    }
                    // Use a higher priority transaction to ensure keyboard responsiveness
                    .transaction { transaction in
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Microphone button
                Button(action: {
                    // Handle dictation - would integrate with SFSpeechRecognizer
                }) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }

                // Send button
                Button(action: sendMessageIfNotEmpty) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .disabled(messageText.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(theme.cardBackground.opacity(0.8))
    }

    // MARK: - Helper Methods

    private func sendMessageIfNotEmpty() {
        if !messageText.isEmpty {
            viewModel.inputMessage = messageText
            messageText = ""
            Task {
                await viewModel.sendMessage()
            }
        }
    }
}

// Previews for ChatView
// ... existing code ...
