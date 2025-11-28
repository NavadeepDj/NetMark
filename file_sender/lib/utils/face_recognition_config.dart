import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class FaceRecognitionConfig {
  static const String _thresholdKey = 'face_threshold';
  static const String _strictModeKey = 'strict_verification_mode';
  static final Logger _logger = Logger();

  static Future<double> getThreshold() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_thresholdKey) ?? 0.75;
    } catch (e) {
      _logger.e('Error getting threshold: $e');
      return 0.75;
    }
  }

  static Future<void> setThreshold(double threshold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_thresholdKey, threshold.clamp(0.5, 0.95));
      _logger.i('Face recognition threshold updated to: ${threshold.clamp(0.5, 0.95)}');
    } catch (e) {
      _logger.e('Error setting threshold: $e');
    }
  }

  static Future<bool> getStrictMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_strictModeKey) ?? false;
    } catch (e) {
      _logger.e('Error getting strict mode: $e');
      return false;
    }
  }

  static Future<void> setStrictMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_strictModeKey, enabled);
      _logger.i('Strict verification mode: ${enabled ? 'ENABLED' : 'DISABLED'}');
    } catch (e) {
      _logger.e('Error setting strict mode: $e');
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    return {
      'threshold': await getThreshold(),
      'strictMode': await getStrictMode(),
    };
  }
}