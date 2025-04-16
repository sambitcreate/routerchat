import SwiftUI

struct StreamingChatMessageView: View {
    @Environment(\.colorTheme) private var theme
    let message: Message
    let isStreaming: Bool
    let streamedText: String

    @State private var displayedText: String = ""
    @State private var opacity: Double = 0

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if isStreaming {
                    Text(streamedText)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(message.role == .user ? Color.white : theme.primaryText)
                        .padding(12)
                        .background(message.role == .user ? theme.accentColor : theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.2)) {
                                opacity = 1.0
                            }
                        }
                        .onChange(of: streamedText) { _, newValue in
                            // Create a subtle fade-in effect for new text
                            if !newValue.isEmpty {
                                // Only animate if text is actually changing
                                withAnimation(.easeIn(duration: 0.1)) {
                                    opacity = 1.0
                                }
                            }
                        }
                } else {
                    Text(message.content)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(message.role == .user ? Color.white : theme.primaryText)
                        .padding(12)
                        .background(message.role == .user ? theme.accentColor : theme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack {
        StreamingChatMessageView(
            message: Message(
                content: "Hello, how can I help you?",
                role: .assistant,
                provider: .openAI,
                model: "gpt-4"
            ),
            isStreaming: true,
            streamedText: "Hello, how can I help you?"
        )

        StreamingChatMessageView(
            message: Message(
                content: "What is the capital of France?",
                role: .user,
                provider: .openAI,
                model: "gpt-4"
            ),
            isStreaming: false,
            streamedText: ""
        )
    }
    .padding()
    .colorTheme(.light)
}
