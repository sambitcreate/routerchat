import SwiftUI

struct ModelSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorTheme) private var theme
    @Binding var selectedProvider: Provider
    @Binding var selectedModel: String
    var onModelSelected: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(Provider.allCases) { provider in
                    Section(provider.rawValue) {
                        ForEach(provider.models, id: \.self) { model in
                            Button(action: {
                                // If model contains a provider prefix, always use OpenRouter
                                if model.contains("/") {
                                    selectedProvider = .openRouter
                                    print("Selected model with provider prefix: \(model), setting provider to OpenRouter")
                                } else {
                                    selectedProvider = provider
                                    print("Selected model without provider prefix: \(model), setting provider to \(provider.rawValue)")
                                }
                                selectedModel = model
                                print("Model selection complete - Provider: \(selectedProvider.rawValue), Model: \(selectedModel)")
                                onModelSelected?() // Call the callback when model is selected
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model)
                                            .foregroundStyle(theme.primaryText)
                                        Text(provider.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(theme.secondaryText)
                                    }

                                    Spacer()

                                    if selectedProvider == provider && selectedModel == model {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.accentColor)
                }
            }
        }
    }
}

#Preview {
    ModelSelectorView(
        selectedProvider: .constant(.openAI),
        selectedModel: .constant("gpt-4")
    )
    .colorTheme(.light)
}
