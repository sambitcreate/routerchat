import Foundation

protocol AIClient {
    // Regular message sending (non-streaming)
    func sendMessage(_ text: String, model: String, history: [Message]) async throws -> String

    // Streaming version
    func streamMessage(_ text: String, model: String, history: [Message], onUpdate: @escaping (String) -> Void) async throws -> String
}

// Default implementation for backward compatibility
extension AIClient {
    func sendMessage(_ text: String, model: String) async throws -> String {
        // Call the new method with empty history for backward compatibility
        return try await sendMessage(text, model: model, history: [])
    }

    // Default implementation that calls the non-streaming version
    func streamMessage(_ text: String, model: String, history: [Message], onUpdate: @escaping (String) -> Void) async throws -> String {
        let response = try await sendMessage(text, model: model, history: history)
        onUpdate(response)
        return response
    }
}

enum AIError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    case streamingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .streamingError(let message):
            return "Streaming error: \(message)"
        }
    }
}