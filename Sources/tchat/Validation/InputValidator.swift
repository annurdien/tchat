import Foundation

actor InputValidator {
    private let config: ValidationConfig
    
    struct ValidationConfig {
        var minUsernameLength: Int = 3
        var maxUsernameLength: Int = 20
        var maxMessageLength: Int = 2000
        var allowedUsernameChars: CharacterSet = {
            var chars = CharacterSet.alphanumerics
            chars.insert(charactersIn: "_-")
            return chars
        }()
    }
    
    init(config: ValidationConfig = ValidationConfig()) {
        self.config = config
    }
    
    func validateUsername(_ username: String) throws {
        
        guard username.count >= config.minUsernameLength else {
            throw ChatError.invalidConfiguration(
                "Username must be at least \(config.minUsernameLength) characters"
            )
        }
        
        guard username.count <= config.maxUsernameLength else {
            throw ChatError.invalidConfiguration(
                "Username must be at most \(config.maxUsernameLength) characters"
            )
        }
        
        
        let usernameChars = CharacterSet(charactersIn: username)
        guard config.allowedUsernameChars.isSuperset(of: usernameChars) else {
            throw ChatError.invalidConfiguration(
                "Username can only contain letters, numbers, underscore, and hyphen"
            )
        }
        
        
        guard let firstChar = username.first, firstChar.isLetter || firstChar.isNumber else {
            throw ChatError.invalidConfiguration(
                "Username must start with a letter or number"
            )
        }
    }
    
    func validateMessage(_ content: String) throws {
        
        guard content.count <= config.maxMessageLength else {
            throw ChatError.messageTooLarge(
                size: content.count,
                max: config.maxMessageLength
            )
        }
        
        
        for char in content {
            if char.isASCII && char.asciiValue! < 32 && char != "\n" && char != "\t" {
                throw ChatError.invalidMessage
            }
        }
    }
    
    func sanitize(_ input: String) -> String {
        
        let sanitized = input.filter { char in
            if char == "\n" || char == "\t" {
                return true
            }
            if char.isASCII, let ascii = char.asciiValue, ascii < 32 {
                return false
            }
            return true
        }
        
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw ChatError.invalidConfiguration(
                "Password must be at least 6 characters"
            )
        }
        
        guard password.count <= 128 else {
            throw ChatError.invalidConfiguration(
                "Password must be at most 128 characters"
            )
        }
    }
}
