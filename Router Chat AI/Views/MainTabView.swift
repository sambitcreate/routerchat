import SwiftUI

struct MainTabView: View {
    @Environment(\.colorTheme) private var theme
    @State private var selectedTab: Tab = .chatHistory
    
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
                ChatView()
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
        .colorTheme(.light)
}
