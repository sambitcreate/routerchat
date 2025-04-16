import Foundation

class OpenRouterClient: AIClient {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ text: String, model: String, history: [Message]) async throws -> String {
        // Create a URLRequest with a timeout
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Router Chat AI", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Router Chat AI (contact@yourapp.com)", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 30 // 30 seconds timeout

        // Convert history to OpenRouter message format (same as OpenAI format)
        var messages: [[String: String]] = []

        // Add history messages
        for message in history {
            messages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }

        // Add the current message
        messages.append(["role": "user", "content": text])

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
                // Print detailed error information for debugging
                print("OpenRouter API Error - Status Code: \(httpResponse.statusCode)")
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

                throw AIError.apiError("OpenRouter API Error: HTTP \(httpResponse.statusCode)")
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

    func streamMessage(_ text: String, model: String, history: [Message], onUpdate: @escaping (String) -> Void) async throws -> String {
        // Create a URLRequest with a timeout
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Router Chat AI", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Router Chat AI (contact@yourapp.com)", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 60 // 60 seconds timeout for streaming

        // Convert history to OpenRouter message format (same as OpenAI format)
        var messages: [[String: String]] = []

        // Add history messages
        for message in history {
            messages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }

        // Add the current message
        messages.append(["role": "user", "content": text])

        // Debug log the model being used
        print("OpenRouterClient: Sending request with model: \(model)")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
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
                print("OpenRouter Streaming Error - Status Code: \(httpResponse.statusCode)")
                print("Error Response: \(errorString)")

                if let data = errorString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw AIError.streamingError(message)
                }
            }

            throw AIError.streamingError("OpenRouter API Error: HTTP \(httpResponse.statusCode)")
        }

        // Process the stream
        var fullResponse = ""

        for try await line in asyncBytes.lines {
            // Skip empty lines and "data: [DONE]" message
            if line.isEmpty || line == "data: [DONE]" {
                continue
            }

            // Remove "data: " prefix
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))

            // Parse the JSON
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let choice = choices.first,
               let delta = choice["delta"] as? [String: Any],
               let content = delta["content"] as? String {

                // Append to the full response
                fullResponse += content

                // Call the update handler
                onUpdate(fullResponse)
            }
        }

        return fullResponse
    }
}