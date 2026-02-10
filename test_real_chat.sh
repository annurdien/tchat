#!/bin/bash

echo "========================================="
echo "Testing tchat with real message exchange"
echo "========================================="
echo ""

# Clean up old logs
rm -f /tmp/tchat_*.log

# Start server in background
echo "Starting server on port 9998..."
swift run tchat server 9998 > /tmp/tchat_server.log 2>&1 &
SERVER_PID=$!
sleep 3

echo "Server started (PID: $SERVER_PID)"
echo ""

# Start Alice (client 1) in background
echo "Alice is joining..."
(
    sleep 1
    echo "Alice"
    sleep 2
    echo "Hey everyone!"
    sleep 2
    echo "Is anyone there?"
    sleep 4
    echo "Nice to meet you Bob!"
    sleep 3
    echo "/quit"
) | swift run tchat client localhost 9998 > /tmp/tchat_alice.log 2>&1 &
ALICE_PID=$!

sleep 4

# Start Bob (client 2) in background
echo "Bob is joining..."
(
    sleep 1
    echo "Bob"
    sleep 2
    echo "Hi Alice! I just joined!"
    sleep 2
    echo "How are you doing?"
    sleep 3
    echo "/quit"
) | swift run tchat client localhost 9998 > /tmp/tchat_bob.log 2>&1 &
BOB_PID=$!

# Wait for everything to finish
sleep 12

# Kill server
echo ""
echo "Shutting down server..."
kill $SERVER_PID 2>/dev/null

sleep 2

echo ""
echo "========================================="
echo "ALICE'S VIEW (what Alice sees):"
echo "========================================="
cat /tmp/tchat_alice.log
echo ""
echo "========================================="
echo "BOB'S VIEW (what Bob sees):"
echo "========================================="
cat /tmp/tchat_bob.log
echo ""
echo "========================================="
echo "SERVER LOG (what happened on server):"
echo "========================================="
cat /tmp/tchat_server.log
echo ""
echo "Test complete!"
