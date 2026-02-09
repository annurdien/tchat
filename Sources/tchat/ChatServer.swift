import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class ChatServer: @unchecked Sendable {
    private let port: UInt16
    private var serverSocket: Int32 = -1
    private var clients: [Int32: String] = [:]
    private var clientThreads: [Thread] = []
    private let clientsLock = NSLock()
    
    init(port: UInt16) {
        self.port = port
    }
    
    func start() {
        // Create socket
        serverSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        guard serverSocket >= 0 else {
            print("Failed to create socket")
            return
        }
        
        // Set socket options to reuse address
        var reuseAddr: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))
        
        // Bind socket
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = port.bigEndian
        serverAddress.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        let bindResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult >= 0 else {
            print("Failed to bind socket to port \(port)")
            close(serverSocket)
            return
        }
        
        // Listen for connections
        guard listen(serverSocket, 5) >= 0 else {
            print("Failed to listen on socket")
            close(serverSocket)
            return
        }
        
        print("✓ Server is listening on port \(port)")
        print("Waiting for clients to connect...")
        
        // Accept connections in a loop
        while true {
            var clientAddress = sockaddr_in()
            var clientAddressLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            let clientSocket = withUnsafeMutablePointer(to: &clientAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(serverSocket, $0, &clientAddressLen)
                }
            }
            
            guard clientSocket >= 0 else {
                continue
            }
            
            // Handle client in a new thread
            let thread = Thread {
                self.handleClient(clientSocket)
            }
            clientThreads.append(thread)
            thread.start()
        }
    }
    
    private func handleClient(_ clientSocket: Int32) {
        // Get client address
        var clientAddress = sockaddr_in()
        var clientAddressLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &clientAddress) { addressPtr in
            addressPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                getpeername(clientSocket, sockaddrPtr, &clientAddressLen)
            }
        }
        
        print("✓ Client connected from socket \(clientSocket)")
        
        // Request username
        let welcomeMsg = "Welcome to tchat! Please enter your username: "
        send(clientSocket, welcomeMsg, welcomeMsg.utf8.count, 0)
        
        // Read username
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
        
        guard bytesRead > 0 else {
            close(clientSocket)
            return
        }
        
        let username = String(bytes: buffer[0..<bytesRead], encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Anonymous"
        
        // Store client
        clientsLock.lock()
        clients[clientSocket] = username
        clientsLock.unlock()
        
        print("✓ User '\(username)' joined the chat")
        
        // Broadcast join message
        let joinMsg = "*** \(username) joined the chat ***\n"
        broadcast(joinMsg, excludeSocket: clientSocket)
        
        // Send confirmation to client
        let confirmMsg = "You are now connected as '\(username)'. Start chatting!\n"
        send(clientSocket, confirmMsg, confirmMsg.utf8.count, 0)
        
        // Handle messages from this client
        while true {
            var messageBuffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = recv(clientSocket, &messageBuffer, messageBuffer.count, 0)
            
            guard bytesRead > 0 else {
                break
            }
            
            if let message = String(bytes: messageBuffer[0..<bytesRead], encoding: .utf8) {
                let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedMessage.isEmpty {
                    let formattedMessage = "[\(username)]: \(trimmedMessage)\n"
                    print("[\(username)]: \(trimmedMessage)")
                    broadcast(formattedMessage, excludeSocket: clientSocket)
                }
            }
        }
        
        // Client disconnected
        clientsLock.lock()
        clients.removeValue(forKey: clientSocket)
        clientsLock.unlock()
        
        print("✓ User '\(username)' left the chat")
        
        let leaveMsg = "*** \(username) left the chat ***\n"
        broadcast(leaveMsg, excludeSocket: clientSocket)
        
        close(clientSocket)
    }
    
    private func broadcast(_ message: String, excludeSocket: Int32) {
        clientsLock.lock()
        let clientSockets = Array(clients.keys)
        clientsLock.unlock()
        
        for socket in clientSockets {
            if socket != excludeSocket {
                send(socket, message, message.utf8.count, 0)
            }
        }
    }
}
