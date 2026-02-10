import Foundation

struct User: Sendable {
    let id: UUID
    let username: String
    let connectedAt: Date
    
    init(id: UUID = UUID(), username: String, connectedAt: Date = Date()) {
        self.id = id
        self.username = username
        self.connectedAt = connectedAt
    }
}

extension User: Identifiable {}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
