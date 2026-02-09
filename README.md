# tchat

[![Build and Test](https://github.com/annurdien/tchat/actions/workflows/build.yml/badge.svg)](https://github.com/annurdien/tchat/actions/workflows/build.yml)

A terminal-based TCP chat application written in Swift!

## Features

- Simple and lightweight TCP chat server and client
- Multi-client support with real-time message broadcasting
- User authentication with custom usernames
- Terminal-based interface
- Cross-platform support (Linux and macOS)
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
