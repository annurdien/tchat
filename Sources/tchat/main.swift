import Foundation

let arguments = CommandLine.arguments

if arguments.count < 2 {
    print("""
    tchat - Terminal-based TCP chat application
    
    Usage:
      tchat server [port]        - Start chat server (default port: 8080)
      tchat host [port]          - Start as host (server + client, default port: 8080)
      tchat client <host> [port] - Connect to chat server (default port: 8080)
    
    Examples:
      tchat server 9000
      tchat host 9000
      tchat client localhost 9000
    
    Environment Variables:
      TCHAT_PORT            - Default server port
      TCHAT_HOST            - Default bind address
      TCHAT_MAX_CONNECTIONS - Maximum concurrent connections
    """)
    exit(1)
}

let mode = arguments[1]

do {
    switch mode {
    case "server":
        let port = arguments.count > 2 ? UInt16(arguments[2]) ?? 8080 : 8080
        let config = ServerConfig(
            port: port,
            host: "0.0.0.0",
            maxConnections: 100,
            connectionTimeout: 30.0,
            readTimeout: 60.0,
            writeTimeout: 10.0
        )
        print("Starting tchat server on port \(port)...")
        let server = ChatServer(config: config)
        try await server.start()
        
    case "host":
        let port = arguments.count > 2 ? UInt16(arguments[2]) ?? 8080 : 8080
        let host = ChatHost(port: port)
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
