import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FaceDatabaseService {
  static const String _faceEmbeddingsFile = 'face_embeddings.json';
  static const String _userDataFile = 'user_data.json';
  
  // Store face embedding for a user
  static Future<bool> storeFaceEmbedding(String userId, List<double> embedding) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_faceEmbeddingsFile');
      
      Map<String, dynamic> data = {};
      
      // Load existing data if file exists
      if (await file.exists()) {
        final contents = await file.readAsString();
        data = json.decode(contents);
      }
      
      // Store the embedding
      data[userId] = embedding;
      
      // Save back to file
      await file.writeAsString(json.encode(data));
      
      print('✅ Face embedding stored for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error storing face embedding: $e');
      return false;
    }
  }
  
  // Retrieve face embedding for a user
  static Future<List<double>?> getFaceEmbedding(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_faceEmbeddingsFile');
      
      if (!await file.exists()) {
        print('❌ Face embeddings file not found');
        return null;
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      if (data.containsKey(userId)) {
        List<dynamic> embeddingList = data[userId];
        List<double> embedding = embeddingList.cast<double>();
        print('✅ Face embedding retrieved for user: $userId');
        return embedding;
      } else {
        print('❌ No face embedding found for user: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error retrieving face embedding: $e');
      return null;
    }
  }
  
  // Get all stored face embeddings
  static Future<Map<String, List<double>>> getAllFaceEmbeddings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_faceEmbeddingsFile');
      
      if (!await file.exists()) {
        print('❌ Face embeddings file not found');
        return {};
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      Map<String, List<double>> embeddings = {};
      for (String userId in data.keys) {
        List<dynamic> embeddingList = data[userId];
        List<double> embedding = embeddingList.cast<double>();
        embeddings[userId] = embedding;
      }
      
      print('✅ Retrieved ${embeddings.length} face embeddings');
      return embeddings;
    } catch (e) {
      print('❌ Error retrieving all face embeddings: $e');
      return {};
    }
  }
  
  // Delete face embedding for a user
  static Future<bool> deleteFaceEmbedding(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_faceEmbeddingsFile');
      
      if (!await file.exists()) {
        print('❌ Face embeddings file not found');
        return false;
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      if (data.containsKey(userId)) {
        data.remove(userId);
        await file.writeAsString(json.encode(data));
        print('✅ Face embedding deleted for user: $userId');
        return true;
      } else {
        print('❌ No face embedding found for user: $userId');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting face embedding: $e');
      return false;
    }
  }
  
  // Store user data (name, registration number, etc.)
  static Future<bool> storeUserData(String userId, Map<String, dynamic> userData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_userDataFile');
      
      Map<String, dynamic> data = {};
      
      // Load existing data if file exists
      if (await file.exists()) {
        final contents = await file.readAsString();
        data = json.decode(contents);
      }
      
      // Store the user data
      data[userId] = userData;
      
      // Save back to file
      await file.writeAsString(json.encode(data));
      
      print('✅ User data stored for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error storing user data: $e');
      return false;
    }
  }
  
  // Retrieve user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_userDataFile');
      
      if (!await file.exists()) {
        print('❌ User data file not found');
        return null;
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      if (data.containsKey(userId)) {
        print('✅ User data retrieved for user: $userId');
        return Map<String, dynamic>.from(data[userId]);
      } else {
        print('❌ No user data found for user: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error retrieving user data: $e');
      return null;
    }
  }
  
  // Get all user data
  static Future<Map<String, Map<String, dynamic>>> getAllUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_userDataFile');
      
      if (!await file.exists()) {
        print('❌ User data file not found');
        return {};
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      Map<String, Map<String, dynamic>> userData = {};
      for (String userId in data.keys) {
        userData[userId] = Map<String, dynamic>.from(data[userId]);
      }
      
      print('✅ Retrieved ${userData.length} user records');
      return userData;
    } catch (e) {
      print('❌ Error retrieving all user data: $e');
      return {};
    }
  }
  
  // Check if user has face embedding
  static Future<bool> hasFaceEmbedding(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_faceEmbeddingsFile');
      
      if (!await file.exists()) {
        return false;
      }
      
      final contents = await file.readAsString();
      final data = json.decode(contents);
      
      return data.containsKey(userId);
    } catch (e) {
      print('❌ Error checking face embedding: $e');
      return false;
    }
  }
  
  // Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final embeddings = await getAllFaceEmbeddings();
      final userData = await getAllUserData();
      
      return {
        'face_embeddings': embeddings.length,
        'user_records': userData.length,
      };
    } catch (e) {
      print('❌ Error getting database stats: $e');
      return {'face_embeddings': 0, 'user_records': 0};
    }
  }
  
  // Clear all data (for testing/reset)
  static Future<bool> clearAllData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final embeddingsFile = File('${directory.path}/$_faceEmbeddingsFile');
      final userDataFile = File('${directory.path}/$_userDataFile');
      
      if (await embeddingsFile.exists()) {
        await embeddingsFile.delete();
      }
      
      if (await userDataFile.exists()) {
        await userDataFile.delete();
      }
      
      print('✅ All face authentication data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing all data: $e');
      return false;
    }
  }
}
