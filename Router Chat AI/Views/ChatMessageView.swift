import SwiftUI

struct ChatMessageView: View {
    @Environment(\.colorTheme) private var theme
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(message.role == .user ? Color.white : theme.primaryText)
                    .padding(12)
                    .background(message.role == .user ? theme.accentColor : theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user {
                Spacer()
            }
        }
    }
}