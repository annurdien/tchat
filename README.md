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

## Architecture

### System Design

tchat uses a client-server architecture with Swift's modern concurrency features:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Client A  │         │   Client B  │         │   Client C  │
│ (ChatClient)│         │ (ChatClient)│         │ (ChatClient)│
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │ TCP Socket            │ TCP Socket            │ TCP Socket
       │                       │                       │
       └───────────────────────┼───────────────────────┘
                               │
                      ┌────────▼────────┐
                      │   ChatServer    │
                      │    (Actor)      │
                      │                 │
                      │ ┌─────────────┐ │
                      │ │ConnectionMgr│ │
                      │ └─────────────┘ │
                      │ ┌─────────────┐ │
                      │ │  Broadcast  │ │
                      │ └─────────────┘ │
                      └─────────────────┘
```

### Concurrency Model

Built on Swift 6's structured concurrency:

**ChatServer (Actor)**
- Thread-safe connection management
- Isolated mutable state (users, connections)
- Async message broadcasting

**ChatClient (Actor)**
- Non-blocking socket I/O
- Concurrent message sending/receiving
- Actor-isolated buffer management

**ConnectionHandler (Actor)**
- Per-connection state isolation
- Async message reading/writing
- Automatic resource cleanup via defer

### Message Protocol

Length-prefixed JSON framing ensures reliable message delivery:

```
┌─────────────┬──────────────────┐
│  4 bytes    │   N bytes        │
│  Length     │   JSON Payload   │
│ (Big-endian)│                  │
└─────────────┴──────────────────┘
```

**Message Types:**
- `chat` - User messages with username and content
- `userJoined` - Broadcast when user connects
- `userLeft` - Broadcast when user disconnects

### Non-Blocking Sockets

All sockets use `fcntl(O_NONBLOCK)` to prevent blocking the async executor:

```swift
var flags = fcntl(socket, F_GETFL, 0)
flags |= O_NONBLOCK
fcntl(socket, F_SETFL, flags)
```

EAGAIN/EWOULDBLOCK handled with async retry loops.

### Key Components

**Models**
- `Message` - Protocol messages with type, username, content
- `User` - User metadata (id, username, timestamp)
- `ServerConfig` / `ClientConfig` - Configuration with defaults

**Network**
- `ChatServer` - Main server actor managing connections
- `ChatClient` - Client actor for sending/receiving
- `ConnectionHandler` - Per-connection message processing

**Security**
- Input validation for usernames and messages
- Rate limiting (10 msg/sec per user)
- SHA256 password hashing (auth system)

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

**With password authentication:**

```bash
swift run tchat server --auth 9000
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

**With password authentication:**

```bash
swift run tchat host --auth 9000
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

**With password authentication:**

```bash
swift run tchat server --auth 9000
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

**Without Authentication:**
1. When you connect as a client, you'll be prompted to enter your username
2. After entering your username, you can start typing messages
3. All messages are broadcast to other connected clients
4. To disconnect, type `/quit` or `/exit`

**With Authentication:**
1. When you connect to a server with authentication enabled, you'll first see:
   - Prompt to choose Login (1) or Register (2)
   - Username prompt
   - Password prompt
2. After successful authentication, proceed as normal with chat
3. To disconnect, type `/quit` or `/exit`

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

tchat supports optional password authentication. You can choose to run with or without authentication:

**Using command-line flag:**

```bash
# Server with authentication
swift run tchat server --auth 9000

# Host mode with authentication
swift run tchat host --auth 9000
```

**Using environment variable:**

```bash
TCHAT_REQUIRE_AUTH=true tchat server 9000
```

**Authentication Features:**
- **Auto-detection**: Client automatically detects if server requires authentication
- **Password Hashing**: SHA256 with salt and pepper
- **Token-based Auth**: 24-hour token expiration
- **User Registration**: Create accounts with username + password
- **Login/Logout**: Session management

**Client Experience:**

When connecting to an authenticated server, clients will be prompted for:
1. Login (1) or Register (2)
2. Username
3. Password

After successful authentication, chat proceeds normally.

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
Connecting to localhost:9000..
.
✓ Connected to server at localhost:9000
Welcome to tchat! Please enter your username: Bob
You are now connected as 'Bob'. Start chatting!
[Alice]: Hello everyone!
Hi Alice!
```

### With Password Authentication

**Terminal 1 (Server with Auth):**
```bash
$ swift run tchat server --auth 9000
Starting tchat server on port 9000...
✓ Server is listening on port 9000 (with authentication)
Waiting for clients to connect...
✓ User 'Alice' joined the chat
[Alice]: Secure chat is working!
```

**Terminal 2 (Client - Register):**
```bash
$ swift run tchat client localhost 9000
Connecting to localhost:9000...
✓ Connected to server at localhost:9000

🔐 This server requires authentication
Would you like to (1) Login or (2) Register?
2
Username: Alice
Password: mypassword123
✓ Authentication successful!
Username: Alice
Welcome to tchat! Please enter your username: 
You are now connected as 'Alice'. Start chatting!
Secure chat is working!
*** Bob joined the chat ***
[Bob]: Hello Alice!
```

**Terminal 3 (Client - Login):**
```bash
$ swift run tchat client localhost 9000
Connecting to localhost:9000...
✓ Connected to server at localhost:9000

🔐 This server requires authentication
Would you like to (1) Login or (2) Register?
1
Username: Alice
Password: wrongpassword
✗ Authentication failed: Authentication failed
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
