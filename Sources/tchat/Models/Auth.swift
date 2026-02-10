import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

struct Credentials: Codable, Sendable {
    let username: String
    let password: String
}

struct AuthToken: Sendable {
    let token: String
    let userId: UUID
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    static func generate(for userId: UUID) -> AuthToken {
        let token = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60)
        return AuthToken(token: token, userId: userId, expiresAt: expiresAt)
    }
}

struct UserAccount: Sendable {
    let id: UUID
    let username: String
    let passwordHash: String
    let createdAt: Date
    
    init(username: String, passwordHash: String) {
        self.id = UUID()
        self.username = username
        self.passwordHash = passwordHash
        self.createdAt = Date()
    }
}

enum AuthState: Sendable {
    case unauthenticated
    case authenticated(userId: UUID, username: String)
}

extension Message {
    static func register(username: String, password: String) -> Message {
        let credentials = Credentials(username: username, password: password)
        let jsonData = try? JSONEncoder().encode(credentials)
        let content = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        return Message(type: .register, content: content)
    }
    
    static func login(username: String, password: String) -> Message {
        let credentials = Credentials(username: username, password: password)
        let jsonData = try? JSONEncoder().encode(credentials)
        let content = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        return Message(type: .login, content: content)
    }
    
    static func authenticated(username: String, token: String) -> Message {
        Message(type: .authenticated, username: username, content: token)
    }
    
    static func authFailed(reason: String) -> Message {
        Message(type: .authFailed, content: reason)
    }
}
