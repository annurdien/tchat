import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class ChatClient: @unchecked Sendable {
    private let host: String
    private let port: UInt16
    private var clientSocket: Int32 = -1
    private var isConnected = false
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
    
    func start() {
        // Create socket
        clientSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        guard clientSocket >= 0 else {
            print("Failed to create socket")
            return
        }
        
        // Resolve host
        guard let hostInfo = gethostbyname(host) else {
            print("Failed to resolve host: \(host)")
            close(clientSocket)
            return
        }
        
        // Setup server address
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = port.bigEndian
        
        let addressList = hostInfo.pointee.h_addr_list
        guard let firstAddress = addressList?[0] else {
            print("Failed to get host address")
            close(clientSocket)
            return
        }
        
        memcpy(&serverAddress.sin_addr, firstAddress, Int(hostInfo.pointee.h_length))
        
        // Connect to server
        let connectResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(clientSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard connectResult >= 0 else {
            print("Failed to connect to server at \(host):\(port)")
            close(clientSocket)
            return
        }
        
        print("✓ Connected to server at \(host):\(port)")
        isConnected = true
        
        // Start receiver thread
        let receiverThread = Thread {
            self.receiveMessages()
        }
        receiverThread.start()
        
        // Read and send messages from stdin
        sendMessages()
        
        // Cleanup
        isConnected = false
        close(clientSocket)
    }
    
    private func receiveMessages() {
        var buffer = [UInt8](repeating: 0, count: 4096)
        
        while isConnected {
            let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
            
            guard bytesRead > 0 else {
                if isConnected {
                    print("\n✗ Disconnected from server")
                    isConnected = false
                }
                break
            }
            
            if let message = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                // Print received message, overwriting the current input line if needed
                print("\r\u{001B}[K\(message)", terminator: "")
            }
        }
    }
    
    private func sendMessages() {
        while isConnected {
            guard let input = readLine() else {
                continue
            }
            
            let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for exit command
            if trimmedInput.lowercased() == "/quit" || trimmedInput.lowercased() == "/exit" {
                print("Disconnecting...")
                isConnected = false
                break
            }
            
            // Skip empty messages
            if trimmedInput.isEmpty {
                continue
            }
            
            // Send message to server
            let messageWithNewline = trimmedInput + "\n"
            let bytesSent = send(clientSocket, messageWithNewline, messageWithNewline.utf8.count, 0)
            
            if bytesSent < 0 {
                print("Failed to send message")
                isConnected = false
                break
            }
        }
    }
}
