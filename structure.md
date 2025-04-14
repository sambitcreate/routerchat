# Router Chat AI - App Structure and Functionality

## Overview

Router Chat AI is a SwiftUI-based iOS application that provides a unified interface for interacting with various AI models from different providers (OpenAI, Anthropic, and OpenRouter). The app allows users to manage API keys, select models, and have conversations with AI models.

## App Architecture

The app follows a modern SwiftUI architecture with:

- **SwiftData** for persistence
- **MVVM pattern** (Model-View-ViewModel)
- **Environment-based theming** for dark/light mode support
- **Protocol-oriented networking** for API interactions
- **Secure storage** for API keys using Keychain

## Entry Points and Navigation

- **Router_Chat_AIApp.swift**: Main app entry point that sets up the SwiftData container and determines whether to show onboarding or the main app
- **MainTabView.swift**: Tab-based navigation with three main sections (History, Chat, Settings)

## Key Files and Their Functionality

### Models

- **Provider.swift**: Enum defining the supported AI providers (OpenAI, Anthropic, OpenRouter) with their available models and keychain keys
- **Message.swift**: SwiftData model for chat messages with properties for content, role, timestamp, provider, and model

### Views

#### Main Navigation
- **MainTabView.swift**: Tab-based navigation with History, Chat, and Settings tabs
- **ContentView.swift**: Simple wrapper around MainTabView

#### Onboarding
- **OnboardingView.swift**: Initial onboarding experience with information pages and API key setup
- **APIKeyFormView.swift**: Form for entering API keys during onboarding

#### Chat
- **ChatView.swift**: Main chat interface for interacting with AI models
  - Displays messages
  - Allows sending new messages
  - Supports attachments (photos, documents)
  - Includes model selection
  - Has a back button to navigate to history (when navigated from ChatHistoryView)
  - Includes a "+" button to start new chats
  - Dismisses keyboard when tapping outside or swiping down
- **ChatMessageView.swift**: Individual message bubble UI component

#### Chat History
- **ChatHistoryView.swift**: Displays a list of past conversations
  - Shows chat titles and previews
  - Allows navigation to specific chats
  - Supports deleting chats
  - Has a "+" button to start new chats

#### Settings
- **SettingsView.swift**: Settings interface with:
  - API key management
  - Dark/light mode toggle
  - Onboarding reset option

### ViewModels

- **ChatViewModel.swift**: Manages chat state and interactions
  - Handles message sending/receiving
  - Manages provider/model selection
  - Handles attachments
  - Saves chats to history
- **ChatHistoryViewModel.swift**: Manages chat history
  - Loads saved chats
  - Handles adding new chats
  - Manages chat deletion
- **SettingsViewModel.swift**: Manages settings
  - Loads/saves API keys
  - Provides bindings for settings UI

### Services

- **AIClient.swift**: Protocol defining the interface for AI service providers
- **OpenAIClient.swift**: Implementation for OpenAI API
- **AnthropicClient.swift**: Implementation for Anthropic API
- **OpenRouterClient.swift**: Implementation for OpenRouter API
- **SecureStorage.swift**: Keychain wrapper for secure API key storage
- **HapticFeedbackManager.swift**: Manages haptic feedback with performance optimizations

### Theme System

- **ColorTheme.swift**: Defines color themes for the app
  - Light and dark mode color sets
  - Environment-based theme injection
  - Custom view modifier for applying themes

### Extensions

- **UIKit+Extensions.swift**: Extensions for UIKit classes to improve performance
  - Keyboard optimization utilities
  - Haptic feedback management
  - Keyboard dismissal helpers

## Navigation Flow

1. **App Launch**:
   - If first launch: OnboardingView → APIKeyFormView → MainTabView
   - If returning user: MainTabView

2. **MainTabView**:
   - Tab 1: ChatHistoryView
   - Tab 2: ChatView (new chat)
   - Tab 3: SettingsView

3. **ChatHistoryView**:
   - Tapping a chat: ChatHistoryView → ChatView (with selected chat)
   - Tapping "+" button: ChatHistoryView → ChatView (new chat)

4. **ChatView**:
   - Back button: ChatView → ChatHistoryView
   - "+" button: Starts a new chat (clears current chat)

5. **SettingsView**:
   - "Restart Onboarding" button: SettingsView → OnboardingView

## Data Flow

1. **API Keys**:
   - Entered during onboarding or in settings
   - Stored securely in Keychain via SecureStorage
   - Retrieved when initializing AI clients

2. **Messages**:
   - Created in ChatViewModel
   - Stored in SwiftData via ModelContext
   - Displayed in ChatView

3. **Chat History**:
   - Created when starting a new chat with existing messages
   - Managed by ChatHistoryViewModel
   - Displayed in ChatHistoryView

## Theme System

The app uses a custom theme system with:
- Light and dark mode support
- Environment-based theme injection
- Consistent colors throughout the app
- Gradient backgrounds for visual depth

## Key Features

1. **Multi-provider support**: OpenAI, Anthropic, and OpenRouter
2. **Secure API key storage**: Keys stored in Keychain
3. **Chat history**: Save and revisit past conversations
4. **Model selection**: Choose from various AI models
5. **Attachment support**: Photos and documents
6. **Dark/light mode**: Customizable appearance
7. **Onboarding**: Guided setup experience

## UI Components

1. **Chat interface**: Message bubbles, input field, attachment options
2. **History list**: Chat previews with titles and timestamps
3. **Settings panels**: API key fields, appearance toggles
4. **Onboarding carousel**: Information pages and setup form
5. **Tab bar**: Navigation between main app sections
