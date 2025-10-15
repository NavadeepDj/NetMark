import 'dart:convert';
import 'dart:io';
import 'package:file_sender/mcp/mcp_server.dart';

Future<void> main() async {
  // Initialize logging
  print('🤖 Face Authentication MCP Server Starting...');

  final mcpServer = MCPServer();

  try {
    // Initialize the server
    await mcpServer.initialize();

    // Start listening on stdin/stdout for MCP communication
    await mcpServer.startStdio();

  } catch (e, stackTrace) {
    print('❌ Failed to start MCP Server: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}