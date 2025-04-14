import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var content: String
    var role: MessageRole
    var timestamp: Date
    var providerType: String  // Store as String since Provider enum isn't directly persistable
    var model: String

    // Using computed property instead of property wrapper to avoid SwiftData issues
    var provider: Provider {
        get {
            Provider(rawValue: providerType) ?? .openAI
        }
        set {
            providerType = newValue.rawValue
        }
    }

    init(id: UUID = UUID(),
         content: String,
         role: MessageRole,
         timestamp: Date = Date(),
         provider: Provider,
         model: String) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.providerType = provider.rawValue
        self.model = model
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
