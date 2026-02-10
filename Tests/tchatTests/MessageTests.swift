import XCTest
@testable import tchat

final class MessageTests: XCTestCase {
    
    func testMessageEncoding() throws {
        let message = Message.chat(username: "Alice", content: "Hello!")
        let data = try message.encode()
        
        // Should have length prefix (4 bytes) + JSON data
        XCTAssertGreaterThan(data.count, 4)
        
        // First 4 bytes should be length
        let lengthBytes = data.prefix(4)
        let length = lengthBytes.withUnsafeBytes { bytes in
            bytes.load(as: UInt32.self).bigEndian
        }
        
        // Length should match remaining data
        XCTAssertEqual(Int(length), data.count - 4)
    }
    
    func testMessageDecoding() throws {
        let original = Message.chat(username: "Bob", content: "Test message")
        let encoded = try original.encode()
        
        // Extract message from buffer
        let extracted = MessageProtocol.extractMessage(from: encoded)
        XCTAssertNotNil(extracted)
        
        let decoded = try Message.decode(from: extracted!.message)
        
        XCTAssertEqual(decoded.type, .chat)
        XCTAssertEqual(decoded.username, "Bob")
        XCTAssertEqual(decoded.content, "Test message")
    }
    
    func testMessageTypes() throws {
        let joinMsg = Message.join(username: "Alice")
        XCTAssertEqual(joinMsg.type, .join)
        XCTAssertEqual(joinMsg.username, "Alice")
        
        let chatMsg = Message.chat(username: "Bob", content: "Hi")
        XCTAssertEqual(chatMsg.type, .chat)
        XCTAssertEqual(chatMsg.content, "Hi")
        
        let leaveMsg = Message.leave(username: "Charlie")
        XCTAssertEqual(leaveMsg.type, .leave)
    }
    
    func testIncompletMessageExtraction() {
        // Create a buffer with only 2 bytes (needs 4 for length)
        let incompleteBuffer = Data([0x00, 0x01])
        let result = MessageProtocol.extractMessage(from: incompleteBuffer)
        XCTAssertNil(result)
    }
    
    func testMessageTooLarge() {
        // Create message with very large content
        let largeContent = String(repeating: "x", count: MessageProtocol.maxMessageSize + 1000)
        let message = Message.chat(username: "Alice", content: largeContent)
        
        XCTAssertThrowsError(try message.encode()) { error in
            guard case ChatError.messageTooLarge = error else {
                XCTFail("Expected messageTooLarge error")
                return
            }
        }
    }
}
