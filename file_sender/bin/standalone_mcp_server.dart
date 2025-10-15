import 'dart:convert';
import 'dart:io';
import 'dart:math';

class StandaloneMCPServer {
  late Map<String, Function> _tools;
  bool _isRunning = false;

  Future<void> initialize() async {
    _tools = {
      // User Management Tools
      'register_user': _registerUser,
      'verify_user': _verifyUser,
      'authenticate_user': _authenticateUser,
      'get_user_info': _getUserInfo,
      'logout_user': _logoutUser,

      // Attendance Management Tools
      'mark_attendance': _markAttendance,
      'get_attendance_stats': _getAttendanceStats,
      'get_student_list': _getStudentList,
      'search_student': _searchStudent,

      // Face Recognition Tools
      'extract_face_embedding': _extractFaceEmbedding,
      'compare_faces': _compareFaces,
      'verify_face_match': _verifyFaceMatch,

      // System Management Tools
      'server_status': _getServerStatus,
      'get_registered_users': _getRegisteredUsers,
      'clear_local_data': _clearLocalData,
      'export_attendance_data': _exportAttendanceData,
    };

    print('🚀 Standalone MCP Server initialized with face authentication tools');
  }

  // Simulated user storage
  final Map<String, Map<String, dynamic>> _users = {};

