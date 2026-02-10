import XCTest
@testable import tchat

final class ValidationTests: XCTestCase {
    
    func testValidUsername() async throws {
        let validator = InputValidator()
        
        // Valid usernames
        try await validator.validateUsername("alice")
        try await validator.validateUsername("bob123")
        try await validator.validateUsername("user_name")
        try await validator.validateUsername("user-name")
    }
    
    func testInvalidUsernameTooShort() async {
        let validator = InputValidator()
        
        do {
            try await validator.validateUsername("ab")
            XCTFail("Should throw error for short username")
        } catch {
            // Expected
        }
    }
    
    func testInvalidUsernameTooLong() async {
        let validator = InputValidator()
        
        let longUsername = String(repeating: "a", count: 25)
        do {
            try await validator.validateUsername(longUsername)
            XCTFail("Should throw error for long username")
        } catch {
            // Expected
        }
    }
    
    func testInvalidUsernameSpecialChars() async {
        let validator = InputValidator()
        
        do {
            try await validator.validateUsername("user@name")
            XCTFail("Should throw error for invalid chars")
        } catch {
            // Expected
        }
    }
    
    func testInvalidUsernameStartsWithSpecial() async {
        let validator = InputValidator()
        
        do {
            try await validator.validateUsername("_username")
            XCTFail("Should throw error for username starting with underscore")
        } catch {
            // Expected
        }
    }
    
    func testValidMessage() async throws {
        let validator = InputValidator()
        
        try await validator.validateMessage("Hello, world!")
        try await validator.validateMessage("Message with\nnewlines\nis ok")
    }
    
    func testInvalidMessageTooLong() async {
        let validator = InputValidator()
        
        let longMessage = String(repeating: "a", count: 3000)
        do {
            try await validator.validateMessage(longMessage)
            XCTFail("Should throw error for long message")
        } catch {
            // Expected
        }
    }
    
    func testSanitization() async {
        let validator = InputValidator()
        
        let dirty = "Hello\u{0007}World\u{001B}Test"
        let clean = await validator.sanitize(dirty)
        
        XCTAssertFalse(clean.contains("\u{0007}"))
        XCTAssertFalse(clean.contains("\u{001B}"))
        XCTAssertTrue(clean.contains("Hello"))
        XCTAssertTrue(clean.contains("World"))
    }
    
    func testPasswordValidation() async throws {
        let validator = InputValidator()
        
        // Valid passwords
        try await validator.validatePassword("password123")
        try await validator.validatePassword("secure_pass")
        
        // Too short
        do {
            try await validator.validatePassword("short")
            XCTFail("Should throw error for short password")
        } catch {
            // Expected
        }
    }
}
