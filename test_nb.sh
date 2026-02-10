#!/bin/bash

echo "=== Testing Non-Blocking Sockets ==="
pkill -f "tchat" 2>/dev/null
sleep 1

swift run tchat server 7777 > /tmp/server_nb.log 2>&1 &
SERVER_PID=$!
sleep 2

(
    sleep 1
    echo "Alice"
    sleep 2
    echo "Hello from Alice!"
    sleep 2
    echo "/quit"
) | swift run tchat client localhost 7777 > /tmp/client_nb.log 2>&1 &

sleep 8
kill $SERVER_PID 2>/dev/null
wait

echo ""
echo "=== SERVER ===" 
cat /tmp/server_nb.log
echo ""
echo "=== CLIENT ==="
cat /tmp/client_nb.log
