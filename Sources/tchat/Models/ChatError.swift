import Foundation

enum ChatError: Error, LocalizedError {
    case connectionFailed(String)
    case connectionTimeout
    case disconnected
    case socketError(String)
    case bindFailed(port: UInt16)
    case listenFailed
    
    case invalidMessage
    case encodingFailed
    case decodingFailed
    case messageTooLarge(size: Int, max: Int)
    
    case invalidConfiguration(String)
    case invalidPort(UInt16)
    
    case maxConnectionsReached(max: Int)
    case duplicateUsername(String)
    case serverNotRunning
    
    case notConnected
    case authenticationFailed
    case reconnectFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .connectionTimeout:
            return "Connection timed out"
        case .disconnected:
            return "Disconnected from server"
        case .socketError(let reason):
            return "Socket error: \(reason)"
        case .bindFailed(let port):
            return "Failed to bind to port \(port)"
        case .listenFailed:
            return "Failed to listen on socket"
        case .invalidMessage:
            return "Invalid message format"
        case .encodingFailed:
            return "Failed to encode message"
        case .decodingFailed:
            return "Failed to decode message"
        case .messageTooLarge(let size, let max):
            return "Message too large: \(size) bytes (max: \(max) bytes)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .invalidPort(let port):
            return "Invalid port: \(port)"
        case .maxConnectionsReached(let max):
            return "Maximum connections reached: \(max)"
        case .duplicateUsername(let username):
            return "Username '\(username)' is already taken"
        case .serverNotRunning:
            return "Server is not running"
        case .notConnected:
            return "Not connected to server"
        case .authenticationFailed:
            return "Authentication failed"
        case .reconnectFailed:
            return "Failed to reconnect to server"
        }
    }
}
