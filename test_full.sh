#!/bin/bash

# Automated full test
echo "=== FULL CHAT TEST ==="
echo ""

# Kill any existing instances
pkill -f "tchat server" 2>/dev/null
pkill -f "tchat client" 2>/dev/null
sleep 1

# Start server in background, capturing output
echo "Starting server..."
swift run tchat server 8888 > /tmp/chat_server_full.log 2>&1 &
SERVER_PID=$!
sleep 3

# Start client and simulate user interaction
echo "Starting client and sending username 'TestUser'..."
(
    sleep 2
    echo "TestUser"
    sleep 3
    echo "Hello world!"
    sleep 2
    echo "This is a test message"
    sleep 2
    echo "/quit"
) | swift run tchat client localhost 8888 > /tmp/chat_client_full.log 2>&1 &
CLIENT_PID=$!

# Wait for interaction
sleep 12

# Cleanup
kill $SERVER_PID 2>/dev/null
wait

echo ""
echo "=== SERVER OUTPUT ==="
cat /tmp/chat_server_full.log
echo ""
echo "=== CLIENT OUTPUT ==="
cat /tmp/chat_client_full.log
echo ""
echo "=== END OF TEST ==="
