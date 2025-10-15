import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class FaceAuthService {
  static final FaceAuthService _instance = FaceAuthService._internal();
  factory FaceAuthService() => _instance;
  FaceAuthService._internal();

  final Logger _logger = Logger();
  String? _macAddress;
  bool _isInitialized = false;

  // Face recognition parameters
  static const double _faceThreshold = 0.6;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get MAC address
      await _getMacAddress();
      _isInitialized = true;
      _logger.i('FaceAuthService initialized successfully (simplified version)');
    } catch (e) {
      _logger.e('Error initializing FaceAuthService: $e');
      rethrow;
    }
  }

  Future<void> _getMacAddress() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _macAddress = androidInfo.id; // Use Android ID as unique identifier
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _macAddress = iosInfo.identifierForVendor; // Use IDFV as unique identifier
      }

      _logger.i('Device identifier: $_macAddress');
    } catch (e) {
      _logger.e('Error getting device identifier: $e');
      _macAddress = 'unknown';
    }
  }

  // Simulated face embedding extraction (for testing without ML Kit)
  Future<List<double>?> extractFaceEmbedding(String? imagePath) async {
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

      _logger.d('Face embedding extracted successfully (simulated)');
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

      // For demo purposes, always return true if we have embeddings
      // In real implementation, this would use actual face comparison
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
      // Store in Firestore
      final CollectionReference users = FirebaseFirestore.instance.collection('users');

      await users.doc(registrationNumber).set({
        'name': name,
        'registrationNumber': registrationNumber,
        'macAddress': _macAddress,
        'faceEmbedding': faceEmbedding,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isVerified': true,
      });

      // Store locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRegNo', registrationNumber);
      await prefs.setString('userName', name);
      await prefs.setString('macAddress', _macAddress!);
      await prefs.setStringList('faceEmbedding', faceEmbedding.map((e) => e.toString()).toList());

      _logger.i('User registered successfully: $registrationNumber');
    } catch (e) {
      _logger.e('Error registering user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> authenticateUser(String registrationNumber) async {
    try {
      // Try local storage first (offline)
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

      // Try Firestore (online)
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(registrationNumber)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Verify MAC address matches
        if (data['macAddress'] == _macAddress) {
          // Update local cache
          await prefs.setString('userRegNo', registrationNumber);
          await prefs.setString('userName', data['name']);
          await prefs.setString('macAddress', _macAddress!);

          if (data['faceEmbedding'] != null) {
            final embeddingList = List<String>.from(
              data['faceEmbedding'].map((e) => e.toString())
            );
            await prefs.setStringList('faceEmbedding', embeddingList);
          }

          return {
            'name': data['name'],
            'registrationNumber': registrationNumber,
            'faceEmbedding': List<double>.from(data['faceEmbedding']),
            'isLocal': false,
          };
        } else {
          _logger.w('MAC address mismatch for user: $registrationNumber');
          return null;
        }
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