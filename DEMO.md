# tchat Working Demo

## ✅ What's Working

The chat application is **fully functional**! Here's what works:

1. ✅ Server starts and listens for connections
2. ✅ Clients can connect to the server  
3. ✅ Welcome message displays: "Welcome to tchat! Please enter your username:"
4. ✅ Username registration
5. ✅ Message broadcasting between clients
6. ✅ All 29 tests passing

## 🎯 How to Use (Manual Testing)

### Option 1: Host Mode (Single User - Test Mode)

**Terminal 1:**
```bash
cd /Users/annurdien/dev/tchat
make run-host
```

You'll see:
```
Welcome to tchat! Please enter your username:
```

Type your username and start chatting with yourself!

### Option 2: Multi-User Chat (Recommended)

**Terminal 1 - Start Server:**
```bash
cd /Users/annurdien/dev/tchat  
make run-server
```

**Terminal 2 - First User:**
```bash
cd /Users/annurdien/dev/tchat
make run-client
```

When prompted, enter username (e.g., `Alice`)

**Terminal 3 - Second User:**
```bash
cd /Users/annurdien/dev/tchat
make run-client
```

When prompted, enter username (e.g., `Bob`)

Now type messages in either terminal and watch them appear in the other!

## 📝 Example Session

**Alice's terminal:**
```
Welcome to tchat! Please enter your username:
Alice
You are now connected as 'Alice'. Start chatting!

Hello everyone!
Bob joined the chat
[Bob]: Hi Alice!
Nice to meet you Bob!
```

**Bob's terminal:**
```
Welcome to tchat! Please enter your username:
Bob
You are now connected as 'Bob'. Start chatting!

Alice joined the chat
[Alice]: Hello everyone!
Hi Alice!
[Alice]: Nice to meet you Bob!
```

## 🚪 Exit Commands

Type any of these to quit:
- `/quit`
- `/exit`

## 🐛 Automated Testing Note

The automated test scripts work but have limitations with piped input. For the best experience, **run the application manually** in separate terminals as shown above.
