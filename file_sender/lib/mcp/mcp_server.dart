import 'dart:convert';
import 'dart:io';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:json_rpc_2/server.dart' as rpc;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/face_auth_service_mobile.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

class MCPServer {
  late rpc.Server _server;
  final FaceAuthService _faceAuthService = FaceAuthService();
  bool _isRunning = false;

  Future<void> initialize() async {
    await _faceAuthService.initialize();

    _server = rpc.Server()
      // User Management Tools
      ..registerMethod('register_user', _registerUser)
      ..registerMethod('verify_user', _verifyUser)
      ..registerMethod('authenticate_user', _authenticateUser)
      ..registerMethod('get_user_info', _getUserInfo)
      ..registerMethod('logout_user', _logoutUser)

      // Attendance Management Tools
      ..registerMethod('mark_attendance', _markAttendance)
      ..registerMethod('get_attendance_stats', _getAttendanceStats)
      ..registerMethod('get_student_list', _getStudentList)
      ..registerMethod('search_student', _searchStudent)

      // Face Recognition Tools
      ..registerMethod('extract_face_embedding', _extractFaceEmbedding)
      ..registerMethod('compare_faces', _compareFaces)
      ..registerMethod('verify_face_match', _verifyFaceMatch)

      // System Management Tools
      ..registerMethod('server_status', _getServerStatus)
      ..registerMethod('get_registered_users', _getRegisteredUsers)
      ..registerMethod('clear_local_data', _clearLocalData)
      ..registerMethod('export_attendance_data', _exportAttendanceData);

    print('🚀 MCP Server initialized with face authentication tools');
  }

  // User Management Methods
  Future<Map<String, dynamic>> _registerUser(Map<String, dynamic> params) async {
    try {
      final name = params['name'] as String?;
      final registrationNumber = params['registrationNumber'] as String?;
      final faceEmbedding = params['faceEmbedding'] as List<dynamic>?;

      if (name == null || registrationNumber == null || faceEmbedding == null) {
        throw RpcException.invalidParams('Missing required parameters: name, registrationNumber, faceEmbedding');
      }

      await _faceAuthService.registerUser(
        name: name,
        registrationNumber: registrationNumber,
        faceEmbedding: faceEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      return {
        'success': true,
        'message': 'User registered successfully',
        'registrationNumber': registrationNumber,
        'name': name,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to register user: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyUser(Map<String, dynamic> params) async {
    try {
      final currentEmbedding = params['currentEmbedding'] as List<dynamic>?;
      final storedEmbedding = params['storedEmbedding'] as List<dynamic>?;

      if (currentEmbedding == null || storedEmbedding == null) {
        throw RpcException.invalidParams('Missing required parameters: currentEmbedding, storedEmbedding');
      }

      final isVerified = await _faceAuthService.verifyFace(
        currentEmbedding.map((e) => (e as num).toDouble()).toList(),
        storedEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      return {
        'success': true,
        'verified': isVerified,
        'message': isVerified ? 'Face verification successful' : 'Face verification failed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to verify user: $e');
    }
  }

  Future<Map<String, dynamic>> _authenticateUser(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw RpcException.invalidParams('Missing required parameter: registrationNumber');
      }

      final userInfo = await _faceAuthService.authenticateUser(registrationNumber);

      if (userInfo == null) {
        return {
          'success': false,
          'message': 'User not found',
          'registrationNumber': registrationNumber,
        };
      }

      return {
        'success': true,
        'user': userInfo,
        'message': 'User authenticated successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to authenticate user: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw RpcException.invalidParams('Missing required parameter: registrationNumber');
      }

      final userInfo = await _faceAuthService.authenticateUser(registrationNumber);

      if (userInfo == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      return {
        'success': true,
        'user': {
          'name': userInfo['name'],
          'registrationNumber': userInfo['registrationNumber'],
          'isLocal': userInfo['isLocal'],
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to get user info: $e');
    }
  }

  Future<Map<String, dynamic>> _logoutUser(Map<String, dynamic> params) async {
    try {
      await _faceAuthService.logout();

      return {
        'success': true,
        'message': 'User logged out successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to logout user: $e');
    }
  }

  // Attendance Management Methods
  Future<Map<String, dynamic>> _markAttendance(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw RpcException.invalidParams('Missing required parameter: registrationNumber');
      }

      final response = await http.post(
        Uri.parse('${Config.serverUrl}/mark_attendance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'registrationNumber': registrationNumber}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Attendance marked successfully',
          'registrationNumber': registrationNumber,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw RpcException.internalError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw RpcException.internalError('Failed to mark attendance: $e');
    }
  }

  Future<Map<String, dynamic>> _getAttendanceStats(Map<String, dynamic> params) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.serverUrl}/attendance_stats'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'stats': responseData,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw RpcException.internalError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw RpcException.internalError('Failed to get attendance stats: $e');
    }
  }

  Future<Map<String, dynamic>> _getStudentList(Map<String, dynamic> params) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.serverUrl}/students'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'students': responseData['students'] ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw RpcException.internalError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw RpcException.internalError('Failed to get student list: $e');
    }
  }

