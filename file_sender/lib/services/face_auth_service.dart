import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceAuthService {
  static final FaceAuthService _instance = FaceAuthService._internal();
  factory FaceAuthService() => _instance;
  FaceAuthService._internal();

  final Logger _logger = Logger();
  late Interpreter _interpreter;
  late FaceDetector _faceDetector;
  String? _macAddress;
  bool _isInitialized = false;

  // Face recognition parameters
  static const double _faceThreshold = 0.6; // Similarity threshold
  static const int _embeddingSize = 512; // Expected embedding size

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite model
      final modelPath = 'assets/models/output_model.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _logger.i('TFLite model loaded successfully');

      // Initialize face detector
      final options = FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
      );
      _faceDetector = GoogleMlKit.vision.faceDetector(options);
      _logger.i('Face detector initialized');

      // Get MAC address
      await _getMacAddress();

      _isInitialized = true;
      _logger.i('FaceAuthService initialized successfully');
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

  Future<List<double>?> extractFaceEmbedding(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to Image
      final image = _convertCameraImage(cameraImage);

      // Detect faces
      final inputImage = InputImage.fromBytes(
        bytes: Uint8List.fromImage(image),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          planeData: [],
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _logger.w('No face detected in the image');
        return null;
      }

      // Use the first detected face
      final face = faces.first;

      // Extract face region
      final faceRect = face.boundingBox;
      final croppedFace = img.copyCrop(
        image,
        x: faceRect.left.toInt(),
        y: faceRect.top.toInt(),
        width: faceRect.width.toInt(),
        height: faceRect.height.toInt(),
      );

      // Preprocess face for model
      final preprocessedFace = _preprocessFace(croppedFace);

      // Run inference
      final output = List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);
      _interpreter.run(preprocessedFace, output);

      final embedding = output[0].cast<double>();
      _logger.d('Face embedding extracted successfully');

      return embedding;
    } catch (e) {
      _logger.e('Error extracting face embedding: $e');
      return null;
    }
  }

  img.Image _convertCameraImage(CameraImage cameraImage) {
    final image = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );
    return img.grayscale(image);
  }

  List<List<double>> _preprocessFace(img.Image face) {
    // Resize to model input size (assuming 112x112 for face recognition)
    final resized = img.copyResize(face, width: 112, height: 112);

    // Convert to normalized float array [1, 112, 112, 1]
    final input = List.generate(
      1 * 112 * 112 * 1,
      (index) => 0.0,
    ).reshape([1, 112, 112, 1]);

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0; // Normalize to [0, 1]
      }
    }

    return input;
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
      final similarity = calculateCosineSimilarity(currentEmbedding, storedEmbedding);
      _logger.d('Face similarity: $similarity');
      return similarity >= _faceThreshold;
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
      _faceDetector.close();
      _interpreter.close();
      _isInitialized = false;
      _logger.i('FaceAuthService disposed');
    }
  }
}