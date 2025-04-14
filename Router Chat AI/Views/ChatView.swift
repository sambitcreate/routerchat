import SwiftUI
import PhotosUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorTheme) private var theme
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showModelSelector = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("How can I help you")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(theme.primaryText)
                            .padding(.top, 40)
                            .padding(.bottom, 20)
                        
                        // Messages will go here
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message)
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 0) {
                    Divider()
                        .background(theme.divider)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.accentColor)
                        }
                        .sheet(isPresented: $showPhotoPicker) {
                            PhotosPicker(selection: $viewModel.selectedPhoto,
                                       matching: .images) {
                                Text("Select Photo")
                            }
                        }
                        
                        TextField("Ask Away...", text: $messageText)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        Button(action: {
                            // Handle dictation
                        }) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(theme.background)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Router Chat")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Chats")
                        }
                        .foregroundStyle(theme.accentColor)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startNewChat()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(theme.accentColor)
                    }
                }
            }
        }
    }
}