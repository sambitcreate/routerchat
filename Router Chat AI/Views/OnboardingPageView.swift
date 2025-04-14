import SwiftUI

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    let bgColor: Color
    @State private var appeared = false
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundStyle(theme.primaryText)

            // Modern gradient card
            VStack(spacing: 24) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.secondaryBackground,
                                theme.tertiaryBackground
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.primaryText.opacity(0.2),
                                        .clear,
                                        theme.primaryText.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            Spacer()
        }
        .padding()
        .background(bgColor == .clear ? theme.background : bgColor)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
