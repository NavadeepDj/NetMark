import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String _studentsCollection = 'students';
  static const String _loginAttemptsCollection = 'loginAttempts';
  static const String _attendanceCollection = 'attendance';
  static const String _classesCollection = 'classes';
  static const String _facultyCollection = 'faculty';

  // ==================== UTILITY METHODS ====================

  /// Sanitize a string to be used as a Firestore document ID
  static String _sanitizeDocumentId(String input) {
    // Remove special characters and replace spaces with underscores
    String sanitized = input
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .toLowerCase(); // Convert to lowercase

    // Ensure it doesn't start with a number
    if (sanitized.isNotEmpty && RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = 'student_$sanitized';
    }

    // Ensure it's not empty
    if (sanitized.isEmpty) {
      sanitized = 'student_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Limit length to 150 characters (Firestore limit)
    if (sanitized.length > 150) {
      sanitized = sanitized.substring(0, 150);
    }

    return sanitized;
  }

  // ==================== STUDENT OPERATIONS ====================

  /// Create a new student document
  static Future<String> createStudent({
    required String email,
    required String name,
    required String registrationNumber,
    required String firebaseUid,
    List<double>? faceEmbedding,
    String? department,
    String? year,
    String? phoneNumber,
  }) async {
    try {
      // Use student name as document ID (sanitized for Firestore)
      String documentId = _sanitizeDocumentId(name);

      // Check if document already exists
      final existingDoc =
          await _db.collection(_studentsCollection).doc(documentId).get();
      if (existingDoc.exists) {
        // If document exists, append registration number to make it unique
        documentId = '${documentId}_$registrationNumber';
      }

      final studentRef = _db.collection(_studentsCollection).doc(documentId);

      final studentData = {
        'profile': {
          'email': email,
          'name': name,
          'registrationNumber': registrationNumber,
          'firebaseUid': firebaseUid,
          'signupDate': FieldValue.serverTimestamp(),
          'lastLogin': null,
          'isActive': true,
          'role': 'student',
          'department': department ?? '',
          'year': year ?? '',
          'phoneNumber': phoneNumber ?? '',
        },
        'faceData': faceEmbedding != null
            ? {
                'embedding': faceEmbedding,
                'embeddingSize': 128,
                'registeredAt': FieldValue.serverTimestamp(),
                'isVerified': true,
                'confidence': 0.95,
              }
            : null,
        'preferences': {
          'notifications': true,
          'faceLoginEnabled': faceEmbedding != null,
          'theme': 'dark',
        },
      };

      await studentRef.set(studentData);
      print('✅ Student created with ID: ${studentRef.id}');
      return studentRef.id;
    } catch (e) {
      print('❌ Error creating student: $e');
      throw Exception('Failed to create student: $e');
    }
  }

  /// Get student by Firebase UID
  static Future<Map<String, dynamic>?> getStudentByFirebaseUid(
      String firebaseUid) async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.firebaseUid', isEqualTo: firebaseUid)
          .where('profile.isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error getting student by Firebase UID: $e');
      return null;
    }
  }

  /// Get student by name (using document ID)
  static Future<Map<String, dynamic>?> getStudentByName(String name) async {
    try {
      String documentId = _sanitizeDocumentId(name);
      final doc =
          await _db.collection(_studentsCollection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error getting student by name: $e');
      return null;
    }
  }

  /// Get student by registration number
  static Future<Map<String, dynamic>?> getStudentByRegNumber(
      String registrationNumber) async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.registrationNumber', isEqualTo: registrationNumber)
          .where('profile.isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error getting student by registration number: $e');
      return null;
    }
  }

  /// Get all students with face data for face recognition
  static Future<List<Map<String, dynamic>>> getAllStudentsWithFaceData() async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.isActive', isEqualTo: true)
          .get();

      final studentsWithFaceData = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['faceData'] != null && data['faceData']['embedding'] != null) {
          data['id'] = doc.id;
          studentsWithFaceData.add(data);
        }
      }

      return studentsWithFaceData;
    } catch (e) {
      print('❌ Error getting students with face data: $e');
      return [];
    }
  }

  /// Get face embeddings mapped to registration numbers for face recognition
  static Future<Map<String, List<double>>>
      getFaceEmbeddingsByRegNumber() async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.isActive', isEqualTo: true)
          .get();

      final embeddingsByRegNumber = <String, List<double>>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['faceData'] != null &&
            data['faceData']['embedding'] != null &&
            data['profile']['registrationNumber'] != null) {
          String regNumber = data['profile']['registrationNumber'];
          List<double> embedding =
              List<double>.from(data['faceData']['embedding']);
          embeddingsByRegNumber[regNumber] = embedding;
        }
      }

      print(
          '✅ Loaded ${embeddingsByRegNumber.length} face embeddings by registration number');
      return embeddingsByRegNumber;
    } catch (e) {
      print('❌ Error getting face embeddings by registration number: $e');
      return {};
    }
  }

  /// Update student's last login time
  static Future<void> updateLastLogin(String studentId) async {
    try {
      await _db.collection(_studentsCollection).doc(studentId).update({
        'profile.lastLogin': FieldValue.serverTimestamp(),
      });
      print('✅ Last login updated for student: $studentId');
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  /// Update student's face data
  static Future<void> updateFaceData(
      String studentId, List<double> faceEmbedding) async {
    try {
      await _db.collection(_studentsCollection).doc(studentId).update({
        'faceData': {
          'embedding': faceEmbedding,
          'embeddingSize': 128,
          'registeredAt': FieldValue.serverTimestamp(),
          'isVerified': true,
          'confidence': 0.95,
        },
        'preferences.faceLoginEnabled': true,
      });
      print('✅ Face data updated for student: $studentId');
    } catch (e) {
      print('❌ Error updating face data: $e');
      throw Exception('Failed to update face data: $e');
    }
  }

  /// Update student's face data by name
  static Future<void> updateFaceDataByName(
      String studentName, List<double> faceEmbedding) async {
    try {
      String documentId = _sanitizeDocumentId(studentName);
      await _db.collection(_studentsCollection).doc(documentId).update({
        'faceData': {
          'embedding': faceEmbedding,
          'embeddingSize': 128,
          'registeredAt': FieldValue.serverTimestamp(),
          'isVerified': true,
          'confidence': 0.95,
        },
        'preferences.faceLoginEnabled': true,
      });
      print('✅ Face data updated for student: $studentName (ID: $documentId)');
    } catch (e) {
      print('❌ Error updating face data by name: $e');
      throw Exception('Failed to update face data: $e');
    }
  }

  // ==================== LOGIN ATTEMPTS ====================

  /// Record a login attempt
  static Future<void> recordLoginAttempt({
    required String email,
    required String status, // 'success', 'failed', 'blocked'
    String? studentId,
    String? failureReason,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      await _db.collection(_loginAttemptsCollection).add({
        'studentId': studentId,
        'email': email,
        'ipAddress': ipAddress ?? 'unknown',
        'userAgent': userAgent ?? 'unknown',
        'attemptStatus': status,
        'failureReason': failureReason,
        'attemptedAt': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo ?? {},
      });
      print('✅ Login attempt recorded: $status for $email');
    } catch (e) {
      print('❌ Error recording login attempt: $e');
    }
  }

  /// Check for suspicious login activity
  static Future<int> checkSuspiciousActivity(String email,
      {int timeWindowMinutes = 15}) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(minutes: timeWindowMinutes));

      final querySnapshot = await _db
          .collection(_loginAttemptsCollection)
          .where('email', isEqualTo: email)
          .where('attemptStatus', isEqualTo: 'failed')
          .where('attemptedAt', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error checking suspicious activity: $e');
      return 0;
    }
  }

  // ==================== ATTENDANCE ====================

  /// Record attendance
  static Future<String> recordAttendance({
    required String studentId,
    required String classId,
    required String className,
    required String status, // 'present', 'absent', 'late'
    required String method, // 'face_recognition', 'manual'
    double? confidence,
    Map<String, dynamic>? location,
    String? facultyId,
    String? remarks,
  }) async {
    try {
      final attendanceRef = _db.collection(_attendanceCollection).doc();

      await attendanceRef.set({
        'studentId': studentId,
        'classId': classId,
        'className': className,
        'attendanceDate': FieldValue.serverTimestamp(),
        'status': status,
        'method': method,
        'confidence': confidence,
        'location': location ?? {},
        'facultyId': facultyId ?? '',
        'remarks': remarks ?? '',
      });

      print('✅ Attendance recorded for student: $studentId');
      return attendanceRef.id;
    } catch (e) {
      print('❌ Error recording attendance: $e');
      throw Exception('Failed to record attendance: $e');
    }
  }

  /// Get student's attendance records
  static Future<List<Map<String, dynamic>>> getStudentAttendance(
      String studentId,
      {int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection(_attendanceCollection)
          .where('studentId', isEqualTo: studentId)
          .orderBy('attendanceDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting student attendance: $e');
      return [];
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Calculate cosine similarity for face recognition
  static double calculateCosineSimilarity(
      List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embeddings must have the same length');
    }

    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  /// Find student by face similarity
  static Future<Map<String, dynamic>?> findStudentByFaceSimilarity(
    List<double> capturedEmbedding, {
    double threshold = 0.75,
  }) async {
    try {
      final studentsWithFaceData = await getAllStudentsWithFaceData();

      for (final student in studentsWithFaceData) {
        final storedEmbedding =
            List<double>.from(student['faceData']['embedding']);
        final similarity =
            calculateCosineSimilarity(capturedEmbedding, storedEmbedding);

        if (similarity >= threshold) {
          print(
              '✅ Face match found with similarity: ${similarity.toStringAsFixed(4)}');
          return student;
        }
      }

      print('❌ No face match found above threshold: $threshold');
      return null;
    } catch (e) {
      print('❌ Error finding student by face similarity: $e');
      return null;
    }
  }

  /// Get student statistics
  static Future<Map<String, int>> getStudentStatistics() async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.isActive', isEqualTo: true)
          .get();

      int totalStudents = querySnapshot.docs.length;
      int studentsWithFace = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['faceData'] != null && data['faceData']['embedding'] != null) {
          studentsWithFace++;
        }
      }

      return {
        'totalStudents': totalStudents,
        'studentsWithFace': studentsWithFace,
        'studentsWithoutFace': totalStudents - studentsWithFace,
      };
    } catch (e) {
      print('❌ Error getting student statistics: $e');
      return {
        'totalStudents': 0,
        'studentsWithFace': 0,
        'studentsWithoutFace': 0
      };
    }
  }

  // ==================== SEARCH FUNCTIONS ====================

  /// Search students by name
  static Future<List<Map<String, dynamic>>> searchStudentsByName(
      String name) async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.isActive', isEqualTo: true)
          .get();

      final results = <Map<String, dynamic>>[];
      final searchName = name.toLowerCase();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final studentName = data['profile']['name'].toString().toLowerCase();

        if (studentName.contains(searchName)) {
          data['id'] = doc.id;
          results.add(data);
        }
      }

      return results;
    } catch (e) {
      print('❌ Error searching students by name: $e');
      return [];
    }
  }

  /// Search students by registration number
  static Future<List<Map<String, dynamic>>> searchStudentsByRegNumber(
      String regNumber) async {
    try {
      final querySnapshot = await _db
          .collection(_studentsCollection)
          .where('profile.registrationNumber', isEqualTo: regNumber)
          .where('profile.isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error searching students by registration number: $e');
      return [];
    }
  }
}
