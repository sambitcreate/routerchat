import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var openAIKey = ""
    @State private var anthropicKey = ""
    @State private var openRouterKey = ""
    @State private var showingApiForm = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.colorTheme) private var theme

    private let pages = [
        OnboardingPage(
            imageName: "key.fill",
            title: "Welcome to Router Chat",
            description: "Your unified interface for all AI models. Get started by setting up your API keys."
        ),
        OnboardingPage(
            imageName: "lock.fill",
            title: "Secure by Design",
            description: "Your API keys are stored securely in the Keychain and never leave your device."
        ),
        OnboardingPage(
            imageName: "sparkles",
            title: "Multiple Models",
            description: "Access GPT-4, Claude, and many other models all in one place."
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.backgroundGradientStart,
                    theme.backgroundGradientEnd
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            imageName: pages[index].imageName,
                            title: pages[index].title,
                            description: pages[index].description,
                            bgColor: .clear
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? theme.primaryText : theme.primaryText.opacity(0.3))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, 24)

                Button(action: {
                    withAnimation {
                        showingApiForm = true
                    }
                }) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.background == .white ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.accentColor)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingApiForm) {
            NavigationStack {
                APIKeyFormView(
                    openAIKey: $openAIKey,
                    anthropicKey: $anthropicKey,
                    openRouterKey: $openRouterKey,
                    onComplete: {
                        hasCompletedOnboarding = true
                    }
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct APIKeyFormView: View {
    @Binding var openAIKey: String
    @Binding var anthropicKey: String
    @Binding var openRouterKey: String
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Setup Your API Keys")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .padding(.top, 20)

                VStack(spacing: 20) {
                    APIKeyField(
                        title: "OpenAI",
                        placeholder: "sk-...",
                        text: $openAIKey
                    )

                    APIKeyField(
                        title: "Anthropic",
                        placeholder: "sk-ant-...",
                        text: $anthropicKey
                    )

                    APIKeyField(
                        title: "OpenRouter",
                        placeholder: "sk-or-...",
                        text: $openRouterKey
                    )
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.secondaryBackground)
                }

                Button(action: {
                    onComplete()
                    dismiss()
                }) {
                    Text("Complete Setup")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.background == .white ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.accentColor)
                        }
                }
                .disabled(openAIKey.isEmpty && anthropicKey.isEmpty && openRouterKey.isEmpty)
                .opacity(openAIKey.isEmpty && anthropicKey.isEmpty && openRouterKey.isEmpty ? 0.5 : 1)
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.background)
    }
}

struct APIKeyField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)

            HStack {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundStyle(theme.primaryText)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundStyle(theme.primaryText)
                }

                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.tertiaryBackground)
            }
        }
    }
}

struct OnboardingPage {
    let imageName: String
    let title: String
    let description: String
}
