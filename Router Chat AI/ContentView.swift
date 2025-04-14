//
//  ContentView.swift
//  Router Chat AI
//
//  Created by Sambit Biswas on 4/14/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorTheme) private var theme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var viewModel: ChatViewModel
    @State private var showingModelSelector = false
    @State private var showingSettings = false
    @State private var meshColors: [Color] = [
        Color(red: 0.1, green: 0.2, blue: 0.4),
        Color(red: 0.2, green: 0.3, blue: 0.5),
        Color(red: 0.15, green: 0.25, blue: 0.45)
    ].map { $0.opacity(0.3) }

    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: ChatViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main background with subtle gradient
                LinearGradient(
                    colors: [
                        theme.backgroundGradientStart,
                        theme.backgroundGradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Optional: Very subtle overlay for depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.overlayGradientStart,
                        theme.overlayGradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageView(message: message)
                            }
                        }
                        .padding()
                    }

                    Divider()
                        .background(theme.divider)

                    VStack(spacing: 12) {
                        Button(action: { showingModelSelector.toggle() }) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundStyle(theme.accentColor)
                                Text(viewModel.selectedModel)
                                    .lineLimit(1)
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(theme.secondaryText)
                                    .imageScale(.small)
                            }
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.cardBackground)
                            }
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 12) {
                            TextField("Type a message...", text: $viewModel.inputMessage, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .foregroundStyle(theme.primaryText)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.inputBackground)
                                }
                                .disabled(viewModel.isLoading)
                                .frame(minHeight: 45)
                                .layoutPriority(1)

                            Button(action: {
                                Task {
                                    withAnimation(.smooth(duration: 0.6)) {
                                        meshColors = [
                                            Color(red: 0.1, green: 0.2, blue: 0.4),
                                            Color(red: 0.2, green: 0.3, blue: 0.5),
                                            Color(red: 0.15, green: 0.25, blue: 0.45)
                                        ].map { $0.opacity(Double.random(in: 0.2...0.4)) }
                                    }
                                    await viewModel.sendMessage()
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(isDarkMode ? .black : .white)
                                    .padding(12)
                                    .background {
                                        Circle()
                                            .fill(theme.accentColor)
                                    }
                            }
                            .disabled(viewModel.isLoading || viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(theme.cardBackground)
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.navigationBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(action: { viewModel.clearMessages() }) {
                            Image(systemName: "trash")
                                .foregroundStyle(theme.primaryText)
                        }

                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .foregroundStyle(theme.primaryText)
                        }
                    }
                }
            }
        }
        .tint(theme.accentColor)
        .sheet(isPresented: $showingModelSelector) {
            ModelSelectorView(
                selectedProvider: $viewModel.selectedProvider,
                selectedModel: $viewModel.selectedModel
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

struct MessageView: View {
    let message: Message
    @Environment(\.colorTheme) private var theme

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundStyle(message.role == .user ? .white : theme.primaryText)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.role == .user ? theme.userMessageBackground : theme.assistantMessageBackground)
                    }

                HStack(spacing: 4) {
                    if message.role == .assistant {
                        Image(systemName: "cpu")
                            .imageScale(.small)
                            .foregroundStyle(message.role == .user ? .white.opacity(0.7) : theme.secondaryText)
                    }
                    Text("\(message.provider.rawValue) · \(message.model)")
                        .foregroundStyle(message.role == .user ? .white.opacity(0.7) : theme.secondaryText)
                }
                .font(.caption2)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct ModelSelectorView: View {
    @Binding var selectedProvider: Provider
    @Binding var selectedModel: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorTheme) private var theme

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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Message.self, configurations: config)
    return ContentView(modelContext: container.mainContext)
}
