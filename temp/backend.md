iOS AI Chat App - Backend

1. Architecture Overview

Design Pattern: Protocol-oriented abstraction.

Modular Backend Clients:

AIClient protocol for unified request handling.

Provider-specific implementations (OpenAIClient, AnthropicClient, etc.).

2. AIClient Protocol

protocol AIClient {
    func sendMessage(_ text: String, model: String) async throws -> String
}

3. Provider Implementations

OpenAIClient

Endpoint: https://api.openai.com/v1/chat/completions

Headers: Authorization: Bearer <apiKey>

Body: JSON with model, messages, stream

AnthropicClient

Endpoint: https://api.anthropic.com/v1/complete

Headers: Anthropic-specific auth + versioning.

Body: Prompt format based on Anthropic structure.

DeepSeekClient (example)

Endpoint and headers defined per API.

4. Request Handling

Use URLSession with async/await.

Abstract request creation + response parsing per provider.

Handle streaming using URLSession.AsyncBytes where available.

5. Local Caching Layer

Model List Caching: 24h expiry using UserDefaults.

Message History: Store locally if offline (CoreData optional).

6. Keychain Layer

SecureStorage.swift: Encapsulate keychain logic.

Read/write/delete API keys per provider.

7. Error Handling

Throw provider-specific errors.

Convert to user-friendly alerts in ViewModel.

8. Unit Testing Plan

Mock clients for AIClient.

Validate network call logic.

Test keychain read/write reliability.

9. Future Expansion

Add more providers (Mistral, Google Gemini).

Extend AIClient protocol for image/audio generation.

10. Deployment

No server required.

All keys stored locally (user-owned).


