import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'config.dart';
import 'face_verification_modal.dart';
import 'services/firestore_service.dart';
import 'services/firebase_auth_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _uniqueIdController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final Logger _logger = Logger();
  String _userName = "";
  String _uniqueIdResponse = "";
  bool _isLoading = false;
  bool _userFound = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  Future<void> fetchUserDetails(String uniqueId) async {
    setState(() {
      _isLoading = true;
      _userFound = false;
      _userName = "";
    });

    try {
      final response = await http
          .get(
            Uri.parse('${Config.serverUrl}/get_user/$uniqueId'),
          )
          .timeout(Duration(seconds: 5));

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _userName = jsonResponse['Name'];
          _userFound = true;
        });
        _animationController.forward();

        // Check if there's a warning about previous attendance
        if (jsonResponse.containsKey('warning')) {
          _showWarningDialog(
            "Previous Attendance Detected",
            "It appears that attendance has already been marked for this registration number. Please contact your instructor if you believe this is an error.",
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User found: ${jsonResponse['Name']}"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog(
          "User Not Found",
          "The registration number entered is not present in the classroom database. Please ensure you're in the correct classroom.",
        );
      }
    } catch (e) {
      _logger.e("Error fetching user details", error: e);
      _showErrorDialog(
        "Connection Error",
        "Unable to connect to the classroom server. Please ensure you're in the correct classroom and try again.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFaceVerificationAndAttendance(String uniqueId) async {
    if (!_userFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please verify your registration number first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch face embeddings mapped to registration numbers
      final embeddingsByRegNumber =
          await FirestoreService.getFaceEmbeddingsByRegNumber();

      if (embeddingsByRegNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("No face data available. Please contact administrator."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show face verification in a modal dialog
      final result = await _showFaceVerificationDialog(embeddingsByRegNumber);

      if (result != null) {
        // Face verification successful, check if the matched registration number matches the entered one
        if (result == uniqueId) {
          print(
              '✅ Face verification successful for registration number: $result');
          await uploadUniqueId(uniqueId);
          // Show success message and reset form
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "✅ Attendance marked successfully! Welcome back, $_userName!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Reset the form to allow for new attendance entries
          setState(() {
            _userFound = false;
            _userName = "";
            _uniqueIdResponse = "";
            _uniqueIdController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Face verification failed: Face does not match the entered registration number."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Face verification failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Face verification failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error during face verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error during face verification: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> uploadUniqueId(String uniqueId) async {
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${Config.serverUrl}/upload_unique_id/$uniqueId'),
          )
          .timeout(Duration(seconds: 5));

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() => _uniqueIdResponse = jsonResponse['message']);
        // Don't show snackbar here as we'll show a better one after face verification
        print('✅ Attendance uploaded successfully: ${jsonResponse['message']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(jsonResponse['error'] ?? "Error uploading ID")),
        );
      }
    } catch (e) {
      _logger.e("Error uploading unique ID", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1f2937), // Dark background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFFef4444), // Red
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Color(0xFFf59e0b), // Orange
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFd1d5db), // Light gray text
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: Color(0xFF818cf8)), // Indigo
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1f2937), // Dark background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFFf59e0b), // Orange
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Color(0xFFf59e0b), // Orange
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFd1d5db), // Light gray text
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: Color(0xFF818cf8)), // Indigo
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFaceVerificationDialog(
      Map<String, List<double>> storedEmbeddings) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Color(0xFF1f2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: FaceVerificationModal(
            storedEmbeddings: storedEmbeddings,
            onSuccess: (userId) {
              Navigator.pop(context, userId);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1f2937),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFFf9fafb),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Color(0xFFd1d5db),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF9ca3af)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        setState(() => _isLoading = true);

        // Sign out from Firebase
        await FirebaseAuthService.signOut();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Color(0xFF10b981),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showServerUrlDialog() {
    _urlController.text = Config.serverUrl;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1f2937), // Dark background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Server URL',
          style: TextStyle(
            color: Color(0xFFf9fafb), // White text
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF374151), // Darker input background
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _urlController,
                style: TextStyle(
                  color: Color(0xFFf9fafb), // White text
                ),
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  labelStyle: TextStyle(
                    color: Color(0xFF9ca3af), // Gray label
                  ),
                  hintText: 'http://server-ip:port',
                  hintStyle: TextStyle(
                    color: Color(0xFF6b7280), // Darker gray hint
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Example: http://10.2.8.97:5000',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9ca3af), // Gray text
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Color(0xFF9ca3af)), // Gray
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF818cf8), // Indigo
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Config.updateServerUrl(_urlController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL updated'),
                  backgroundColor: Color(0xFF10b981), // Green
                ),
              );
            },
            child: Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
        backgroundColor:
            Color(0xFF111827), // Dark background like faculty dashboard
        appBar: AppBar(
          backgroundColor: Color(0xFF1f2937), // Dark app bar
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            "Student Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFFf9fafb), // White text
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Color(0xFFd1d5db)),
              onPressed: _showServerUrlDialog,
              tooltip: 'Configure Server URL',
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Color(0xFFd1d5db)),
              onPressed: _isLoading ? null : _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 40), // Add top spacing
                // Welcome section
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf9fafb), // White text
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Mark your attendance for today",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFd1d5db), // Light gray text
                        ),
                      ),
                    ],
                  ),
                ),

                // Main card
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1f2937), // Dark card background
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Registration number input
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF374151), // Darker input background
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _uniqueIdController,
                            style: TextStyle(
                              color: Color(0xFFf9fafb), // White text
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: "Enter Registration Number",
                              labelStyle: TextStyle(
                                color: Color(0xFF9ca3af), // Gray label
                              ),
                              hintText: "e.g., 20K-0001",
                              hintStyle: TextStyle(
                                color: Color(0xFF6b7280), // Darker gray hint
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.numbers,
                                color: Color(0xFF818cf8), // Indigo accent
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color(0xFF818cf8), // Indigo primary
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => fetchUserDetails(
                                    _uniqueIdController.text.trim()),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    "Verify Registration Number",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // User found card
                if (_userName.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: Color(0xFF1f2937), // Dark card background
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Success icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Color(0xFF10b981)
                                    .withOpacity(0.1), // Green with opacity
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Color(0xFF10b981), // Green
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 16),

                            Text(
                              "User Verified",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFf9fafb), // White text
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10b981), // Green
                              ),
                            ),
                            SizedBox(height: 24),

                            // Mark attendance button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF10b981), // Green
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                        _handleFaceVerificationAndAttendance(
                                            _uniqueIdController.text.trim()),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        "Verify Face & Mark Attendance",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Response message
                if (_uniqueIdResponse.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF10b981).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF10b981),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _uniqueIdResponse,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF10b981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 40), // Add bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uniqueIdController.dispose();
    _urlController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