  // User Management Methods
  Future<Map<String, dynamic>> _registerUser(Map<String, dynamic> params) async {
    try {
      final name = params['name'] as String?;
      final registrationNumber = params['registrationNumber'] as String?;
      final faceEmbedding = params['faceEmbedding'] as List<dynamic>?;

      if (name == null || registrationNumber == null || faceEmbedding == null) {
        throw Exception('Missing required parameters: name, registrationNumber, faceEmbedding');
      }

      _users[registrationNumber] = {
        'name': name,
        'registrationNumber': registrationNumber,
        'faceEmbedding': faceEmbedding.map((e) => (e as num).toDouble()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'deviceId': 'standalone_device_${Random().nextInt(100000)}',
      };

      return {
        'success': true,
        'message': 'User registered successfully',
        'registrationNumber': registrationNumber,
        'name': name,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyUser(Map<String, dynamic> params) async {
    try {
      final currentEmbedding = params['currentEmbedding'] as List<dynamic>?;
      final storedEmbedding = params['storedEmbedding'] as List<dynamic>?;

      if (currentEmbedding == null || storedEmbedding == null) {
        throw Exception('Missing required parameters: currentEmbedding, storedEmbedding');
      }

      final similarity = _calculateCosineSimilarity(
        currentEmbedding.map((e) => (e as num).toDouble()).toList(),
        storedEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      final isVerified = similarity >= 0.6;

      return {
        'success': true,
        'verified': isVerified,
        'similarity': similarity,
        'threshold': 0.6,
        'message': isVerified ? 'Face verification successful' : 'Face verification failed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  Future<Map<String, dynamic>> _authenticateUser(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw Exception('Missing required parameter: registrationNumber');
      }

      final userInfo = _users[registrationNumber];

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
      throw Exception('Failed to authenticate user: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw Exception('Missing required parameter: registrationNumber');
      }

      final userInfo = _users[registrationNumber];

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
          'createdAt': userInfo['createdAt'],
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  Future<Map<String, dynamic>> _logoutUser(Map<String, dynamic> params) async {
    return {
      'success': true,
      'message': 'User logged out successfully',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Attendance Management Methods
  Future<Map<String, dynamic>> _markAttendance(Map<String, dynamic> params) async {
    try {
      final registrationNumber = params['registrationNumber'] as String?;

      if (registrationNumber == null) {
        throw Exception('Missing required parameter: registrationNumber');
      }

      // Simulate server call
      await Future.delayed(Duration(milliseconds: 500));

      return {
        'success': true,
        'message': 'Attendance marked successfully',
        'registrationNumber': registrationNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'serverUrl': 'http://10.2.8.97:5000',
      };
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  Future<Map<String, dynamic>> _getAttendanceStats(Map<String, dynamic> params) async {
    // Simulate attendance stats
    await Future.delayed(Duration(milliseconds: 300));

    return {
      'success': true,
      'stats': {
        'totalStudents': _users.length,
        'presentToday': (_users.length * 0.7).round(),
        'absentToday': (_users.length * 0.3).round(),
        'attendanceRate': 70.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _getStudentList(Map<String, dynamic> params) async {
    await Future.delayed(Duration(milliseconds: 200));

    final students = _users.values.map((user) => {
      'name': user['name'],
      'registrationNumber': user['registrationNumber'],
      'present': Random().nextBool(),
      'timestamp': DateTime.now().toIso8601String(),
    }).toList();

    return {
      'success': true,
      'students': students,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _searchStudent(Map<String, dynamic> params) async {
    try {
      final query = params['query'] as String?;

      if (query == null || query.isEmpty) {
        throw Exception('Missing required parameter: query');
      }

      await Future.delayed(Duration(milliseconds: 200));

      final filteredStudents = _users.values.where((user) =>
        user['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
        user['registrationNumber'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();

      return {
        'success': true,
        'students': filteredStudents,
        'query': query,
        'count': filteredStudents.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to search students: $e');
    }
  }

  // Face Recognition Methods
  Future<Map<String, dynamic>> _extractFaceEmbedding(Map<String, dynamic> params) async {
    try {
      await Future.delayed(Duration(milliseconds: 1500)); // Simulate processing

      // Generate dummy embedding
      final embedding = List.generate(512, (index) => (Random().nextDouble() - 0.5) * 2.0);

      return {
        'success': true,
        'embedding': embedding,
        'embeddingSize': embedding.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to extract face embedding: $e');
    }
  }

  Future<Map<String, dynamic>> _compareFaces(Map<String, dynamic> params) async {
    try {
      final embedding1 = params['embedding1'] as List<dynamic>?;
      final embedding2 = params['embedding2'] as List<dynamic>?;

      if (embedding1 == null || embedding2 == null) {
        throw Exception('Missing required parameters: embedding1, embedding2');
      }

      final similarity = _calculateCosineSimilarity(
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
      throw Exception('Failed to compare faces: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyFaceMatch(Map<String, dynamic> params) async {
    try {
      final currentEmbedding = params['currentEmbedding'] as List<dynamic>?;
      final storedEmbedding = params['storedEmbedding'] as List<dynamic>?;
      final threshold = params['threshold'] as double? ?? 0.6;

      if (currentEmbedding == null || storedEmbedding == null) {
        throw Exception('Missing required parameters: currentEmbedding, storedEmbedding');
      }

      final similarity = _calculateCosineSimilarity(
        currentEmbedding.map((e) => (e as num).toDouble()).toList(),
        storedEmbedding.map((e) => (e as num).toDouble()).toList(),
      );

      final isVerified = similarity >= threshold;

      return {
        'success': true,
        'verified': isVerified,
        'similarity': similarity,
        'threshold': threshold,
        'match': similarity >= threshold,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to verify face match: $e');
    }
  }

  // System Management Methods
  Future<Map<String, dynamic>> _getServerStatus(Map<String, dynamic> params) async {
    return {
      'success': true,
      'status': {
        'server_running': _isRunning,
        'face_service_initialized': true,
        'registered_users_count': _users.length,
        'server_type': 'standalone',
        'server_url': 'http://10.2.8.97:5000',
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> _getRegisteredUsers(Map<String, dynamic> params) async {
    return {
      'success': true,
      'users': _users.values.toList(),
      'count': _users.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _clearLocalData(Map<String, dynamic> params) async {
    _users.clear();

    return {
      'success': true,
      'message': 'Local data cleared successfully',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _exportAttendanceData(Map<String, dynamic> params) async {
    await Future.delayed(Duration(milliseconds: 500));

    return {
      'success': true,
      'data': {
        'attendance_stats': {
          'totalStudents': _users.length,
          'presentToday': (_users.length * 0.7).round(),
          'absentToday': (_users.length * 0.3).round(),
          'attendanceRate': 70.0,
        },
        'export_timestamp': DateTime.now().toIso8601String(),
        'server_url': 'http://10.2.8.97:5000',
        'users_exported': _users.length,
      },
    };
  }

  double _calculateCosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  Future<void> startStdio() async {
    if (_isRunning) {
      print('⚠️ MCP Server is already running');
      return;
    }

    _isRunning = true;
    print('🚀 Face Authentication MCP Server started (standalone stdio mode)');
    print('📋 Available MCP Tools:');
    print('   📱 User Management: register_user, verify_user, authenticate_user, get_user_info, logout_user');
    print('   📊 Attendance: mark_attendance, get_attendance_stats, get_student_list, search_student');
    print('   🤖 Face Recognition: extract_face_embedding, compare_faces, verify_face_match');
    print('   ⚙️ System: server_status, get_registered_users, clear_local_data, export_attendance_data');

    try {
      await for (final line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
        if (line.trim().isEmpty) continue;

        Map<String, dynamic>? request;
        try {
          request = json.decode(line);
          final response = await _handleRequest(request!);
          print(json.encode(response));
        } catch (e) {
          final errorResponse = {
            'jsonrpc': '2.0',
            'id': request?['id'] ?? null,
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

  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> request) async {
    try {
      final method = request['method'] as String?;
      final params = request['params'] as Map<String, dynamic>? ?? {};
      final id = request['id'];

      if (method == null || !_tools.containsKey(method)) {
        return {
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32601,
            'message': 'Method not found: $method'
          }
        };
      }

      final result = await _tools[method]!(params);

      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': result
      };
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'id': request['id'] ?? null,
        'error': {
          'code': -32603,
          'message': 'Internal error: $e'
        }
      };
    }
  }
}

Future<void> main() async {
  print('🤖 Starting Standalone Face Authentication MCP Server...');

  final mcpServer = StandaloneMCPServer();

  try {
    await mcpServer.initialize();
    await mcpServer.startStdio();
  } catch (e, stackTrace) {
    print('❌ Failed to start MCP Server: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}