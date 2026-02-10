import Foundation
import CryptoKit

/// Manages user authentication and token validation
actor AuthManager {
    private var accounts: [String: UserAccount] = [:]
    private var tokens: [String: AuthToken] = [:]
    private let pepper: String = "tchat-secret-pepper-2024"
    
    /// Register a new user account
    func register(username: String, password: String) async throws -> AuthToken {
        guard accounts[username] == nil else {
            throw ChatError.duplicateUsername(username)
        }
        
        let passwordHash = hashPassword(password)
        
        let account = UserAccount(username: username, passwordHash: passwordHash)
        accounts[username] = account
        
        let token = AuthToken.generate(for: account.id)
        tokens[token.token] = token
        
        return token
    }
    
    /// Login with existing credentials
    func login(username: String, password: String) async throws -> AuthToken {
        guard let account = accounts[username] else {
            throw ChatError.authenticationFailed
        }
        
        guard verifyPassword(password, hash: account.passwordHash) else {
            throw ChatError.authenticationFailed
        }
        
        let token = AuthToken.generate(for: account.id)
        tokens[token.token] = token
        
        return token
    }
    
    /// Validate a token
    func validateToken(_ tokenString: String) async -> AuthToken? {
        guard let token = tokens[tokenString], !token.isExpired else {
            return nil
        }
        return token
    }
    
    /// Get username for a user ID
    func getUsername(for userId: UUID) async -> String? {
        accounts.values.first { $0.id == userId }?.username
    }
    
    /// Logout (invalidate token)
    func logout(token: String) async {
        tokens.removeValue(forKey: token)
    }
    
    /// Hash a password using SHA256 with salt and pepper
    private func hashPassword(_ password: String) -> String {
        let salt = UUID().uuidString
        let combined = salt + password + pepper
        let hash = SHA256.hash(data: Data(combined.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(salt):\(hashString)"
    }
    
    /// Verify a password against a hash
    private func verifyPassword(_ password: String, hash: String) -> Bool {
        let components = hash.split(separator: ":")
        guard components.count == 2 else { return false }
        
        let salt = String(components[0])
        let storedHash = String(components[1])
        
        let combined = salt + password + pepper
        let computedHash = SHA256.hash(data: Data(combined.utf8))
        let computedHashString = computedHash.compactMap { String(format: "%02x", $0) }.joined()
        
        return computedHashString == storedHash
    }
    
    /// Get account count (for testing)
    func getAccountCount() async -> Int {
        accounts.count
    }
}
