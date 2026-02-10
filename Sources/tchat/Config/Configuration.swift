import Foundation

struct ServerConfig: Codable, Sendable {
    var port: UInt16
    var host: String
    var maxConnections: Int
    var connectionTimeout: TimeInterval
    var readTimeout: TimeInterval
    var writeTimeout: TimeInterval
    
    static let `default` = ServerConfig(
        port: 8080,
        host: "0.0.0.0",
        maxConnections: 100,
        connectionTimeout: 30.0,
        readTimeout: 60.0,
        writeTimeout: 10.0
    )
}

struct ClientConfig: Codable, Sendable {
    var reconnectAttempts: Int
    var reconnectDelay: TimeInterval
    var keepaliveInterval: TimeInterval
    
    static let `default` = ClientConfig(
        reconnectAttempts: 3,
        reconnectDelay: 2.0,
        keepaliveInterval: 30.0
    )
}

struct SecurityConfig: Sendable {
    var requireAuth: Bool = false
    var maxMessageLength: Int = 2000
    var messagesPerSecond: Int = 10
    var messagesPerMinute: Int = 100
    var minUsernameLength: Int = 3
    var maxUsernameLength: Int = 20
    
    static let `default` = SecurityConfig()
}

struct Configuration: Sendable {
    var server: ServerConfig
    var client: ClientConfig
    var security: SecurityConfig
    
    static let `default` = Configuration(
        server: .default,
        client: .default,
        security: .default
    )
    
    static func load() -> Configuration {
        var config = Configuration.default
        
        if let portStr = ProcessInfo.processInfo.environment["TCHAT_PORT"],
           let port = UInt16(portStr) {
            config.server.port = port
        }
        
        if let host = ProcessInfo.processInfo.environment["TCHAT_HOST"] {
            config.server.host = host
        }
        
        if let maxStr = ProcessInfo.processInfo.environment["TCHAT_MAX_CONNECTIONS"],
           let max = Int(maxStr) {
            config.server.maxConnections = max
        }
        
        if let authStr = ProcessInfo.processInfo.environment["TCHAT_REQUIRE_AUTH"],
           authStr.lowercased() == "true" {
            config.security.requireAuth = true
        }
        
        return config
    }
    
    static func with(port: UInt16) -> Configuration {
        var config = Configuration.default
        config.server.port = port
        return config
    }
    
    static func withAuth(port: UInt16) -> Configuration {
        var config = Configuration.default
        config.server.port = port
        config.security.requireAuth = true
        return config
    }
    
    func validate() throws {
        guard server.port > 0 else {
            throw ChatError.invalidPort(server.port)
        }
        
        guard server.connectionTimeout > 0,
              server.readTimeout > 0,
              server.writeTimeout > 0 else {
            throw ChatError.invalidConfiguration("Timeouts must be positive")
        }
        
        guard server.maxConnections > 0 else {
            throw ChatError.invalidConfiguration("Max connections must be positive")
        }
        
        guard client.reconnectAttempts >= 0 else {
            throw ChatError.invalidConfiguration("Reconnect attempts must be non-negative")
        }
        
        guard security.maxMessageLength > 0 else {
            throw ChatError.invalidConfiguration("Max message length must be positive")
        }
    }
}
