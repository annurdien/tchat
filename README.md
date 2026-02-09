# tchat

A terminal-based TCP chat application written in Swift!

## Features

- Simple and lightweight TCP chat server and client
- Multi-client support with real-time message broadcasting
- User authentication with custom usernames
- Terminal-based interface
- Cross-platform support (Linux and macOS)

## Building

To build the project, you need Swift 6.2 or later installed.

```bash
swift build
```

For a release build:

```bash
swift build -c release
```

## Usage

### Starting the Server

Start a chat server on the default port (8080):

```bash
swift run tchat server
```

Or specify a custom port:

```bash
swift run tchat server 9000
```

### Connecting as a Client

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

## Example Session

**Terminal 1 (Server):**
```bash
$ swift run tchat server 9000
Starting tchat server on port 9000...
✓ Server is listening on port 9000
Waiting for clients to connect...
✓ Client connected from socket 4
✓ User 'Alice' joined the chat
[Alice]: Hello everyone!
```

**Terminal 2 (Client 1):**
```bash
$ swift run tchat client localhost 9000
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
$ swift run tchat client localhost 9000
Connecting to localhost:9000...
✓ Connected to server at localhost:9000
Welcome to tchat! Please enter your username: Bob
You are now connected as 'Bob'. Start chatting!
[Alice]: Hello everyone!
Hi Alice!
```

## License

See LICENSE file for details.
