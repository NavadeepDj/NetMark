import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class StorageManager {
  static final Logger _logger = Logger();

  // Keys used for storage
  static const String FACE_EMBEDDING_KEY = 'faceEmbedding';
  static const String ADDITIONAL_EMBEDDINGS_KEY = 'additionalFaceEmbeddings';
  static const String USER_REG_NO_KEY = 'userRegNo';
  static const String USER_NAME_KEY = 'userName';
  static const String DEVICE_ID_KEY = 'deviceId';

  /// Show all stored face recognition data
  static Future<void> showAllStoredData() async {
    _logger.i('📱 === FACE RECOGNITION STORAGE ANALYSIS ===');

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      _logger.i('🔑 All SharedPreferences Keys (${keys.length} total):');
      for (final key in keys) {
        final value = prefs.get(key);

        if (key == FACE_EMBEDDING_KEY && value is List<String>) {
          final embedding = value.map((e) => double.tryParse(e) ?? 0.0).toList();
          _logger.i('   • $key: ${embedding.length} double values');
          _logger.i('     Sample: [${embedding.take(5).map((v) => v.toStringAsFixed(4)).join(', ')}...]');
        } else if (key == ADDITIONAL_EMBEDDINGS_KEY && value is List<String>) {
          _logger.i('   • $key: ${value.length} additional embeddings stored');
        } else {
          _logger.i('   • $key: $value');
        }
      }

      // Detailed analysis of face embedding
      await _analyzeFaceEmbedding();

      _logger.i('💾 Storage Location Analysis:');
      _logger.i('   • Platform: ${_getPlatform()}');
      _logger.i('   • App Package: com.example.file_sender');
      _logger.i('   • Storage Type: SharedPreferences');
      _logger.i('   • Max Storage: ~1-10 MB per app');
      _logger.i('   • Persistence: Survives app restarts');

    } catch (e) {
      _logger.e('Error analyzing storage: $e');
    }

    _logger.i('=== END STORAGE ANALYSIS ===');
  }

  /// Analyze the stored face embedding in detail
  static Future<void> _analyzeFaceEmbedding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final faceEmbeddingList = prefs.getStringList(FACE_EMBEDDING_KEY);

      if (faceEmbeddingList != null && faceEmbeddingList.isNotEmpty) {
        final embedding = faceEmbeddingList.map((e) => double.tryParse(e) ?? 0.0).toList();

        _logger.i('🎯 FACE EMBEDDING ANALYSIS:');
        _logger.i('   • Dimensions: ${embedding.length}');
        _logger.i('   • Min Value: ${embedding.reduce((a, b) => a < b ? a : b).toStringAsFixed(4)}');
        _logger.i('   • Max Value: ${embedding.reduce((a, b) => a > b ? a : b).toStringAsFixed(4)}');
        _logger.i('   • Average: ${(embedding.reduce((a, b) => a + b) / embedding.length).toStringAsFixed(4)}');
        _logger.i('   • Checksum: ${embedding.map((v) => v.toStringAsFixed(2)).join('|').hashCode}');
        _logger.i('   • Storage Size: ~${(embedding.length * 8).toString()} bytes');

        // Show histogram of values
        final buckets = _createHistogram(embedding);
        _logger.i('   • Distribution: ${buckets.entries.take(5).map((e) => '${e.key}: ${e.value}').join(', ')}...');

      } else {
        _logger.w('❌ No face embedding found in storage!');
      }
    } catch (e) {
      _logger.e('Error analyzing face embedding: $e');
    }
  }

  /// Create histogram of embedding values
  static Map<String, int> _createHistogram(List<double> embedding) {
    final histogram = <String, int>{};
    for (final value in embedding) {
      final range = (value * 5).floor();
      final key = '${range * 0.2}-${(range + 1) * 0.2}';
      histogram[key] = (histogram[key] ?? 0) + 1;
    }
    return histogram;
  }

  /// Clear all face recognition data
  static Future<bool> clearAllFaceData() async {
    try {
      _logger.i('🗑️ Clearing all face recognition data...');

      final prefs = await SharedPreferences.getInstance();

      // Remove each face recognition key
      await prefs.remove(FACE_EMBEDDING_KEY);
      await prefs.remove(ADDITIONAL_EMBEDDINGS_KEY);
      await prefs.remove(USER_REG_NO_KEY);
      await prefs.remove(USER_NAME_KEY);
      await prefs.remove(DEVICE_ID_KEY);

      _logger.i('✅ All face recognition data cleared successfully');
      return true;

    } catch (e) {
      _logger.e('Error clearing face data: $e');
      return false;
    }
  }

  /// Clear only face embeddings (keep user info)
  static Future<bool> clearFaceEmbeddings() async {
    try {
      _logger.i('🗑️ Clearing face embeddings only...');

      final prefs = await SharedPreferences.getInstance();

      // Remove only embedding keys
      await prefs.remove(FACE_EMBEDDING_KEY);
      await prefs.remove(ADDITIONAL_EMBEDDINGS_KEY);

      _logger.i('✅ Face embeddings cleared (user info preserved)');
      return true;

    } catch (e) {
      _logger.e('Error clearing face embeddings: $e');
      return false;
    }
  }

  /// Clear additional face embeddings only
  static Future<bool> clearAdditionalEmbeddings() async {
    try {
      _logger.i('🗑️ Clearing additional face embeddings...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ADDITIONAL_EMBEDDINGS_KEY);

      _logger.i('✅ Additional face embeddings cleared');
      return true;

    } catch (e) {
      _logger.e('Error clearing additional embeddings: $e');
      return false;
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final faceEmbeddingList = prefs.getStringList(FACE_EMBEDDING_KEY);
      final additionalEmbeddings = prefs.getStringList(ADDITIONAL_EMBEDDINGS_KEY);

      int totalSize = 0;
      if (faceEmbeddingList != null) {
        totalSize += faceEmbeddingList.length * 8; // 8 bytes per double as string
      }
      if (additionalEmbeddings != null) {
        totalSize += additionalEmbeddings.length * 8;
      }

      return {
        'totalKeys': prefs.getKeys().length,
        'mainEmbeddingSize': faceEmbeddingList?.length ?? 0,
        'additionalEmbeddingsCount': additionalEmbeddings?.length ?? 0,
        'totalBytesUsed': totalSize,
        'approximateKB': (totalSize / 1024).toStringAsFixed(2),
      };

    } catch (e) {
      _logger.e('Error getting storage stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get platform information
  static String _getPlatform() {
    return 'Android'; // Can be extended for iOS/web
  }
}