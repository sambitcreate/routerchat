import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath = NavigationPath()
    @State private var currentView: AppView = .chat
    @State private var chatSession: ChatSession? = nil
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var historyViewModel = ChatHistoryViewModel()

    // Enum to track the current view
    enum AppView {
        case chatHistory
        case chat
        case settings
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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

                // Main content based on current view
                VStack {
                    // Custom top navigation bar
                    TopNavigationBar(
                        currentView: $currentView,
                        chatSession: $chatSession,
                        navigationPath: $navigationPath,
                        viewModel: viewModel,
                        historyViewModel: historyViewModel
                    )

                    // Content view
                    contentView
                }
            }
            .navigationDestination(for: AppView.self) { view in
                switch view {
                case .chatHistory:
                    ChatHistoryView(viewModel: historyViewModel)
                case .chat:
                    ChatView(viewModel: viewModel, chatSession: chatSession, isFromChatHistory: false)
                case .settings:
                    SettingsView()
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch currentView {
        case .chatHistory:
            ChatHistoryView(viewModel: historyViewModel, onSelectChat: { session in
                chatSession = session
                currentView = .chat
            })
        case .chat:
            ChatView(viewModel: viewModel, chatSession: chatSession, isFromChatHistory: false)
        case .settings:
            SettingsView()
        }
    }
}

// Custom top navigation bar
struct TopNavigationBar: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Binding var currentView: MainView.AppView
    @Binding var chatSession: ChatSession?
    @Binding var navigationPath: NavigationPath
    @State private var showModelSelector = false
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var historyViewModel: ChatHistoryViewModel

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                // History button
                Button(action: {
                    withAnimation {
                        currentView = .chatHistory
                    }
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.accentColor)
                }

                // New chat button
                Button(action: {
                    // Save current chat to history if needed
                    if currentView == .chat && !viewModel.messages.isEmpty {
                        print("Saving current chat to history before starting new chat")
                        
                        // Create a new chat session
                        let chatTitle = viewModel.messages.first?.content.prefix(30).appending(viewModel.messages.count > 1 ? "..." : "") ?? "New Chat"
                        let lastMessage = viewModel.messages.last?.content.prefix(50).appending("...") ?? ""
                        
                        let chatSession = ChatSession(
                            title: String(chatTitle),
                            lastMessage: String(lastMessage),
                            date: Date(),
                            messages: viewModel.messages
                        )
                        
                        // Add directly to history view model
                        historyViewModel.addChat(chatSession)
                        print("Added chat directly to history: \(chatTitle)")
                    }

                    // Start a new chat with animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        chatSession = nil
                        currentView = .chat
                        viewModel.clearMessages()
                        print("Started new chat, cleared messages")
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                        Text("New")
                            .font(.system(.body, design: .rounded))
                    }
                    .foregroundStyle(theme.accentColor)
                }

                Spacer()

                // Model name button
                Button(action: {
                    showModelSelector = true
                }) {
                    Text(getModelDisplayName())
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                }

                Spacer()

                // Settings button
                Button(action: {
                    withAnimation {
                        currentView = .settings
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.cardBackground.opacity(0.8))
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

            // Hidden view to set model context
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    print("TopNavigationBar: appeared")
                }
        }
    }

    // Helper to get a clean display name for the model
    private func getModelDisplayName() -> String {
        let model = viewModel.selectedModel

        // If the model contains a slash, extract the part after the slash
        if model.contains("/") {
            let components = model.components(separatedBy: "/")
            if components.count > 1 {
                return components[1]
            }
        }

        return model
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Message.self])
        .colorTheme(.light)
}
