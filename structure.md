# Router Chat AI - App Structure and Functionality

## Overview

Router Chat AI is a SwiftUI-based iOS application that provides a unified interface for interacting with various AI models from different providers (OpenAI, Anthropic, and OpenRouter). The app allows users to manage API keys, select models, and have conversations with AI models while maintaining chat history.

## App Architecture

The app follows a modern SwiftUI architecture with:

- **SwiftData** for persistence of messages and chat history
- **MVVM pattern** (Model-View-ViewModel) for separation of concerns
- **Environment-based theming** for consistent dark/light mode support
- **Protocol-oriented networking** for flexible API interactions
- **Secure storage** for API keys using Keychain

## Entry Points and Navigation

- **Router_Chat_AIApp.swift**: Main app entry point that sets up the SwiftData container and determines whether to show onboarding or the main app based on whether the user has completed onboarding. Also configures global performance optimizations.
- **ContentView.swift**: Simple wrapper around MainView that provides the model context and theme environment.
- **MainView.swift**: Main view with custom top navigation bar and content switching between chat, chat history, and settings views.

## Key Files and Their Functionality

### Models

- **Provider.swift**: Enum defining the supported AI providers (OpenAI, Anthropic, OpenRouter) with their available models and keychain keys. Contains logic for routing models with provider prefixes (e.g., "meta-llama/llama-4-scout:free") through OpenRouter.
- **Message.swift**: SwiftData model for chat messages with properties for content, role, timestamp, provider, and model. Uses a computed property for the Provider enum since enums aren't directly persistable in SwiftData.
- **MessageRole.swift**: Enum defining message roles (user, assistant) for chat interactions.

### Views

#### Main Navigation and Structure
- **MainView.swift**: Main view with custom top navigation bar that includes:
  - History button (clock icon) for accessing chat history
  - New chat button (plus icon) for starting a new conversation
  - Current model name display for showing and selecting models
  - Settings button (gear icon) for accessing app settings
- **TopNavigationBar.swift**: Custom navigation bar component used in MainView

#### Chat Functionality
- **ChatView.swift**: Primary chat interface where users interact with AI models. Features include:
  - Message list with user and AI messages
  - Text input area with attachment options
  - Streaming text display for AI responses
  - Support for photos and document attachments
  - Keyboard dismissal on outside tap/swipe
- **ChatHistoryView.swift**: Displays saved chat sessions with titles, previews, and timestamps. Allows users to select a chat to continue or delete chats with swipe actions.
- **ModelSelectorView.swift**: Interface for selecting AI providers and models, organized by provider with a searchable list.

#### Settings and Onboarding
- **SettingsView.swift**: Settings interface with sections for:
  - API key management for each provider
  - Appearance settings (dark/light mode)
  - Navigation options
  - App information
- **OnboardingView.swift**: First-time user experience with introduction to app features and API key setup.
- **OnboardingPageView.swift**: Individual pages within the onboarding flow.
- **APIKeyFormView.swift**: Form for entering and managing API keys during onboarding or from settings.

#### UI Components
- **MessageBubble.swift**: Custom chat bubble component for displaying messages.
- **LoadingIndicator.swift**: Animated loading indicator for async operations.
- **AttachmentView.swift**: Component for displaying attached photos or documents.

### ViewModels

- **ChatViewModel.swift**: Manages chat state and interactions with AI services, including:
  - Message list management
  - API client initialization and selection
  - Message sending and receiving
  - Streaming text handling
  - Attachment processing
- **ChatHistoryViewModel.swift**: Handles chat history operations:
  - Loading saved chats
  - Saving new chats
  - Deleting chats
  - Chat session data conversion
- **SettingsViewModel.swift**: Manages settings state and operations:
  - API key loading and saving
  - Theme preference management

### Services

- **AIClient.swift**: Protocol defining the interface for AI service providers with methods for sending messages and streaming responses.
- **OpenAIClient.swift**: Implementation for OpenAI API with support for both regular and streaming requests.
- **AnthropicClient.swift**: Implementation for Anthropic API with Claude model support.
- **OpenRouterClient.swift**: Implementation for OpenRouter API, which provides access to multiple AI models from different providers.
- **SecureStorage.swift**: Keychain wrapper for secure API key storage with methods for saving, retrieving, and deleting keys.
- **HapticFeedbackManager.swift**: Manages haptic feedback with performance optimizations to reduce battery impact.

### Theme System

- **ColorTheme.swift**: Defines color themes for the app with:
  - Light and dark mode color sets
  - Environment-based theme injection
  - Custom view modifier for applying themes
  - Gradient colors for backgrounds and overlays

### Extensions and Utilities

- **UIKit+Extensions.swift**: Extensions for UIKit classes to improve performance:
  - Keyboard optimization utilities
  - Haptic feedback management
  - Keyboard dismissal helpers
- **Date+Extensions.swift**: Date formatting utilities for chat timestamps.
- **String+Extensions.swift**: String manipulation helpers for message processing.

## Navigation Flow

1. **App Launch**:
   - If first launch: OnboardingView → APIKeyFormView → MainView
   - If returning user: MainView

2. **MainView**:
   - Top navigation bar with:
     - History button: Switch to ChatHistoryView
     - New chat button: Start a new chat in ChatView
     - Model name: Open ModelSelectorView
     - Settings button: Switch to SettingsView

3. **ChatHistoryView**:
   - Tapping a chat: Switches to ChatView with the selected chat
   - Swipe to delete chats

4. **ChatView**:
   - Back button: ChatView → ChatHistoryView
   - "+" button: Starts a new chat (clears current chat)
   - Attachment button: Opens menu for photos or documents
   - Mic button: Voice input (if implemented)
   - Send button: Sends message to selected AI model

## Theme System

The app uses a custom theme system with:
- Light and dark mode support
- Environment-based theme injection
- Consistent colors throughout the app
- Gradient backgrounds for visual depth

## Key Features

1. **Multi-provider support**: OpenAI, Anthropic, and OpenRouter with intelligent routing based on model format
2. **Secure API key storage**: Keys stored in Keychain
3. **Chat history**: Save and revisit past conversations
4. **Model selection**: Choose from various AI models
5. **Attachment support**: Photos and documents
6. **Dark/light mode**: Customizable appearance
7. **Onboarding**: Guided setup experience
8. **Streaming responses**: Real-time AI responses with token-by-token display

## Data Flow

1. **User Input**: User enters text or attaches media in ChatView
2. **ViewModel Processing**: ChatViewModel processes input and prepares API request
3. **API Request**: Appropriate AIClient implementation sends request to selected provider
4. **Response Handling**: Response is processed and added to message list
5. **Persistence**: Messages are saved to SwiftData store
6. **UI Update**: ChatView updates to display new messages

## Performance Optimizations

- Background thread processing for JSON serialization/deserialization
- Optimized keyboard handling
- Efficient haptic feedback management
- Lazy loading of chat history
- Streaming text display for faster perceived response time