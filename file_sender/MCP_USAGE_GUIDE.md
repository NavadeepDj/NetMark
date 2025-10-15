# MCP Server Usage Guide

## 🚀 Face Authentication MCP Server

This MCP server provides comprehensive tools for managing the face recognition attendance system through VS Code's Model Context Protocol integration.

## 📋 Available Tools

### 📱 User Management
- **`register_user`** - Register new users with face embeddings
- **`verify_user`** - Verify user identity using face recognition
- **`authenticate_user`** - Authenticate user by registration number
- **`get_user_info`** - Get user information
- **`logout_user`** - Logout current user

### 📊 Attendance Management
- **`mark_attendance`** - Mark attendance for verified users
- **`get_attendance_stats`** - Get attendance statistics
- **`get_student_list`** - Get complete student list with attendance status
- **`search_student`** - Search students by name or registration number

### 🤖 Face Recognition
- **`extract_face_embedding`** - Extract face embedding from image
- **`compare_faces`** - Compare two face embeddings with similarity score
- **`verify_face_match`** - Verify face match with configurable threshold

### ⚙️ System Management
- **`server_status`** - Get server status and current user info
- **`get_registered_users`** - Get list of registered users
- **`clear_local_data`** - Clear local cached data
- **`export_attendance_data`** - Export attendance data for analysis

## 🔧 Setup in VS Code

### 1. Configuration
The MCP server is automatically configured in `.vscode/settings.json`:

```json
{
    "dart.mcpServer": true,
    "mcp.servers": {
        "face-auth-server": {
            "command": "dart",
            "args": [
                "run",
                "bin/standalone_mcp_server.dart"
            ],
            "cwd": "${workspaceFolder}/file_sender",
            "description": "Face Authentication MCP Server - Manage users, attendance, and face recognition"
        }
    }
}
```

### 2. Server Status Check
Use the `server_status` tool to check if the server is running:

```json
{
  "jsonrpc": "2.0",
  "method": "server_status",
  "params": {},
  "id": 1
}
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "success": true,
    "status": {
      "server_running": true,
      "face_service_initialized": true,
      "registered_users_count": 0,
      "server_type": "standalone",
      "server_url": "http://10.2.8.97:5000",
      "timestamp": "2025-01-15T10:30:00.000Z"
    }
  }
}
```

## 📝 Usage Examples

### Example 1: Register a New User
```json
{
  "jsonrpc": "2.0",
  "method": "register_user",
  "params": {
    "name": "Alice Johnson",
    "registrationNumber": "RA2111004010200",
    "faceEmbedding": [0.1, 0.2, 0.3, 0.4, 0.5, ...]
  },
  "id": 2
}
```

### Example 2: Authenticate User
```json
{
  "jsonrpc": "2.0",
  "method": "authenticate_user",
  "params": {
    "registrationNumber": "RA2111004010200"
  },
  "id": 3
}
```

### Example 3: Verify Face Match
```json
{
  "jsonrpc": "2.0",
  "method": "verify_face_match",
  "params": {
    "currentEmbedding": [0.1, 0.2, 0.3, 0.4, 0.5, ...],
    "storedEmbedding": [0.1, 0.2, 0.3, 0.4, 0.5, ...],
    "threshold": 0.6
  },
  "id": 4
}
```

### Example 4: Mark Attendance
```json
{
  "jsonrpc": "2.0",
  "method": "mark_attendance",
  "params": {
    "registrationNumber": "RA2111004010200"
  },
  "id": 5
}
```

### Example 5: Get Attendance Statistics
```json
{
  "jsonrpc": "2.0",
  "method": "get_attendance_stats",
  "params": {},
  "id": 6
}
```

### Example 6: Search Students
```json
{
  "jsonrpc": "2.0",
  "method": "search_student",
  "params": {
    "query": "Alice"
  },
  "id": 7
}
```

## 🔍 Testing the Server

### Manual Testing
You can test the server manually by running:

```bash
cd file_sender
dart run bin/standalone_mcp_server.dart
```

Then send JSON-RPC requests via stdin:

```bash
echo '{"jsonrpc":"2.0","method":"server_status","params":{},"id":1}' | dart run bin/standalone_mcp_server.dart
```

### Quick Test Script
```dart
import 'dart:convert';
import 'dart:io';

void main() async {
  // Test server status
  final request = {
    'jsonrpc': '2.0',
    'method': 'server_status',
    'params': {},
    'id': 1
  };

  final process = await Process.start('dart', ['run', 'bin/standalone_mcp_server.dart']);
  process.stdin.writeln(json.encode(request));

  final response = await process.stdout.transform(utf8.decoder).first;
  print('Server response: $response');

  await process.kill();
}
```

## 🎯 Common Workflows

### Workflow 1: Complete User Registration
1. Extract face embedding: `extract_face_embedding`
2. Register user: `register_user`
3. Verify registration: `get_user_info`

### Workflow 2: Attendance Marking
1. Authenticate user: `authenticate_user`
2. Verify face: `verify_face_match`
3. Mark attendance: `mark_attendance`

### Workflow 3: Attendance Reporting
1. Get stats: `get_attendance_stats`
2. Get student list: `get_student_list`
3. Export data: `export_attendance_data`

## 🔧 Integration with VS Code

The MCP server integrates seamlessly with VS Code's Model Context Protocol, allowing you to:

- Use face authentication tools directly from VS Code
- Manage users and attendance through the MCP interface
- Automate attendance workflows
- Debug and test face recognition functionality

## 📊 Error Handling

The server provides comprehensive error responses:

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

## 🚀 Production Deployment

For production use:

1. **Replace with Full Flutter Integration**: Use the full Flutter-based MCP server when you need real face recognition
2. **Firebase Integration**: Connect to your Firebase Firestore backend
3. **Real TFLite Model**: Integrate your actual `output_model.tflite` model
4. **Security**: Add authentication and authorization layers

## 📚 Advanced Usage

### Custom Face Recognition Thresholds
```json
{
  "jsonrpc": "2.0",
  "method": "verify_face_match",
  "params": {
    "currentEmbedding": [...],
    "storedEmbedding": [...],
    "threshold": 0.8  // Higher threshold for more strict matching
  },
  "id": 8
}
```

### Batch Operations
You can chain multiple MCP calls for complex workflows:

1. Register multiple users
2. Extract and compare multiple face embeddings
3. Process attendance for entire classes

### Integration with Other Tools
The MCP server can be integrated with:
- **Claude Code** for AI-powered assistance
- **VS Code extensions** for custom UI
- **CI/CD pipelines** for automated testing
- **External applications** via JSON-RPC

## 🎉 Benefits

- **🤖 AI-Powered**: Full integration with Claude and other AI models
- **⚡ Real-time**: Immediate response to authentication requests
- **🔒 Secure**: Built-in face recognition and verification
- **📱 Cross-platform**: Works on Windows, macOS, and Linux
- **🔧 Extensible**: Easy to add new tools and features

Your face authentication system is now fully integrated with VS Code's MCP ecosystem! 🚀