  Future<Map<String, dynamic>> _searchStudent(Map<String, dynamic> params) async {
    try {
      final query = params['query'] as String?;

      if (query == null || query.isEmpty) {
        throw RpcException.invalidParams('Missing required parameter: query');
      }

      final response = await http.get(
        Uri.parse('${Config.serverUrl}/search_students/$query'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'students': responseData['students'] ?? [],
          'query': query,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw RpcException.internalError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw RpcException.internalError('Failed to search students: $e');
    }
  }

  // Face Recognition Methods
  Future<Map<String, dynamic>> _extractFaceEmbedding(Map<String, dynamic> params) async {
    try {
      final imagePath = params['imagePath'] as String?;

      if (imagePath == null) {
        throw RpcException.invalidParams('Missing required parameter: imagePath');
      }

      final embedding = await _faceAuthService.extractFaceEmbedding();

      if (embedding == null) {
        throw RpcException.internalError('Failed to extract face embedding');
      }

      return {
        'success': true,
        'embedding': embedding,
        'embeddingSize': embedding.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to extract face embedding: $e');
    }
  }

  Future<Map<String, dynamic>> _compareFaces(Map<String, dynamic> params) async {
    try {
      final embedding1 = params['embedding1'] as List<dynamic>?;
      final embedding2 = params['embedding2'] as List<dynamic>?;

      if (embedding1 == null || embedding2 == null) {
        throw RpcException.invalidParams('Missing required parameters: embedding1, embedding2');
      }

      final similarity = _faceAuthService.calculateCosineSimilarity(
        embedding1.map((e) => (e as num).toDouble()).toList(),
        embedding2.map((e) => (e as num).toDouble()).toList(),
      );

      return {
        'success': true,
        'similarity': similarity,
        'match': similarity >= 0.6,
        'threshold': 0.6,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to compare faces: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyFaceMatch(Map<String, dynamic> params) async {
    try {
      final currentEmbedding = params['currentEmbedding'] as List<dynamic>?;
      final storedEmbedding = params['storedEmbedding'] as List<dynamic>?;
      final threshold = params['threshold'] as double? ?? 0.6;

      if (currentEmbedding == null || storedEmbedding == null) {
        throw RpcException.invalidParams('Missing required parameters: currentEmbedding, storedEmbedding');
      }

      final isVerified = await _faceAuthService.verifyFace(
        currentEmbedding.map((e) => (e as num).toDouble()).toList(),
        storedEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      final similarity = _faceAuthService.calculateCosineSimilarity(
        currentEmbedding.map((e) => (e as num).toDouble()).toList(),
        storedEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      return {
        'success': true,
        'verified': isVerified,
        'similarity': similarity,
        'threshold': threshold,
        'match': similarity >= threshold,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to verify face match: $e');
    }
  }

  // System Management Methods
  Future<Map<String, dynamic>> _getServerStatus(Map<String, dynamic> params) async {
    try {
      final isUserRegistered = await _faceAuthService.isUserRegistered();
      final currentUser = await _faceAuthService.getCurrentUserRegNo();

      return {
        'success': true,
        'status': {
          'server_running': _isRunning,
          'face_service_initialized': true,
          'current_user_registered': isUserRegistered,
          'current_user_reg_no': currentUser,
          'server_url': Config.serverUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      throw RpcException.internalError('Failed to get server status: $e');
    }
  }

  // Public method for testing
  Future<Map<String, dynamic>> getServerStatus() async {
    return await _getServerStatus({});
  }

  Future<Map<String, dynamic>> _getRegisteredUsers(Map<String, dynamic> params) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRegNo = prefs.getString('userRegNo');
      final userName = prefs.getString('userName');

      return {
        'success': true,
        'users': userRegNo != null ? [
          {
            'registrationNumber': userRegNo,
            'name': userName,
            'isLocal': true,
          }
        ] : [],
        'count': userRegNo != null ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to get registered users: $e');
    }
  }

  Future<Map<String, dynamic>> _clearLocalData(Map<String, dynamic> params) async {
    try {
      await _faceAuthService.logout();

      return {
        'success': true,
        'message': 'Local data cleared successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw RpcException.internalError('Failed to clear local data: $e');
    }
  }

  Future<Map<String, dynamic>> _exportAttendanceData(Map<String, dynamic> params) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.serverUrl}/attendance_stats'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        return {
          'success': true,
          'data': {
            'attendance_stats': responseData,
            'export_timestamp': DateTime.now().toIso8601String(),
            'server_url': Config.serverUrl,
          },
        };
      } else {
        throw RpcException.internalError('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw RpcException.internalError('Failed to export attendance data: $e');
    }
  }

  Future<void> startStdio() async {
    if (_isRunning) {
      print('⚠️ MCP Server is already running');
      return;
    }

    _isRunning = true;
    print('🚀 Face Authentication MCP Server started (stdio mode)');
    print('📋 Available MCP Tools:');
    print('   📱 User Management: register_user, verify_user, authenticate_user, get_user_info, logout_user');
    print('   📊 Attendance: mark_attendance, get_attendance_stats, get_student_list, search_student');
    print('   🤖 Face Recognition: extract_face_embedding, compare_faces, verify_face_match');
    print('   ⚙️ System: server_status, get_registered_users, clear_local_data, export_attendance_data');

    try {
      await for (final line in stdin.transform(utf8.decoder).transform(LineSplitter()) {
        if (line.trim().isEmpty) continue;

        try {
          final request = json.decode(line);
          final response = await _server.parseRequest(json.encode(request));
          print(json.encode(response));
        } catch (e) {
          final errorResponse = {
            'jsonrpc': '2.0',
            'id': request['id'] ?? null,
            'error': {
              'code': -32603,
              'message': 'Internal error: $e'
            }
          };
          print(json.encode(errorResponse));
        }
      }
    } catch (e) {
      print('❌ Error in stdio communication: $e');
    }
  }

  Future<void> start({int port = 8080}) async {
    if (_isRunning) {
      print('⚠️ MCP Server is already running');
      return;
    }

    try {
      final server = await HttpServer.bind('localhost', port);
      _isRunning = true;

      print('🚀 MCP Server started on http://localhost:$port');
      print('📋 Available methods:');
      print('   📱 User Management: register_user, verify_user, authenticate_user, get_user_info, logout_user');
      print('   📊 Attendance: mark_attendance, get_attendance_stats, get_student_list, search_student');
      print('   🤖 Face Recognition: extract_face_embedding, compare_faces, verify_face_match');
      print('   ⚙️ System: server_status, get_registered_users, clear_local_data, export_attendance_data');

      await for (HttpRequest request in server) {
        _handleRequest(request);
      }
    } catch (e) {
      print('❌ Failed to start MCP Server: $e');
      _isRunning = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getServerStatus(Map<String, dynamic> params) async {
    try {
      final isUserRegistered = await _faceAuthService.isUserRegistered();
      final currentUser = await _faceAuthService.getCurrentUserRegNo();

      return {
        'success': true,
        'status': {
          'server_running': _isRunning,
          'face_service_initialized': true,
          'current_user_registered': isUserRegistered,
          'current_user_reg_no': currentUser,
          'server_url': Config.serverUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      throw RpcException.internalError('Failed to get server status: $e');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/rpc') {
        final content = await utf8.decodeStream(request);
        final response = await _server.parseRequest(content);

        request.response
          ..headers.contentType = ContentType.json
          ..write(json.encode(response))
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    } catch (e) {
      print('❌ Error handling request: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal Server Error')
        ..close();
    }
  }

  Future<void> stop() async {
    if (!_isRunning) {
      print('⚠️ MCP Server is not running');
      return;
    }

    _isRunning = false;
    print('🛑 MCP Server stopped');
  }
}