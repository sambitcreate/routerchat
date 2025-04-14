import SwiftUI

struct ModelSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorTheme) private var theme
    @Binding var selectedProvider: Provider
    @Binding var selectedModel: String
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Provider.allCases) { provider in
                    Section(provider.rawValue) {
                        ForEach(provider.models, id: \.self) { model in
                            Button(action: {
                                selectedProvider = provider
                                selectedModel = model
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
