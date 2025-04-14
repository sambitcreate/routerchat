import SwiftUI

struct ChatHistoryView: View {
    @Environment(\.colorTheme) private var theme
    @StateObject private var viewModel = ChatHistoryViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.chatHistory) { chat in
                    NavigationLink(destination: ChatView()) {
                        VStack(alignment: .leading) {
                            Text(chat.title)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(theme.primaryText)
                            Text(chat.lastMessage)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteChats(at: indexSet)
                }
            }
            .navigationTitle("Chat History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ChatView()) {
                        Image(systemName: "plus")
                            .foregroundStyle(theme.accentColor)
                    }
                }
            }
        }
    }
}