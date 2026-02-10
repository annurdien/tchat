import Foundation

@main
struct TChatApp {
    static func main() {
        let arguments = CommandLine.arguments
        
        if arguments.count < 2 {
            printUsage()
            exit(1)
        }
        
        let mode = arguments[1]
        
        switch mode {
        case "server":
            let port = arguments.count > 2 ? UInt16(arguments[2]) ?? 8080 : 8080
            print("Starting tchat server on port \(port)...")
            let server = ChatServer(port: port)
            server.start()
            
        case "client":
            guard arguments.count >= 3 else {
                print("Error: Client mode requires host and optional port")
                printUsage()
                exit(1)
            }
            let host = arguments[2]
            let port = arguments.count > 3 ? UInt16(arguments[3]) ?? 8080 : 8080
            print("Connecting to \(host):\(port)...")
            let client = ChatClient(host: host, port: port)
            client.start()
            
        default:
            print("Error: Unknown mode '\(mode)'")
            printUsage()
            exit(1)
        }
    }
    
    static func printUsage() {
        print("""
        Usage:
          tchat server [port]        - Start chat server (default port: 8080)
          tchat client <host> [port] - Connect to chat server (default port: 8080)
        
        Examples:
          tchat server 9000
          tchat client localhost 9000
        """)
    }
}
