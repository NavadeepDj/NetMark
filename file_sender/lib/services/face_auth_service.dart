import 'dart:typed_data';
import 'tflite_interpreter.dart';
import 'face_registration_service.dart';

class FaceAuthService {
  static TfliteInterpreter? _interpreter;
  static bool _isModelLoaded = false;
  static const double _similarityThreshold = 0.6; // Adjust based on testing

  // Initialize the TensorFlow Lite model for authentication
  static Future<bool> initializeModel() async {
    try {
      if (_isModelLoaded) return true;

      // Use the same model as registration
      _interpreter = TfliteInterpreterIo();
      await _interpreter!.loadModel('assets/models/output_model.tflite');
      _isModelLoaded = true;
      print('✅ Face authentication model loaded successfully');
      return true;
    } catch (e) {
      print('❌ Error loading face authentication model: $e');
      return false;
    }
  }

  // Authenticate a face against a stored embedding
  static Future<bool> authenticateFace(
    Uint8List imageBytes,
    List<double> storedEmbedding,
  ) async {
    try {
      if (!_isModelLoaded || _interpreter == null) {
        bool loaded = await initializeModel();
        if (!loaded) return false;
      }

      // Generate embedding from current image
      List<double>? currentEmbedding =
          await FaceRegistrationService.generateFaceEmbedding(imageBytes);

      if (currentEmbedding == null ||
          !FaceRegistrationService.isValidEmbedding(currentEmbedding)) {
        print('❌ Failed to generate valid embedding for authentication');
        return false;
      }

      // Normalize both embeddings
      List<double> normalizedCurrent =
          FaceRegistrationService.normalizeEmbedding(currentEmbedding);
      List<double> normalizedStored =
          FaceRegistrationService.normalizeEmbedding(storedEmbedding);

      // Calculate similarity
      double similarity = FaceRegistrationService.calculateSimilarity(
          normalizedCurrent, normalizedStored);

      print('🔍 Authentication similarity: ${similarity.toStringAsFixed(3)}');
      print('🎯 Threshold: $_similarityThreshold');

      bool isAuthenticated = similarity >= _similarityThreshold;

      if (isAuthenticated) {
        print('✅ Face authentication successful');
      } else {
        print('❌ Face authentication failed - similarity too low');
      }

      return isAuthenticated;
    } catch (e) {
      print('❌ Error during face authentication: $e');
      return false;
    }
  }

  // Batch authenticate against multiple stored embeddings
  static Future<Map<String, double>> authenticateAgainstMultiple(
    Uint8List imageBytes,
    Map<String, List<double>> storedEmbeddings,
  ) async {
    try {
      if (!_isModelLoaded || _interpreter == null) {
        bool loaded = await initializeModel();
        if (!loaded) return {};
      }

      // Generate embedding from current image
      List<double>? currentEmbedding =
          await FaceRegistrationService.generateFaceEmbedding(imageBytes);

      if (currentEmbedding == null ||
          !FaceRegistrationService.isValidEmbedding(currentEmbedding)) {
        print('❌ Failed to generate valid embedding for batch authentication');
        return {};
      }

      // Normalize current embedding
      List<double> normalizedCurrent =
          FaceRegistrationService.normalizeEmbedding(currentEmbedding);

      Map<String, double> similarities = {};

      for (String userId in storedEmbeddings.keys) {
        List<double> storedEmbedding = storedEmbeddings[userId]!;
        List<double> normalizedStored =
            FaceRegistrationService.normalizeEmbedding(storedEmbedding);

        double similarity = FaceRegistrationService.calculateSimilarity(
            normalizedCurrent, normalizedStored);
        similarities[userId] = similarity;

        print('🔍 Similarity with $userId: ${similarity.toStringAsFixed(3)}');
      }

      return similarities;
    } catch (e) {
      print('❌ Error during batch face authentication: $e');
      return {};
    }
  }

  // Find the best match from multiple stored embeddings
  static Future<String?> findBestMatch(
    Uint8List imageBytes,
    Map<String, List<double>> storedEmbeddings,
  ) async {
    try {
      Map<String, double> similarities =
          await authenticateAgainstMultiple(imageBytes, storedEmbeddings);

      if (similarities.isEmpty) {
        return null;
      }

      // Find the user with highest similarity
      String? bestMatch;
      double highestSimilarity = 0.0;

      for (String userId in similarities.keys) {
        double similarity = similarities[userId]!;
        if (similarity > highestSimilarity &&
            similarity >= _similarityThreshold) {
          highestSimilarity = similarity;
          bestMatch = userId;
        }
      }

      if (bestMatch != null) {
        print(
            '✅ Best match found: $bestMatch with similarity ${highestSimilarity.toStringAsFixed(3)}');
      } else {
        print('❌ No match found above threshold');
      }

      return bestMatch;
    } catch (e) {
      print('❌ Error finding best match: $e');
      return null;
    }
  }

  // Set custom similarity threshold
  static void setSimilarityThreshold(double threshold) {
    if (threshold >= 0.0 && threshold <= 1.0) {
      print('🎯 Similarity threshold updated to: $threshold');
    } else {
      print('❌ Invalid threshold value. Must be between 0.0 and 1.0');
    }
  }

  // Get current similarity threshold
  static double getSimilarityThreshold() {
    return _similarityThreshold;
  }

  // Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}