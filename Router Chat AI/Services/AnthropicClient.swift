import Foundation

class AnthropicClient: AIClient {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/complete"
    private let apiVersion = "2023-06-01" // Update this as needed
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ text: String, model: String) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": "\n\nHuman: \(text)\n\nAssistant:",
            "max_tokens_to_sample": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let completion = json["completion"] as? String else {
            throw AIError.invalidResponse
        }
        
        return completion.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}