import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

actor ChatServer {
    private let config: ServerConfig
    private let security: SecurityConfig
    private let authManager: AuthManager
    private var users: [UUID: User] = [:]
    private var connections: [UUID: ConnectionHandler] = [:]
    private var clientTasks: [UUID: Task<Void, Never>] = [:]
    private var isRunning = false
    private var serverSocket: Int32 = -1
    
    init(config: ServerConfig = .default, security: SecurityConfig = .default) {
        self.config = config
        self.security = security
        self.authManager = AuthManager()
    }
    
    func start() async throws {
        guard !isRunning else {
            throw ChatError.invalidConfiguration("Server is already running")
        }
        
        #if canImport(Darwin)
        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        #else
        serverSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #endif
        
        guard serverSocket >= 0 else {
            throw ChatError.socketError("Failed to create socket")
        }
        
        var flags = fcntl(serverSocket, F_GETFL, 0)
        flags |= O_NONBLOCK
        fcntl(serverSocket, F_SETFL, flags)
        
        var reuseAddr: Int32 = 1
        let optResult = setsockopt(
            serverSocket,
            SOL_SOCKET,
            SO_REUSEADDR,
            &reuseAddr,
            socklen_t(MemoryLayout<Int32>.size)
        )
        
        if optResult < 0 {
            print("Warning: Failed to set SO_REUSEADDR option")
        }
        
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = config.port.bigEndian
        serverAddress.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        let bindResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult >= 0 else {
            close(serverSocket)
            throw ChatError.bindFailed(port: config.port)
        }
        
        guard listen(serverSocket, 5) >= 0 else {
            close(serverSocket)
            throw ChatError.listenFailed
        }
        
        isRunning = true
        let authStatus = security.requireAuth ? "with authentication" : "without authentication"
        print("✓ Server is listening on port \(config.port) (\(authStatus))")
        print("Waiting for clients to connect...")
        
        await acceptConnections()
    }
    
    private func acceptConnections() async {
        while isRunning {
            let clientSocket = await Task {
                var clientAddress = sockaddr_in()
                var clientAddressLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                
                return withUnsafeMutablePointer(to: &clientAddress) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        accept(serverSocket, $0, &clientAddressLen)
                    }
                }
            }.value
            
            guard clientSocket >= 0 else {
                if isRunning {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                continue
            }
            
            var flags = fcntl(clientSocket, F_GETFL, 0)
            flags |= O_NONBLOCK
            fcntl(clientSocket, F_SETFL, flags)
            
            if connections.count >= config.maxConnections {
                print("⚠️ Max connections reached, rejecting client")
                close(clientSocket)
                continue
            }
            
            print("✓ Client connected from socket \(clientSocket)")
            
            let userId = UUID()
            let task = Task {
                await handleClient(socket: clientSocket, userId: userId)
            }
            clientTasks[userId] = task
        }
    }
    
    private func handleClient(socket: Int32, userId: UUID) async {
        let handler = ConnectionHandler(socket: socket, server: self, userId: userId, security: security, authManager: authManager)
        
        do {
            try await handler.run()
        } catch {
            print("✗ Client error: \(error.localizedDescription)")
        }
        
        await removeConnection(userId: userId)
        clientTasks.removeValue(forKey: userId)
    }
    
    func registerUser(_ user: User, handler: ConnectionHandler) async throws {
        if users.values.contains(where: { $0.username == user.username }) {
            throw ChatError.duplicateUsername(user.username)
        }
        
        users[user.id] = user
        connections[user.id] = handler
        
        print("✓ User '\(user.username)' joined the chat")
        
        let joinMsg = Message.userJoined(username: user.username)
        await broadcast(joinMsg, excluding: user.id)
    }
    
    func broadcast(_ message: Message, excluding userId: UUID? = nil) async {
        let targetConnections = connections.filter { $0.key != userId }
        
        await withTaskGroup(of: Void.self) { group in
            for (_, handler) in targetConnections {
                group.addTask {
                    do {
                        try await handler.send(message)
                    } catch {
                    }
                }
            }
        }
    }
    
    func removeConnection(userId: UUID) async {
        guard let user = users.removeValue(forKey: userId) else {
            return
        }
        
        connections.removeValue(forKey: userId)
        
        print("✓ User '\(user.username)' left the chat")
        
        let leaveMsg = Message.userLeft(username: user.username)
        await broadcast(leaveMsg, excluding: userId)
    }
    
    func stop() async {
        isRunning = false
        
        for (userId, _) in connections {
            await removeConnection(userId: userId)
        }
        
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        
        print("✓ Server stopped")
    }
}

