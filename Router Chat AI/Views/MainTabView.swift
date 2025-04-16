import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.colorTheme) private var theme
    @State private var selectedTab: Tab = .chatHistory
    @StateObject private var chatViewModel = ChatViewModel()

    enum Tab {
        case chatHistory
        case chat
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat History Tab
            NavigationStack {
                ChatHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(Tab.chatHistory)

            // Chat Tab
            NavigationStack {
                ChatView(viewModel: chatViewModel, isFromChatHistory: false)
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(Tab.chat)

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
        .tint(theme.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Message.self])
        .colorTheme(.light)
}
