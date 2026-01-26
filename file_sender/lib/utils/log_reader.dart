import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Utility class to read face verification logs from CSV file
class LogReader {
  /// Read logs from CSV file, trying multiple possible locations
  static Future<List<Map<String, String>>> readLogs({int limit = 50}) async {
    List<File> possibleFiles = [];

    // Try project root first
    try {
      final rootFile = File('logs.csv');
      if (await rootFile.exists()) {
        possibleFiles.add(rootFile);
      }
    } catch (e) {
      // Ignore if we can't access project root
    }

    // Try app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appFile = File('${directory.path}/logs.csv');
      if (await appFile.exists()) {
        possibleFiles.add(appFile);
      }
    } catch (e) {
      // Ignore if we can't access app directory
    }

    if (possibleFiles.isEmpty) {
      return [];
    }

    // Read from the first available file
    final file = possibleFiles.first;
    try {
      final content = await file.readAsString();
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.length <= 1) {
        // Only header or empty
        return [];
      }

      // Skip header and parse data lines
      final logs = <Map<String, String>>[];
      for (int i = 1; i < lines.length && logs.length < limit; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 3) {
          logs.add({
            'registrationNumber': parts[0],
            'timestamp': parts[1],
            'timeSeconds': parts[2],
            'filePath': file.path,
          });
        }
      }

      // Return most recent first
      return logs.reversed.toList();
    } catch (e) {
      print('Error reading logs: $e');
      return [];
    }
  }

  /// Get the path where logs are being written
  static Future<String?> getLogFilePath() async {
    // Try project root first
    try {
      final rootFile = File('logs.csv');
      if (await rootFile.exists()) {
        return rootFile.absolute.path;
      }
    } catch (e) {
      // Ignore
    }

    // Try app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appFile = File('${directory.path}/logs.csv');
      if (await appFile.exists()) {
        return appFile.absolute.path;
      }
    } catch (e) {
      // Ignore
    }

    return null;
  }
}
