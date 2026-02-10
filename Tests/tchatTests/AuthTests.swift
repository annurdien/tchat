import XCTest
@testable import tchat

final class AuthTests: XCTestCase {
    
    func testPasswordHashing() async throws {
        let authManager = AuthManager()
        
        // Register a user
        let token = try await authManager.register(username: "alice", password: "password123")
        
        XCTAssertFalse(token.token.isEmpty)
        XCTAssertFalse(token.isExpired)
        
        // Verify account was created
        let count = await authManager.getAccountCount()
        XCTAssertEqual(count, 1)
    }
    
    func testLoginWithCorrectPassword() async throws {
        let authManager = AuthManager()
        
        // Register
        _ = try await authManager.register(username: "bob", password: "secret123")
        
        // Login with correct password
        let loginToken = try await authManager.login(username: "bob", password: "secret123")
        XCTAssertFalse(loginToken.token.isEmpty)
    }
    
    func testLoginWithIncorrectPassword() async throws {
        let authManager = AuthManager()
        
        // Register
        _ = try await authManager.register(username: "charlie", password: "correct")
        
        // Login with wrong password
        do {
            _ = try await authManager.login(username: "charlie", password: "wrong")
            XCTFail("Should have thrown authentication error")
        } catch ChatError.authenticationFailed {
            // Expected
        }
    }
    
    func testDuplicateUsername() async throws {
        let authManager = AuthManager()
        
        // Register first user
        _ = try await authManager.register(username: "duplicate", password: "pass1")
        
        // Try to register same username
        do {
            _ = try await authManager.register(username: "duplicate", password: "pass2")
            XCTFail("Should have thrown duplicate username error")
        } catch ChatError.duplicateUsername {
            // Expected
        }
    }
    
    func testTokenValidation() async throws {
        let authManager = AuthManager()
        
        // Register and get token
        let token = try await authManager.register(username: "dave", password: "pass")
        
        // Validate token
        let validated = await authManager.validateToken(token.token)
        XCTAssertNotNil(validated)
        XCTAssertEqual(validated?.userId, token.userId)
    }
    
    func testInvalidToken() async {
        let authManager = AuthManager()
        
        let validated = await authManager.validateToken("invalid-token-123")
        XCTAssertNil(validated)
    }
}
