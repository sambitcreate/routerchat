import Foundation

class OpenRouterClient: AIClient {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ text: String, model: String) async throws -> String {
        // Create a URLRequest with a timeout
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Router Chat AI", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Router Chat AI (contact@yourapp.com)", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 30 // 30 seconds timeout

        let messages: [[String: String]] = [
            ["role": "user", "content": text]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7
        ]

        // Move JSON serialization to a background thread
        let jsonData = try await Task.detached(priority: .userInitiated) { () -> Data in
            return try JSONSerialization.data(withJSONObject: body)
        }.value

        request.httpBody = jsonData

        // Create a task with a timeout
        let (data, response) = try await URLSession.shared.data(for: request)

        // Process response on a background thread
        return try await Task.detached(priority: .userInitiated) { () -> String in
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            // Check for error responses
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw AIError.apiError(message)
                }
                throw AIError.invalidResponse
            }

            // Parse the JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIError.invalidResponse
            }

            return content
        }.value
    }
}