actor ConnectionHandler {
    private let socket: Int32
    private weak var server: ChatServer?
    let userId: UUID
    private var user: User?
    private var buffer = Data()
    private let security: SecurityConfig
    private let authManager: AuthManager
    private var authToken: String?
    
    init(socket: Int32, server: ChatServer, userId: UUID, security: SecurityConfig, authManager: AuthManager) {
        self.socket = socket
        self.server = server
        self.userId = userId
        self.security = security
        self.authManager = authManager
    }
    
    func run() async throws {
        defer {
            close(socket)
        }
        
        // Send auth mode to client
        let authMsg = Message.authRequired(security.requireAuth)
        try await send(authMsg)
        
        // Handle authentication if required
        if security.requireAuth {
            try await handleAuthentication()
        }
        
        // Proceed with username and chat
        let welcomeMsg = Message(type: .chat, content: "Welcome to tchat! Please enter your username: ")
        try await send(welcomeMsg)
        
        guard let usernameMsg = try await readMessage() else {
            throw ChatError.disconnected
        }
        
        guard let username = usernameMsg.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty else {
            throw ChatError.invalidMessage
        }
        
        let user = User(id: userId, username: username, connectedAt: Date())
        self.user = user
        
        try await server?.registerUser(user, handler: self)
        
        let confirmMsg = Message(type: .chat, content: "You are now connected as '\(username)'. Start chatting!\n")
        try await send(confirmMsg)
        
        while true {
            guard let message = try await readMessage() else {
                break
            }
            
            if let content = message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty {
                let chatMsg = Message.chat(username: username, content: content)
                await server?.broadcast(chatMsg, excluding: userId)
            }
        }
    }
    
    private func handleAuthentication() async throws {
        while true {
            guard let message = try await readMessage() else {
                throw ChatError.disconnected
            }
            
            switch message.type {
            case .register:
                guard let content = message.content,
                      let credentials = try? JSONDecoder().decode(Credentials.self, from: Data(content.utf8)) else {
                    let errorMsg = Message.authFailed(reason: "Invalid credentials format")
                    try await send(errorMsg)
                    continue
                }
                
                do {
                    let token = try await authManager.register(username: credentials.username, password: credentials.password)
                    authToken = token.token
                    let successMsg = Message.authenticated(username: credentials.username, token: token.token)
                    try await send(successMsg)
                    return
                } catch {
                    let errorMsg = Message.authFailed(reason: error.localizedDescription)
                    try await send(errorMsg)
                }
                
            case .login:
                guard let content = message.content,
                      let credentials = try? JSONDecoder().decode(Credentials.self, from: Data(content.utf8)) else {
                    let errorMsg = Message.authFailed(reason: "Invalid credentials format")
                    try await send(errorMsg)
                    continue
                }
                
                do {
                    let token = try await authManager.login(username: credentials.username, password: credentials.password)
                    authToken = token.token
                    let successMsg = Message.authenticated(username: credentials.username, token: token.token)
                    try await send(successMsg)
                    return
                } catch {
                    let errorMsg = Message.authFailed(reason: error.localizedDescription)
                    try await send(errorMsg)
                }
                
            default:
                let errorMsg = Message.authFailed(reason: "Please login or register first")
                try await send(errorMsg)
            }
        }
    }
    
    func send(_ message: Message) async throws {
        let data = try message.encode()
        
        var remaining = data.count
        var offset = 0
        
        while remaining > 0 {
            let sent = data.withUnsafeBytes { bytes in
                #if canImport(Darwin)
                Darwin.send(socket, bytes.baseAddress!.advanced(by: offset), remaining, 0)
                #elseif canImport(Glibc)
                Glibc.send(socket, bytes.baseAddress!.advanced(by: offset), remaining, 0)
                #endif
            }
            
            guard sent > 0 else {
                throw ChatError.socketError("Failed to send data")
            }
            
            remaining -= sent
            offset += sent
        }
    }
    
    private func readMessage() async throws -> Message? {
        while true {
            
            if let (messageData, consumed) = MessageProtocol.extractMessage(from: buffer) {
                
                buffer = buffer.subdata(in: consumed..<buffer.count)
                
                return try Message.decode(from: messageData)
            }
            
            let (bytesRead, readData) = await Task { () -> (Int, [UInt8]) in
                var readBuffer = [UInt8](repeating: 0, count: 4096)
                let bytes = recv(socket, &readBuffer, readBuffer.count, 0)
                return (bytes, readBuffer)
            }.value
            
            if bytesRead < 0 {
                let err = errno
                if err == EAGAIN || err == EWOULDBLOCK {
                    try? await Task.sleep(for: .milliseconds(10))
                    continue
                }
                return nil
            }
            
            guard bytesRead > 0 else {
                return nil
            }
            
            buffer.append(contentsOf: readData[0..<bytesRead])
        }
    }
}
