import Foundation

struct User: Sendable {
    let id: UUID
    let username: String
    let connectedAt: Date
    
    init(username: String) {
        self.id = UUID()
        self.username = username
        self.connectedAt = Date()
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
