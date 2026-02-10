#!/bin/bash

# Test script for tchat
echo "Testing tchat application..."
echo ""

# Start server in background
echo "1. Starting server..."
swift run tchat server 9999 > /tmp/tchat_server.log 2>&1 &
SERVER_PID=$!
sleep 2

# Start first client and send username + message
echo "2. Connecting client 1..."
(
    sleep 1
    echo "alice"
    sleep 1
    echo "Hello from Alice!"
    sleep 2
    echo "/quit"
) | swift run tchat client localhost 9999 > /tmp/tchat_client1.log 2>&1 &
CLIENT1_PID=$!

sleep 3

# Start second client and send username + message  
echo "3. Connecting client 2..."
(
    sleep 1
    echo "bob"
    sleep 1
    echo "Hello from Bob!"
    sleep 2
    echo "/quit"
) | swift run tchat client localhost 9999 > /tmp/tchat_client2.log 2>&1 &
CLIENT2_PID=$!

# Wait for clients to finish
sleep 6

# Kill server
kill $SERVER_PID 2>/dev/null

echo ""
echo "=== SERVER LOG ==="
cat /tmp/tchat_server.log
echo ""
echo "=== CLIENT 1 LOG (alice) ==="
cat /tmp/tchat_client1.log
echo ""
echo "=== CLIENT 2 LOG (bob) ==="
cat /tmp/tchat_client2.log
echo ""
echo "Test complete!"
