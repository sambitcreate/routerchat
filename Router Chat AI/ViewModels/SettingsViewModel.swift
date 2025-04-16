import SwiftUI

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
