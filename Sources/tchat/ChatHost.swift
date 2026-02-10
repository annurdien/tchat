import Foundation

actor ChatHost {
    private let config: Configuration
    private var server: ChatServer?
    private var client: ChatClient?
    
    init(port: UInt16) {
        self.config = .with(port: port)
    }
    
    func start() async throws {
        print("Starting tchat in host mode on port \(config.server.port)...")
        
        
        let server = ChatServer(config: config.server)
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
