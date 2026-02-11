# tchat

[![Build and Test](https://github.com/annurdien/tchat/actions/workflows/build.yml/badge.svg)](https://github.com/annurdien/tchat/actions/workflows/build.yml)

![tchat demo](demo.gif)

A minimal TCP chat application built with Swift.

## Quick Start

```bash
# Host mode (server + client in one)
swift run tchat host

# Or use separate server/client
swift run tchat server            # Terminal 1
swift run tchat client localhost  # Terminal 2
```

## Architecture

### System Overview

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Client A   │         │  Client B   │         │  Client C   │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │      TCP Sockets      │                       │
       └───────────┬───────────┴───────────────────────┘
                   │
          ┌────────▼────────┐
          │   ChatServer    │
          │     (Actor)     │
          │                 │
          │  - Connections  │
          │  - Broadcast    │
          │  - Auth         │
          └─────────────────┘
```

### Core Components

**Actor Model** - Thread-safe concurrency using Swift 6 actors:
- `ChatServer` - Manages connections and broadcasts messages
- `ChatClient` - Handles sending/receiving with non-blocking I/O
- `ConnectionHandler` - Per-connection state isolation

**Message Protocol** - Length-prefixed JSON framing:
```
┌──────────┬──────────────┐
│ 4 bytes  │   N bytes    │
│ Length   │ JSON Payload │
└──────────┴──────────────┘
```

Message types: `chat`, `userJoined`, `userLeft`, `authMode`, `authRequest`, `authResponse`

**Non-Blocking I/O** - All sockets use `fcntl(O_NONBLOCK)` with async retry loops for EAGAIN/EWOULDBLOCK

## Usage

### Basic Usage

```bash
# Start host mode (quickest way to start)
swift run tchat host [PORT]

# Start server only
swift run tchat server [PORT]

# Connect as client
swift run tchat client <HOST> [PORT]
```

Default port: `8080`

### With Authentication

```bash
# Server with optional password auth
swift run tchat server --auth [PORT]

# Host mode with auth
swift run tchat host --auth [PORT]
```

When connecting to an auth-enabled server:
1. Choose Login (1) or Register (2)
2. Enter username and password
3. Start chatting

### Installation

Install system-wide:
```bash
make install
```

Then run from anywhere:
```bash
tchat server 9000
tchat client localhost 9000
```

### Environment Variables

```bash
TCHAT_PORT=9000               # Default port
TCHAT_HOST=0.0.0.0           # Bind address
TCHAT_MAX_CONNECTIONS=100    # Connection limit
TCHAT_REQUIRE_AUTH=true      # Enable authentication
```

## Security

- **Input Validation**: Usernames (3-20 chars), Messages (max 2000 chars)
- **Rate Limiting**: 10 msg/sec per user, 5 connection attempts/min per IP
- **Authentication**: SHA256 password hashing with salt/pepper, 24-hour tokens
- **Auto-detection**: Clients automatically detect if server requires auth

## Building

```bash
# Using Makefile
make build           # Debug build
make build-release   # Release build
make test           # Run tests

# Using Swift PM directly
swift build
swift build -c release
```

## Example Session

**Server:**
```bash
$ swift run tchat server 9000
✓ Server is listening on port 9000
✓ User 'Alice' joined the chat
[Alice]: Hello!
```

**Client:**
```bash
$ swift run tchat client localhost 9000
✓ Connected to server at localhost:9000
Welcome to tchat! Please enter your username: Alice
You are now connected as 'Alice'. Start chatting!
Hello!
```

**Chat commands:**
- `/quit` or `/exit` - Disconnect

## Requirements

- Swift 6.0+
- macOS or Linux

## License

MIT