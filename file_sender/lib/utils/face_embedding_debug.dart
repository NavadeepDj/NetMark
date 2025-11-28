import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

class FaceEmbeddingDebug {
  static final Logger _logger = Logger();

  static Future<void> showAllStoredData() async {
    _logger.i('🔍 === FACE EMBEDDING STORAGE DEBUG ===');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys
      final keys = prefs.getKeys();
      _logger.i('📱 Available SharedPreferences keys:');
      for (final key in keys) {
        final value = prefs.get(key);
        if (key == 'faceEmbedding' && value is List<String>) {
          final embedding = value.map((e) => double.tryParse(e) ?? 0.0).toList();
          _logger.i('   • $key: [${embedding.take(10).map((v) => v.toStringAsFixed(4)).join(', ')}...] (${embedding.length} total)');
        } else {
          _logger.i('   • $key: $value');
        }
      }

      // Show face embedding details
      final faceEmbeddingList = prefs.getStringList('faceEmbedding');
      if (faceEmbeddingList != null) {
        final embedding = faceEmbeddingList.map((e) => double.tryParse(e) ?? 0.0).toList();

        _logger.i('🎯 FACE EMBEDDING ANALYSIS:');
        _logger.i('   • Total dimensions: ${embedding.length}');
        _logger.i('   • Min value: ${embedding.reduce((a, b) => a < b ? a : b).toStringAsFixed(4)}');
        _logger.i('   • Max value: ${embedding.reduce((a, b) => a > b ? a : b).toStringAsFixed(4)}');
        _logger.i('   • Average: ${(embedding.reduce((a, b) => a + b) / embedding.length).toStringAsFixed(4)}');
        _logger.i('   • First 20 values: ${embedding.take(20).map((v) => v.toStringAsFixed(4)).join(', ')}');

        // Calculate checksum for verification
        final checksum = embedding.map((v) => v.toStringAsFixed(2)).join('|');
        _logger.i('   • Checksum: ${checksum.hashCode}');
      } else {
        _logger.w('❌ No face embedding found in local storage!');
      }

      _logger.i('📍 STORAGE LOCATIONS:');
      _logger.i('   • Local Storage: SharedPreferences (app data)');
      _logger.i('   • Cloud Storage: Firebase Firestore (collection: "users")');
      _logger.i('   • Device Binding: Device ID verification required');

    } catch (e) {
      _logger.e('Error debugging face embeddings: $e');
    }

    _logger.i('=== END DEBUG INFO ===');
  }
}