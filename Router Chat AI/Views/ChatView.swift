import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showModelSelector = false
    @State private var showAttachmentMenu = false
    @FocusState private var isInputFocused: Bool

    // Track whether this view was opened from ChatHistoryView
    private var isFromChatHistory: Bool

    // Initialize with an optional chat session
    init(chatSession: ChatSession? = nil, isFromChatHistory: Bool = true) {
        // Use _viewModel to initialize the StateObject
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatSession: chatSession))
        self.isFromChatHistory = isFromChatHistory
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    theme.backgroundGradientStart,
                    theme.backgroundGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle overlay for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.overlayGradientStart,
                    theme.overlayGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Chat content
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
                                ChatMessageView(message: message)
                                    .id(message.id)
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
                }

                // Input area
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
                                if !messageText.isEmpty {
                                    viewModel.inputMessage = messageText
                                    messageText = ""
                                    Task {
                                        await viewModel.sendMessage()
                                    }
                                }
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
                        Button(action: {
                            if !messageText.isEmpty {
                                viewModel.inputMessage = messageText
                                messageText = ""
                                Task {
                                    await viewModel.sendMessage()
                                }
                            }
                        }) {
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
        }
        // Use a simpler approach for keyboard dismissal
        .contentShape(Rectangle())
        .onTapGesture(perform: {
            // Dismiss keyboard when tapping outside text field
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    showModelSelector = true
                }) {
                    HStack(spacing: 4) {
                        Text("Router Chat")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(theme.primaryText)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                    }
                    }
            }

            // Only show back button if we came from ChatHistoryView
            if isFromChatHistory {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Use dismiss() to navigate back with the standard iOS animation
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("History")
                        }
                        .foregroundStyle(theme.accentColor)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.startNewChat()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(theme.accentColor)
                }
            }
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(
                selectedProvider: $viewModel.selectedProvider,
                selectedModel: $viewModel.selectedModel
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

            // Optimize keyboard performance
            UIImpactFeedbackGenerator.disableHapticsDuringKeyboardOperations()
            UIApplication.optimizeKeyboardPerformance()
        }
    }
}

