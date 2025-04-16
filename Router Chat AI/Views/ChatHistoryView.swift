import SwiftUI

struct ChatHistoryView: View {
    @Environment(\.colorTheme) private var theme
    @ObservedObject var viewModel: ChatHistoryViewModel
    
    // Optional callback for when a chat is selected
    var onSelectChat: ((ChatSession) -> Void)? = nil
    
    // Initialize with a view model
    init(viewModel: ChatHistoryViewModel = ChatHistoryViewModel(), onSelectChat: ((ChatSession) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSelectChat = onSelectChat
    }
    
    var body: some View {
        ZStack {
            // Background gradient is now handled by the parent view
            
            if viewModel.chatHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                    
                    Text("No Chat History")
                        .font(.system(.title2, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    
                    Text("Your chat history will appear here")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            } else {
                List {
                    ForEach(viewModel.chatHistory) { chat in
                        Button {
                            // If callback is provided, use it
                            if let onSelectChat = onSelectChat {
                                onSelectChat(chat)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.title)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(theme.primaryText)
                                
                                HStack {
                                    Text(chat.lastMessage)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(theme.secondaryText)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(chat.date))
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(theme.secondaryText)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    if let index = viewModel.chatHistory.firstIndex(where: { $0.id == chat.id }) {
                                        viewModel.deleteChats(at: IndexSet(integer: index))
                                    }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Chat History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            print("ChatHistoryView appeared with \(viewModel.chatHistory.count) chats")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
