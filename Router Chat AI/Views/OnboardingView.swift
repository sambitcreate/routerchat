import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboarding: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Welcome to Router Chat AI")) {
                    Text("Please enter your API keys to get started.")
                        .padding(.vertical)
                }
                
                ForEach(Provider.allCases) { provider in
                    Section(header: Text(provider.rawValue)) {
                        SecureField("API Key", text: viewModel.bindingForProvider(provider))
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                Section {
                    Button("Get Started") {
                        Task {
                            await viewModel.saveKeys()
                            isOnboarding = false
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
                
                Section(header: Text("How to get API Keys")) {
                    Link("OpenAI API Keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    Link("Anthropic API Keys", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                }
            }
            .navigationTitle("Setup")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

class OnboardingViewModel: ObservableObject {
    @Published var openAIKey = ""
    @Published var anthropicKey = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    var isValid: Bool {
        !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        }
    }
    
    func saveKeys() async {
        do {
            if !openAIKey.isEmpty {
                try SecureStorage.shared.saveAPIKey(openAIKey, for: Provider.openAI.keychainKey)
            }
            if !anthropicKey.isEmpty {
                try SecureStorage.shared.saveAPIKey(anthropicKey, for: Provider.anthropic.keychainKey)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}