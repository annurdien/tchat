import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

actor ChatClient {
    private let config: ClientConfig
    private var socket: Int32 = -1
    private var isConnected = false
    private var buffer = Data()
    private var receiveTask: Task<Void, Never>?
    private var username: String?
    
    init(config: ClientConfig = .default) {
        self.config = config
    }
    
    func connect(to host: String, port: UInt16) async throws {
        guard !isConnected else {
            throw ChatError.invalidConfiguration("Already connected")
        }
        
        #if canImport(Darwin)
        socket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        #else
        socket = Glibc.socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #endif
        
        guard socket >= 0 else {
            throw ChatError.socketError("Failed to create socket")
        }
        
        guard let hostInfo = gethostbyname(host) else {
            close(socket)
            throw ChatError.connectionFailed("Failed to resolve host: \(host)")
        }
        
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = port.bigEndian
        
        let addressList = hostInfo.pointee.h_addr_list
        guard let firstAddress = addressList?[0] else {
            close(socket)
            throw ChatError.connectionFailed("Failed to get host address")
        }
        
        memcpy(&serverAddress.sin_addr, firstAddress, Int(hostInfo.pointee.h_length))
        
        let connectResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard connectResult >= 0 else {
            close(socket)
            throw ChatError.connectionFailed("Failed to connect to \(host):\(port)")
        }
        
        var flags = fcntl(socket, F_GETFL, 0)
        flags |= O_NONBLOCK
        fcntl(socket, F_SETFL, flags)
        
        isConnected = true
        print("✓ Connected to server at \(host):\(port)")
        
        receiveTask = Task {
            await receiveMessages()
        }
    }
    
    func send(_ message: Message) async throws {
        guard isConnected else {
            throw ChatError.notConnected
        }
        
        let data = try message.encode()
        
        var remaining = data.count
        var offset = 0
        
        while remaining > 0 {
            let sent = data.withUnsafeBytes { bytes in
                Darwin.send(socket, bytes.baseAddress!.advanced(by: offset), remaining, 0)
            }
            
            guard sent > 0 else {
                await disconnect()
                throw ChatError.socketError("Failed to send data")
            }
            
            remaining -= sent
            offset += sent
        }
    }
    
    private func receiveMessages() async {
        while isConnected {
            do {
                guard let message = try await readMessage() else {
                    break
                }
                
                handleMessage(message)
            } catch {
                print("✗ Error receiving message: \(error.localizedDescription)")
                break
            }
        }
        
        if isConnected {
            print("\n✗ Disconnected from server")
            await disconnect()
        }
    }
    
    private func readMessage() async throws -> Message? {
        while true {
            
            if let (messageData, consumed) = MessageProtocol.extractMessage(from: buffer) {
                
                buffer = buffer.subdata(in: consumed..<buffer.count)
                
                return try Message.decode(from: messageData)
            }
            
            var readBuffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = recv(socket, &readBuffer, readBuffer.count, 0)
            
            if bytesRead < 0 {
                let err = errno
                if err == EAGAIN || err == EWOULDBLOCK {
                    try? await Task.sleep(for: .milliseconds(10))
                    continue
                }
                throw ChatError.socketError("recv failed")
            }
            
            guard bytesRead > 0 else {
                
                return nil
            }
            
            buffer.append(contentsOf: readBuffer[0..<bytesRead])
        }
    }
    
    nonisolated private func handleMessage(_ message: Message) {
        if let content = message.content {
            if let username = message.username {
                print("[\(username)]: \(content)")
            } else {
                print(content)
            }
        }
    }
    
    func sendInput(_ input: String) async throws {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedInput.lowercased() == "/quit" || trimmedInput.lowercased() == "/exit" {
            print("Disconnecting...")
            await disconnect()
            return
        }
        
        guard !trimmedInput.isEmpty else {
            return
        }
        
        let message = Message(type: .chat, content: trimmedInput)
        try await send(message)
        
        if let username = username {
            print("\u{001B}[1A\u{001B}[2K[\(username)]: \(trimmedInput)")
        }
    }
    
    func disconnect() async {
        isConnected = false
        
        receiveTask?.cancel()
        receiveTask = nil
        
        if socket >= 0 {
            close(socket)
            socket = -1
        }
        
        buffer = Data()
    }
    
    nonisolated func run(host: String, port: UInt16) async throws {
        try await connect(to: host, port: port)
        
        try await Task.sleep(for: .milliseconds(500))
        
        guard let input = readLine() else {
            await disconnect()
            return
        }
        
        await setUsername(input)
        
        let usernameMsg = Message(type: .chat, content: input)
        try await send(usernameMsg)
        
        try await Task.sleep(for: .milliseconds(500))
        while await isConnected {
            guard let input = readLine() else {
                break
            }
            
            do {
                try await sendInput(input)
            } catch {
                print("✗ Error sending message: \(error.localizedDescription)")
                break
            }
        }
        
        await disconnect()
    }
    
    func setUsername(_ name: String) {
        username = name
    }
    
    func getUsername() -> String? {
        return username
    }
}
