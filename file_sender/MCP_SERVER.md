# Face Authentication MCP Server

This MCP server provides comprehensive tools for managing the face recognition attendance system through VS Code's Model Context Protocol integration.

## 🚀 Features

### 📱 User Management Tools
- `register_user` - Register new users with face embeddings
- `verify_user` - Verify user identity using face recognition
- `authenticate_user` - Authenticate user by registration number
- `get_user_info` - Get user information
- `logout_user` - Logout current user

### 📊 Attendance Management Tools
- `mark_attendance` - Mark attendance for verified users
- `get_attendance_stats` - Get attendance statistics
- `get_student_list` - Get complete student list with attendance status
- `search_student` - Search students by name or registration number

### 🤖 Face Recognition Tools
- `extract_face_embedding` - Extract face embedding from image
- `compare_faces` - Compare two face embeddings with similarity score
- `verify_face_match` - Verify face match with configurable threshold

### ⚙️ System Management Tools
- `server_status` - Get server status and current user info
- `get_registered_users` - Get list of registered users
- `clear_local_data` - Clear local cached data
- `export_attendance_data` - Export attendance data for analysis

## 🛠️ Setup Instructions

### 1. VS Code Configuration
The MCP server is automatically configured in `.vscode/settings.json`:

```json
{
    "dart.mcpServer": true,
    "mcp.servers": {
        "face-auth-server": {
            "command": "dart",
            "args": [
                "run",
                "bin/mcp_server.dart"
            ],
            "cwd": "${workspaceFolder}/file_sender",
            "description": "Face Authentication MCP Server - Manage users, attendance, and face recognition"
        }
    }
}
```

### 2. Start the Server
The server will automatically start when VS Code detects the MCP configuration.

### 3. Available Commands
Once running, you can use these commands through VS Code's MCP integration:

#### User Registration
```json
{
  "jsonrpc": "2.0",
  "method": "register_user",
  "params": {
    "name": "John Doe",
    "registrationNumber": "RA2111004010199",
    "faceEmbedding": [0.1, 0.2, 0.3, ...]
  },
  "id": 1
}
```

#### Face Verification
```json
{
  "jsonrpc": "2.0",
  "method": "verify_user",
  "params": {
    "currentEmbedding": [0.1, 0.2, 0.3, ...],
    "storedEmbedding": [0.1, 0.2, 0.3, ...]
  },
  "id": 2
}
```

#### Mark Attendance
```json
{
  "jsonrpc": "2.0",
  "method": "mark_attendance",
  "params": {
    "registrationNumber": "RA2111004010199"
  },
  "id": 3
}
```

#### Get Attendance Stats
```json
{
  "jsonrpc": "2.0",
  "method": "get_attendance_stats",
  "params": {},
  "id": 4
}
```

## 📋 Tool Examples

### Register a New User
```dart
// Through MCP server
await mcpCall('register_user', {
  'name': 'Alice Johnson',
  'registrationNumber': 'RA2111004010200',
  'faceEmbedding': faceEmbeddingList,
});
```

### Verify Face Match
```dart
// Compare current face with stored face
final result = await mcpCall('verify_face_match', {
  'currentEmbedding': currentFaceEmbedding,
  'storedEmbedding': storedFaceEmbedding,
  'threshold': 0.6,
});

if (result['verified']) {
  // Proceed with attendance marking
}
```

### Get System Status
```dart
final status = await mcpCall('server_status', {});
print('Server running: ${status['server_running']}');
print('Current user: ${status['current_user_reg_no']}');
```

## 🔧 Technical Details

### Server Architecture
- **Protocol**: JSON-RPC 2.0
- **Communication**: Stdio (for VS Code MCP integration)
- **Backend**: Flutter/Dart with Firebase Firestore
- **Face Recognition**: TFLite with cosine similarity

### Security Features
- Device binding (MAC address/device ID)
- Face verification with configurable thresholds
- Failed attempt protection
- Local data encryption
- Firebase authentication integration

### Data Flow
1. **Registration**: Face embedding extraction → Local storage → Firebase backup
2. **Verification**: Face capture → Embedding comparison → Authentication
3. **Attendance**: Face verification → Server API call → Record update

## 🚨 Error Handling

The server provides comprehensive error handling with JSON-RPC error responses:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params: Missing required parameter: registrationNumber"
  }
}
```

Common error codes:
- `-32600`: Invalid Request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error

## 🔍 Troubleshooting

### Server Won't Start
1. Check if Dart SDK is installed: `dart --version`
2. Verify dependencies: `dart pub get`
3. Check VS Code MCP configuration

### Face Recognition Issues
1. Verify TFLite model is in `assets/models/`
2. Check camera permissions
3. Ensure proper image preprocessing

### Firebase Connection Issues
1. Verify Firebase configuration in `firebase_options.dart`
2. Check internet connectivity
3. Review Firebase security rules

## 📚 Usage Examples

### Complete User Registration Flow
```dart
// 1. Extract face embedding
final embedding = await mcpCall('extract_face_embedding', {'imagePath': '/path/to/face.jpg'});

// 2. Register user
final result = await mcpCall('register_user', {
  'name': 'Bob Smith',
  'registrationNumber': 'RA2111004010201',
  'faceEmbedding': embedding['embedding'],
});

// 3. Verify registration
final user = await mcpCall('get_user_info', {
  'registrationNumber': 'RA2111004010201',
});
```

### Attendance Marking Flow
```dart
// 1. Authenticate user
final auth = await mcpCall('authenticate_user', {
  'registrationNumber': 'RA2111004010201',
});

// 2. Verify face
final faceVerified = await mcpCall('verify_face_match', {
  'currentEmbedding': currentFace,
  'storedEmbedding': auth['user']['faceEmbedding'],
});

// 3. Mark attendance
if (faceVerified['verified']) {
  await mcpCall('mark_attendance', {
    'registrationNumber': 'RA2111004010201',
  });
}
```

## 🔄 Integration with VS Code

This MCP server integrates seamlessly with VS Code's Model Context Protocol, allowing:
- Real-time user management
- Face recognition operations
- Attendance monitoring
- System administration
- Debugging and testing capabilities

The server provides a comprehensive API for managing your face recognition attendance system directly from your development environment.