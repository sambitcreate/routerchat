import Foundation

enum Provider: String, Codable, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case openRouter = "OpenRouter"

    var id: String { rawValue }

    var models: [String] {
        switch self {
        case .openAI:
            return ["gpt-4", "gpt-3.5-turbo", "openai/o3-mini", "openai/gpt-4o", "openai/gpt-4o-search-preview", "openai/gpt-4o-mini-search-preview"]
        case .anthropic:
            return ["claude-2", "claude-instant", "anthropic/claude-3.7-sonnet", "anthropic/claude-3.7-sonnet:thinking", "anthropic/claude-3.5-sonnet"]
        case .openRouter:
            return [
                "openai/gpt-4-turbo-preview",
                "openai/gpt-4",
                "openai/gpt-3.5-turbo",
                "openai/gpt-4o-mini",
                "openai/o3-mini-high",
                "anthropic/claude-3-opus",
                "anthropic/claude-3-sonnet",
                "anthropic/claude-2",
                "anthropic/claude-3.7-sonnet:beta",
                "anthropic/claude-3.5-sonnet",
                "google/gemini-pro",
                "google/gemini-2.0-flash-lite-001",
                "google/gemini-2.0-flash-001",
                "google/gemini-2.5-pro-exp-03-25:free",
                "google/gemma-3-12b-it:free",
                "meta-llama/llama-2-70b-chat",
                "meta-llama/llama-4-scout:free",
                "meta-llama/llama-4-maverick:free",
                "deepseek/deepseek-v3-base:free",
                "deepseek/deepseek-r1:free",
                "deepseek/deepseek-chat:free",
                "qwen/qwq-32b:free",
                "agentica-org/deepcoder-14b-preview:free",
                "x-ai/grok-3-mini-beta",
                "nvidia/llama-3.1-nemotron-nano-8b-v1:free"
            ]
        }
    }

    var keychainKey: String {
        switch self {
        case .openAI:
            return "openai-api-key"
        case .anthropic:
            return "anthropic-api-key"
        case .openRouter:
            return "openrouter-api-key"
        }
    }
}
