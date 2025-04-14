import Foundation

protocol AIClient {
    func sendMessage(_ text: String, model: String) async throws -> String
}

enum AIError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}