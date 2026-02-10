import Foundation

enum MessageType: UInt8, Codable {
    case join = 1
    case leave = 2
    case chat = 3
    case userJoined = 4
    case userLeft = 5
    case error = 6
    case ping = 7
    case pong = 8
    case register = 10
    case login = 11
    case authenticated = 12
    case authFailed = 13
    case rateLimited = 14
    case authRequired = 15
}

struct Message: Codable, Sendable {
    let type: MessageType
    let username: String?
    let content: String?
    let timestamp: Date
    
    init(type: MessageType, username: String? = nil, content: String? = nil) {
        self.type = type
        self.username = username
        self.content = content
        self.timestamp = Date()
    }

    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(self)
        
        guard jsonData.count <= MessageProtocol.maxMessageSize else {
            throw ChatError.messageTooLarge(size: jsonData.count, max: MessageProtocol.maxMessageSize)
        }
        
        var length = UInt32(jsonData.count).bigEndian
        var data = Data()
        data.append(Data(bytes: &length, count: 4))
        data.append(jsonData)
        
        return data
    }
    
    static func decode(from data: Data) throws -> Message {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(Message.self, from: data)
        } catch {
            throw ChatError.decodingFailed
        }
    }
}

enum MessageProtocol {
    static let version: UInt8 = 1
    static let maxMessageSize = 1024 * 64
    static let lengthPrefixSize = 4
    
    static func extractMessage(from buffer: Data) -> (message: Data, consumed: Int)? {
        guard buffer.count >= lengthPrefixSize else {
            return nil
        }
        
        let lengthBytes = buffer.prefix(lengthPrefixSize)
        let length = lengthBytes.withUnsafeBytes { bytes in
            bytes.load(as: UInt32.self).bigEndian
        }
        
        let messageLength = Int(length)
        
        guard messageLength <= maxMessageSize else {
            return nil
        }
        
        let totalNeeded = lengthPrefixSize + messageLength
        guard buffer.count >= totalNeeded else {
            return nil
        }
        
        let messageData = buffer.subdata(in: lengthPrefixSize..<totalNeeded)
        return (messageData, totalNeeded)
    }
}

extension Message {
    static func join(username: String) -> Message {
        Message(type: .join, username: username)
    }
    
    static func leave(username: String) -> Message {
        Message(type: .leave, username: username)
    }
    
    static func chat(username: String, content: String) -> Message {
        Message(type: .chat, username: username, content: content)
    }
    
    static func userJoined(username: String) -> Message {
        Message(type: .userJoined, username: username)
    }
    
    static func userLeft(username: String) -> Message {
        Message(type: .userLeft, username: username)
    }
    
    static func error(content: String) -> Message {
        Message(type: .error, content: content)
    }
    
    static func ping() -> Message {
        Message(type: .ping)
    }
    
    static func pong() -> Message {
        Message(type: .pong)
    }
    
    static func authRequired(_ required: Bool) -> Message {
        Message(type: .authRequired, content: required ? "true" : "false")
    }
}
