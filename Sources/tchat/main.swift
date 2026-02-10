import Foundation

let arguments = CommandLine.arguments

// Parse flags
var authEnabled = false
var filteredArgs = arguments.filter { arg in
    if arg == "--auth" {
        authEnabled = true
        return false
    }
    return true
}

if filteredArgs.count < 2 {
    print("""
    tchat - Terminal-based TCP chat application
    
    Usage:
      tchat server [--auth] [port]        - Start chat server (default port: 8080)
      tchat host [--auth] [port]          - Start as host (server + client, default port: 8080)
      tchat client <host> [port] - Connect to chat server (default port: 8080)
    
    Options:
      --auth                            - Enable password authentication
    
    Examples:
      tchat server 9000
      tchat server --auth 9000
      tchat host --auth 9000
      tchat client localhost 9000
    
    Environment Variables:
      TCHAT_PORT            - Default server port
      TCHAT_HOST            - Default bind address
      TCHAT_MAX_CONNECTIONS - Maximum concurrent connections
      TCHAT_REQUIRE_AUTH    - Enable authentication (true/false)
    """)
    exit(1)
}

let mode = filteredArgs[1]

do {
    switch mode {
    case "server":
        let port = filteredArgs.count > 2 ? UInt16(filteredArgs[2]) ?? 8080 : 8080
        let config = ServerConfig(
            port: port,
            host: "0.0.0.0",
            maxConnections: 100,
            connectionTimeout: 30.0,
            readTimeout: 60.0,
            writeTimeout: 10.0
        )
        let security = SecurityConfig(requireAuth: authEnabled)
        print("Starting tchat server on port \(port)...")
        let server = ChatServer(config: config, security: security)
        try await server.start()
        
    case "host":
        let port = filteredArgs.count > 2 ? UInt16(filteredArgs[2]) ?? 8080 : 8080
        let host = ChatHost(port: port, requireAuth: authEnabled)
        try await host.start()
        
    case "client":
        guard arguments.count >= 3 else {
            print("Error: Client mode requires host and optional port")
            exit(1)
        }
        let host = arguments[2]
        let port = arguments.count > 3 ? UInt16(arguments[3]) ?? 8080 : 8080
        print("Connecting to \(host):\(port)...")
        let client = ChatClient()
        try await client.run(host: host, port: port)
        
    default:
        print("Error: Unknown mode '\(mode)'")
        exit(1)
    }
} catch {
    print("✗ Error: \(error.localizedDescription)")
    exit(1)
}
