#!/bin/bash

echo "Testing with server output to console..."
echo ""

# Start server in foreground (so we see output)
swift run tchat server 9996 &
SERVER_PID=$!
sleep 2

echo ""
echo "Starting client..."
(
    sleep 1
    echo "Alice"
    sleep 3
    echo "Hello world"
    sleep 2
    echo "/quit"
) | swift run tchat client localhost 9996 &

sleep 10

kill $SERVER_PID 2>/dev/null
wait

echo ""
echo "Test complete"
