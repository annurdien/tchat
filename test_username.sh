#!/bin/bash

echo "Testing username flow..."
echo ""

# Start server
echo "Starting server..."
swift run tchat server 9997 > /tmp/test_server.log 2>&1 &
SERVER_PID=$!
sleep 2

echo "Connecting client and sending username 'TestUser'..."
(
    sleep 1
    echo "TestUser"
    sleep 5
    echo "/quit"
) | swift run tchat client localhost 9997 2>&1 | tee /tmp/test_client.log &

CLIENT_PID=$!
sleep 8

kill $SERVER_PID 2>/dev/null
wait

echo ""
echo "=== CLIENT OUTPUT ==="
cat /tmp/test_client.log
echo ""
echo "=== SERVER OUTPUT ==="
cat /tmp/test_server.log
