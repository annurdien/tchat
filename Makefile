.PHONY: all build run-server run-client clean install test help

# Default target
all: build

# Build the project
build:
	@echo "Building tchat..."
	@swift build

# Build release version
build-release:
	@echo "Building tchat (release)..."
	@swift build -c release

# Run server on default port (8080)
run-server:
	@swift run tchat server

# Run server on custom port (usage: make run-server PORT=9000)
run-server-port:
	@swift run tchat server $(PORT)

# Run client connecting to localhost (usage: make run-client)
run-client:
	@swift run tchat client localhost

# Run client with custom host/port (usage: make run-client-custom HOST=localhost PORT=9000)
run-client-custom:
	@swift run tchat client $(HOST) $(PORT)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build

# Install the binary to /usr/local/bin (requires sudo)
install: build-release
	@echo "Installing tchat to /usr/local/bin..."
	@cp .build/release/tchat /usr/local/bin/tchat
	@echo "Installation complete. You can now run 'tchat' from anywhere."

# Run tests (if any)
test:
	@swift test

# Display help information
help:
	@echo "tchat Makefile - Available targets:"
	@echo ""
	@echo "  make build              - Build the project (debug mode)"
	@echo "  make build-release      - Build the project (release mode)"
	@echo "  make run-server         - Run server on default port (8080)"
	@echo "  make run-server-port PORT=<port> - Run server on custom port"
	@echo "  make run-client         - Run client connecting to localhost:8080"
	@echo "  make run-client-custom HOST=<host> PORT=<port> - Run client with custom settings"
	@echo "  make clean              - Clean build artifacts"
	@echo "  make install            - Install binary to /usr/local/bin (requires sudo)"
	@echo "  make test               - Run tests"
	@echo "  make help               - Display this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make run-server-port PORT=9000"
	@echo "  make run-client-custom HOST=192.168.1.100 PORT=9000"
