import Foundation

actor ChatHost {
    private let config: Configuration
    private let requireAuth: Bool
    private var server: ChatServer?
    private var client: ChatClient?
    
    init(port: UInt16, requireAuth: Bool = false) {
        self.config = .with(port: port)
        self.requireAuth = requireAuth
    }
    
    func start() async throws {
        print("Starting tchat in host mode on port \(config.server.port)...")
        
        
        let security = SecurityConfig(requireAuth: requireAuth)
        let server = ChatServer(config: config.server, security: security)
        self.server = server
        
        Task {
            do {
                try await server.start()
            } catch {
                print("✗ Server error: \(error.localizedDescription)")
            }
        }
        
        
        try await Task.sleep(for: .milliseconds(500))
        
        
        print("Connecting to your hosted server...")
        let client = ChatClient(config: config.client)
        self.client = client
        
        try await client.run(host: "localhost", port: config.server.port)
        
        
        await server.stop()
        
        print("Host session ended.")
    }
}
