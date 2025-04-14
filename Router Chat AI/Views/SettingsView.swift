import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorTheme) private var theme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // API Keys Section
                    APIKeysSection(viewModel: viewModel)

                    // Appearance Section
                    AppearanceSection(isDarkMode: $isDarkMode, hasCompletedOnboarding: $hasCompletedOnboarding, dismiss: dismiss)

                    // Made in NYC Section
                    MadeInNYCSection()
                }
                .padding(20)
            }
            .background(theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task {
                            await viewModel.saveKeys()
                            dismiss()
                        }
                    }
                    .foregroundStyle(theme.accentColor)
                    .font(.system(.body, design: .rounded))
                }
            }
        }
    }
}

// Extracted API Keys Section
struct APIKeysSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Keys")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.primaryText)

            let containerCornerRadius: CGFloat = 16

            VStack(spacing: 2) {
                ForEach(Provider.allCases) { provider in
                    APIKeySettingRow(provider: provider, apiKey: viewModel.bindingForProvider(provider))
                }
            }
            .background(theme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                    .stroke(theme.divider, lineWidth: 1)
            }
        }
    }
}

// Extracted Appearance Section
struct AppearanceSection: View {
    @Binding var isDarkMode: Bool
    @Binding var hasCompletedOnboarding: Bool
    var dismiss: DismissAction
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.primaryText)

            let containerCornerRadius: CGFloat = 16

            VStack(spacing: 2) {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .tint(theme.accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                Button("Restart Onboarding") {
                    hasCompletedOnboarding = false
                    dismiss()
                }
                .foregroundStyle(theme.primaryText)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(theme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                    .stroke(theme.divider, lineWidth: 1)
            }
        }
    }
}

// Extracted Made in NYC Section
struct MadeInNYCSection: View {
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Made in NYC")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            let containerCornerRadius: CGFloat = 16

            VStack(spacing: 2) {
                Text("Made in NYC by Sambit")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .background(theme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                    .stroke(theme.divider, lineWidth: 1)
            }
        }
    }
}

struct APIKeySettingRow: View {
    let provider: Provider
    @Binding var apiKey: String
    @State private var isSecure = true
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider.rawValue)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(theme.secondaryText)
                }
            }

            if isSecure {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .foregroundStyle(theme.primaryText)
            } else {
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .foregroundStyle(theme.primaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var openAIKey = ""
    @Published var anthropicKey = ""
    @Published var openRouterKey = ""

    init() {
        loadKeys()
    }

    private func loadKeys() {
        for provider in Provider.allCases {
            if let key = try? SecureStorage.shared.getAPIKey(for: provider.keychainKey) {
                switch provider {
                case .openAI:
                    openAIKey = key
                case .anthropic:
                    anthropicKey = key
                case .openRouter:
                    openRouterKey = key
                }
            }
        }
    }

    func bindingForProvider(_ provider: Provider) -> Binding<String> {
        switch provider {
        case .openAI:
            return Binding(
                get: { self.openAIKey },
                set: { self.openAIKey = $0 }
            )
        case .anthropic:
            return Binding(
                get: { self.anthropicKey },
                set: { self.anthropicKey = $0 }
            )
        case .openRouter:
            return Binding(
                get: { self.openRouterKey },
                set: { self.openRouterKey = $0 }
            )
        }
    }

    func saveKeys() async {
        do {
            for provider in Provider.allCases {
                let key: String
                switch provider {
                case .openAI:
                    key = openAIKey
                case .anthropic:
                    key = anthropicKey
                case .openRouter:
                    key = openRouterKey
                }

                if !key.isEmpty {
                    try SecureStorage.shared.saveAPIKey(key, for: provider.keychainKey)
                }
            }
        } catch {
            print("Error saving keys: \(error)")
        }
    }
}
