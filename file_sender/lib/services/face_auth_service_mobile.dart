import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FaceAuthService {
  static final FaceAuthService _instance = FaceAuthService._internal();
  factory FaceAuthService() => _instance;
  FaceAuthService._internal();

  final Logger _logger = Logger();
  String? _macAddress;
  String? _deviceId;
  bool _isInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to obtain a stable device identifier (Android ID / identifierForVendor)
      if (!kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        try {
          final androidInfo = await deviceInfo.androidInfo;
          _deviceId = androidInfo.id; // stable ANDROID_ID
        } catch (_) {
          try {
            final iosInfo = await deviceInfo.iosInfo;
            _deviceId = iosInfo.identifierForVendor;
          } catch (_) {
            _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
          }
        }
      } else {
        _deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
      // keep legacy macAddress variable for compatibility
      _macAddress = _deviceId;
      _isInitialized = true;
      _logger.i('FaceAuthService initialized successfully (mobile version)');
    } catch (e) {
      _logger.e('Error initializing FaceAuthService: $e');
      rethrow;
    }
  }

  // Simulated face embedding extraction (for mobile testing)
  Future<List<double>?> extractFaceEmbedding() async {
    try {
      // Simulate face processing delay
      await Future.delayed(Duration(milliseconds: 1500));

      // Generate deterministic dummy embedding based on device ID
      final seed = _macAddress?.hashCode ?? 0;
      final random = Random(seed);

      final embedding = List.generate(512, (index) {
        // Create a consistent embedding for the same device
        return (random.nextDouble() - 0.5) * 2.0;
      });

      _logger.d('Face embedding extracted successfully (simulated mobile)');
      return embedding;
    } catch (e) {
      _logger.e('Error extracting face embedding: $e');
      return null;
    }
  }

  double calculateCosineSimilarity(List<double> embedding1, List<double> embedding2) {
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

  Future<bool> verifyFace(List<double> currentEmbedding, List<double> storedEmbedding) async {
    try {
      // Simulate verification delay
      await Future.delayed(Duration(milliseconds: 1000));

      // For mobile testing, always return true if we have embeddings
      final similarity = calculateCosineSimilarity(currentEmbedding, storedEmbedding);
      _logger.d('Face similarity: $similarity');

      // For testing, we'll accept higher threshold
      return similarity >= 0.3; // Lower threshold for testing
    } catch (e) {
      _logger.e('Error verifying face: $e');
      return false;
    }
  }

  Future<void> registerUser({
    required String name,
    required String registrationNumber,
    required List<double> faceEmbedding,
  }) async {
    try {
      // Store locally for demo (without Firebase for mobile testing)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRegNo', registrationNumber);
      await prefs.setString('userName', name);
      if (_deviceId != null) await prefs.setString('macAddress', _deviceId!);
      await prefs.setStringList('faceEmbedding', faceEmbedding.map((e) => e.toString()).toList());

      _logger.i('User registered successfully: $registrationNumber');

      // Attempt to write to Firestore (best-effort)
      try {
        final userDoc = _firestore.collection('users').doc(registrationNumber);
        await userDoc.set({
          'name': name,
          'registrationNumber': registrationNumber,
          'deviceId': _deviceId,
          'faceEmbedding': faceEmbedding,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _logger.i('User saved to Firestore: $registrationNumber');
      } catch (e) {
        _logger.w('Failed to save user to Firestore (continuing local only): $e');
      }
    } catch (e) {
      _logger.e('Error registering user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> authenticateUser(String registrationNumber) async {
    try {
      // Try local storage
      final prefs = await SharedPreferences.getInstance();
      final localRegNo = prefs.getString('userRegNo');
      final localMacAddress = prefs.getString('macAddress');

      if (localRegNo == registrationNumber && localMacAddress == _macAddress) {
        final localEmbeddingList = prefs.getStringList('faceEmbedding');
        if (localEmbeddingList != null) {
          final localEmbedding = localEmbeddingList.map((e) => double.parse(e)).toList();
          return {
            'name': prefs.getString('userName'),
            'registrationNumber': registrationNumber,
            'faceEmbedding': localEmbedding,
            'isLocal': true,
          };
        }
      }

      // If not in local cache, attempt Firestore lookup
      try {
        final doc = await _firestore.collection('users').doc(registrationNumber).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final embeddingRaw = data['faceEmbedding'];
            List<double> embedding = [];
            if (embeddingRaw is List) {
              embedding = embeddingRaw.map((e) => (e as num).toDouble()).toList();
            }

            // cache locally for offline use
            await prefs.setString('userRegNo', registrationNumber);
            await prefs.setString('userName', data['name'] ?? '');
            if (data['deviceId'] != null) await prefs.setString('macAddress', data['deviceId']);
            await prefs.setStringList('faceEmbedding', embedding.map((e) => e.toString()).toList());

            return {
              'name': data['name'],
              'registrationNumber': registrationNumber,
              'faceEmbedding': embedding,
              'isLocal': false,
            };
          }
        }
      } catch (e) {
        _logger.w('Firestore lookup failed: $e');
      }

      return null;
    } catch (e) {
      _logger.e('Error authenticating user: $e');
      return null;
    }
  }

  Future<bool> isUserRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRegNo = prefs.getString('userRegNo');
      final localMacAddress = prefs.getString('macAddress');

      return localRegNo != null && localMacAddress == _macAddress;
    } catch (e) {
      _logger.e('Error checking user registration: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserRegNo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userRegNo');
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _isInitialized = false;
      _logger.i('FaceAuthService disposed');
    }
  }
}