import 'dart:convert';
import 'package:file_sender/mcp/mcp_server.dart';

Future<void> main() async {
  print('🧪 Testing Face Authentication MCP Server...');

  final mcpServer = MCPServer();

  try {
    // Initialize the server
    await mcpServer.initialize();
    print('✅ MCP Server initialized successfully');

    // Test server status
    print('🔍 Testing server status...');
    final status = await mcpServer.getServerStatus();
    print('✅ Server status: ${json.encode(status)}');

    print('🎉 MCP Server is ready for VS Code integration!');
    print('📋 Available tools:');
    print('   📱 User Management: register_user, verify_user, authenticate_user, get_user_info, logout_user');
    print('   📊 Attendance: mark_attendance, get_attendance_stats, get_student_list, search_student');
    print('   🤖 Face Recognition: extract_face_embedding, compare_faces, verify_face_match');
    print('   ⚙️ System: server_status, get_registered_users, clear_local_data, export_attendance_data');
    print('');
    print('🔧 VS Code Configuration:');
    print('   • MCP server configured in .vscode/settings.json');
    print('   • Server will start automatically when VS Code detects MCP');
    print('   • Use tools through VS Code\'s MCP integration');

  } catch (e, stackTrace) {
    print('❌ MCP Server test failed: $e');
    print('Stack trace: $stackTrace');
  }
}