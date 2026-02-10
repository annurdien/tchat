# tchat

[![Build and Test](https://github.com/annurdien/tchat/actions/workflows/build.yml/badge.svg)](https://github.com/annurdien/tchat/actions/workflows/build.yml)

A terminal-based TCP chat application written in Swift!

## Features

- **Modern Swift Concurrency**: Built with actors and async/await for thread-safe, concurrent operations
- **Robust Message Protocol**: Length-prefixed framing with JSON encoding
- **Production-Ready Error Handling**: Custom error types, timeouts, and proper resource cleanup
- **Authentication System**: Token-based authentication with secure password hashing (SHA256)
- **Input Validation**: Comprehensive username, message, and password validation with sanitization
- **Rate Limiting**: Token bucket algorithm to prevent spam (10 msg/sec per user)
- **Configuration Management**: Environment variable support and validation
- **Host mode**: Act as both server and client simultaneously
- Multi-client support with real-time message broadcasting
- User authentication with custom usernames
- Connection limits and timeout handling
- Terminal-based interface
- Cross-platform support (Linux and macOS)
- Comprehensive test suite (29 tests)
- Easy to build and run with Makefile

## Requirements

- Swift 6.0 or later
- Linux or macOS

## Building

### Using Makefile (Recommended)

The easiest way to build and run the project is using the provided Makefile:

```bash
# Build the project (debug mode)
make build

# Build release version
make build-release

# Clean build artifacts
make clean

# Show all available commands
make help
```

### Using Swift Package Manager

You can also use Swift Package Manager directly:

```bash
# Build debug version
swift build

# Build release version
swift build -c release
```

## Usage

### Using Makefile

#### Host Mode (Recommended for Quick Start)

Start in host mode (acts as both server and client) on the default port (8080):

```bash
make run-host
```

Or specify a custom port:

```bash
make run-host-port PORT=9000
```

#### Starting the Server

Start a chat server on the default port (8080):

```bash
make run-server
```

Or specify a custom port:

```bash
make run-server-port PORT=9000
```

#### Connecting as a Client

Connect to a server running on localhost:

```bash
make run-client
```

Or connect to a specific host and port:

```bash
make run-client-custom HOST=192.168.1.100 PORT=9000
```

### Using Swift Run

#### Host Mode (Recommended for Quick Start)

Start in host mode on the default port (8080):

```bash
swift run tchat host
```

Or specify a custom port:

```bash
swift run tchat host 9000
```

#### Starting the Server

Start a chat server on the default port (8080):

```bash
swift run tchat server
```

Or specify a custom port:

```bash
swift run tchat server 9000
```

#### Connecting as a Client

Connect to a server running on localhost:

```bash
swift run tchat client localhost
```

Or connect to a specific host and port:

```bash
swift run tchat client localhost 9000
```

### Chatting

1. When you connect as a client, you'll be prompted to enter your username
2. After entering your username, you can start typing messages
3. All messages are broadcast to other connected clients
4. To disconnect, type `/quit` or `/exit`

## Installation

To install tchat system-wide (requires sudo):

```bash
make install
```

This will install the binary to `/usr/local/bin/tchat`, allowing you to run it from anywhere:

```bash
tchat server 9000
tchat client localhost 9000
```

## Architecture

### Modern Swift Concurrency

tchat is built with Swift's modern concurrency features:
- **Actors**: `ChatServer` and `ChatClient` are actors for thread-safe state management
- **Async/Await**: All I/O operations use async/await for better performance
- **Structured Concurrency**: Task groups for managing concurrent connections

### Message Protocol

Messages use length-prefixed framing:
```
[4 bytes: message length][JSON payload]
```

Message types:
- `join`: User joining
- `leave`: User leaving  
- `chat`: Regular chat message
- `userJoined`/`userLeft`: Notifications
- `error`: Error messages
- `ping`/`pong`: Keepalive

### Code Structure

```
Sources/tchat/
├── Models/           # Data models and protocol
│   ├── Message.swift
│   ├── User.swift
│   └── ChatError.swift
├── Network/          # Actor-based networking
│   ├── ChatServer.swift
│   └── ChatClient.swift
├── Config/           # Configuration management
│   └── Configuration.swift
├── ChatHost.swift
└── main.swift
```

## Configuration

### Environment Variables

- `TCHAT_PORT`: Default server port (default: 8080)
- `TCHAT_HOST`: Bind address (default: 0.0.0.0)
- `TCHAT_MAX_CONNECTIONS`: Maximum concurrent connections (default: 100)
- `TCHAT_REQUIRE_AUTH`: Enable authentication (default: false)

Example:
```bash
TCHAT_PORT=9000 TCHAT_MAX_CONNECTIONS=50 TCHAT_REQUIRE_AUTH=true tchat server
```

## Security Features

### Authentication (Optional)

Enable authentication to require users to register/login:

```bash
TCHAT_REQUIRE_AUTH=true tchat server

# or programmatically
let config = Configuration.withAuth(port: 8080)
```

Features:
- **Password Hashing**: SHA256 with salt and pepper
- **Token-based Auth**: 24-hour token expiration
- **User Registration**: Create accounts with username + password
- **Login/Logout**: Session management

### Input Validation

All user input is validated:
- **Usernames**: 3-20 chars, alphanumeric + underscore/hyphen
- **Messages**: Max 2000 chars, control characters filtered
- **Passwords**: 6-128 characters

### Rate Limiting

Token bucket algorithm prevents spam:
- **10 messages/second** per user (burst: 15)
- **100 messages/minute** per user
- **5 connection attempts/minute** per IP

Rate-limited users receive `rateLimited` messages.

## Example Session

**Terminal 1 (Server):**
```bash
$ make run-server-port PORT=9000
Starting tchat server on port 9000...
✓ Server is listening on port 9000
Waiting for clients to connect...
✓ Client connected from socket 4
✓ User 'Alice' joined the chat
[Alice]: Hello everyone!
```

**Terminal 2 (Client 1):**
```bash
$ make run-client-custom HOST=localhost PORT=9000
Connecting to localhost:9000...
✓ Connected to server at localhost:9000
Welcome to tchat! Please enter your username: Alice
You are now connected as 'Alice'. Start chatting!
Hello everyone!
*** Bob joined the chat ***
[Bob]: Hi Alice!
```

**Terminal 3 (Client 2):**
```bash
$ make run-client-custom HOST=localhost PORT=9000
Connecting to localhost:9000...
✓ Connected to server at localhost:9000
Welcome to tchat! Please enter your username: Bob
You are now connected as 'Bob'. Start chatting!
[Alice]: Hello everyone!
Hi Alice!
```

## CI/CD

This project uses GitHub Actions for continuous integration. The workflow automatically:

- Builds the project on both Linux (Ubuntu) and macOS
- Tests both debug and release builds
- Verifies the binary is created successfully
- Runs basic functionality tests

The CI workflow runs on every push to main/master branches and on pull requests.

## Development

### Running Tests

```bash
make test
```

### Available Make Targets

Run `make help` to see all available commands:

```bash
make help
```

## License

See LICENSE file for details.
