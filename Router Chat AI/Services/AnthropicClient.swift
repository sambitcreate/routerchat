import Foundation

class AnthropicClient: AIClient {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01" // This is the older API version
    private let latestApiVersion = "2023-01-01" // Latest API version as of 2024

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ text: String, model: String, history: [Message]) async throws -> String {
        // Create a URLRequest with a timeout
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(latestApiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30 // 30 seconds timeout

        // Convert history to Anthropic message format
        var messages: [[String: Any]] = []

        // Add history messages
        for message in history {
            let role = message.role == .user ? "user" : "assistant"
            messages.append([
                "role": role,
                "content": message.content
            ])
        }

        // Add the current message
        messages.append(["role": "user", "content": text])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 1000,
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
                // Print detailed error information for debugging
                print("Anthropic API Error - Status Code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error Response: \(errorString)")
                }

                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Error JSON: \(errorJson)")

                    if let error = errorJson["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw AIError.apiError(message)
                    } else if let message = errorJson["error"] as? String {
                        throw AIError.apiError(message)
                    }
                }

                throw AIError.apiError("Anthropic API Error: HTTP \(httpResponse.statusCode)")
            }

            // Parse the JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                throw AIError.invalidResponse
            }

            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }

    func streamMessage(_ text: String, model: String, history: [Message], onUpdate: @escaping (String) -> Void) async throws -> String {
        // Create a URLRequest with a timeout
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(latestApiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60 // 60 seconds timeout for streaming

        // Convert history to Anthropic message format
        var messages: [[String: Any]] = []

        // Add history messages
        for message in history {
            let role = message.role == .user ? "user" : "assistant"
            messages.append([
                "role": role,
                "content": message.content
            ])
        }

        // Add the current message
        messages.append(["role": "user", "content": text])

        // Debug log the model being used
        print("AnthropicClient: Sending request with model: \(model)")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.7,
            "stream": true
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        // Create a streaming task
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        // Check for error responses
        if !(200...299).contains(httpResponse.statusCode) {
            // Try to get more detailed error information
            let errorData = try? await asyncBytes.reduce(into: Data()) { data, byte in
                data.append(byte)
            }

            if let errorData = errorData,
               let errorString = String(data: errorData, encoding: .utf8) {
                print("Anthropic Streaming Error - Status Code: \(httpResponse.statusCode)")
                print("Error Response: \(errorString)")

                if let data = errorString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw AIError.streamingError(message)
                }
            }

            throw AIError.streamingError("Anthropic API Error: HTTP \(httpResponse.statusCode)")
        }

        // Process the stream
        var fullResponse = ""

        for try await line in asyncBytes.lines {
            // Skip empty lines
            if line.isEmpty {
                continue
            }

            // Remove "data: " prefix
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))

            // Skip [DONE] message
            if jsonString == "[DONE]" {
                continue
            }

            // Parse the JSON
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {

                // Append to the full response
                fullResponse += text

                // Call the update handler
                onUpdate(fullResponse)
            }
        }

        return fullResponse
    }
}
