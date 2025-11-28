import 'package:flutter/material.dart';
import 'services/firebase_auth_service.dart';
import 'services/face_database_service.dart';
import 'services/firestore_service.dart';
import 'face_login_screen.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  _StudentLoginState createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleEmailLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter both email and password'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Sign in with Firebase
      print('🔥 Signing in with Firebase...');
      var userCredential = await FirebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        print('✅ Firebase sign in successful: ${userCredential!.user!.uid}');

        // Get student data from Firestore
        var studentData = await FirestoreService.getStudentByFirebaseUid(
            userCredential.user!.uid);

        if (studentData != null) {
          // Update last login time
          await FirestoreService.updateLastLogin(studentData['id']);

          // Record successful login attempt
          await FirestoreService.recordLoginAttempt(
            email: email,
            status: 'success',
            studentId: studentData['id'],
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${studentData['profile']['name']}!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to student dashboard
          Navigator.pushReplacementNamed(context, '/user');
        } else {
          throw Exception('Student data not found in database');
        }
      } else {
        throw Exception('Failed to sign in');
      }
    } catch (e) {
      print('❌ Error during login: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Show more helpful message for invalid credentials
      if (errorMessage.contains('Invalid email or password') ||
          errorMessage.contains('No user found')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Account not found. Please sign up first or check your credentials.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Sign Up',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/student-signup');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _showFaceLoginModal(
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
          child: FaceLoginScreen(
            storedEmbeddings: storedEmbeddings,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFaceLogin() async {
    try {
      // Get all students with face data from Firestore
      List<Map<String, dynamic>> studentsWithFaceData =
          await FirestoreService.getAllStudentsWithFaceData();

      if (studentsWithFaceData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No registered faces found. Please sign up first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Convert to the format expected by FaceLoginScreen
      Map<String, List<double>> storedEmbeddings = {};
      for (var student in studentsWithFaceData) {
        if (student['faceData'] != null &&
            student['faceData']['embedding'] != null) {
          storedEmbeddings[student['id']] =
              List<double>.from(student['faceData']['embedding']);
        }
      }

      // Show face login as a floating modal dialog
      final String? authenticatedUserId =
          await _showFaceLoginModal(storedEmbeddings);

      print(
          '🔄 Received authenticatedUserId from face login: $authenticatedUserId');

      if (authenticatedUserId != null && authenticatedUserId.isNotEmpty) {
        print('✅ Processing face login for user: $authenticatedUserId');
        // Find the student data
        var studentData = studentsWithFaceData.firstWhere(
          (student) => student['id'] == authenticatedUserId,
          orElse: () => {},
        );

        if (studentData.isNotEmpty) {
          print('✅ Student data found: ${studentData['profile']['name']}');
          // Update last login time
          await FirestoreService.updateLastLogin(authenticatedUserId);

          // Record successful login attempt
          await FirestoreService.recordLoginAttempt(
            email: studentData['profile']['email'],
            status: 'success',
            studentId: authenticatedUserId,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${studentData['profile']['name']}!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to user dashboard
          print('🔄 Navigating to user dashboard...');
          Navigator.pushReplacementNamed(context, '/user');
        } else {
          print('❌ Student data not found for user: $authenticatedUserId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student data not found. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ No authenticated user ID received from face login');
      }
    } catch (e) {
      print('❌ Face login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face login failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121416),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Text(
                      "Student Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Spacer to balance the layout
                  SizedBox(width: 40),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 32),

                    // Email field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(0xFF2c3035),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter your email address",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(0xFF2c3035),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter your password",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFFa2abb3),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFdce7f3),
                          foregroundColor: Color(0xFF121416),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleEmailLogin,
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF121416)),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Signing In...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFF6b7280))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: Color(0xFF6b7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFF6b7280))),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Face Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _handleFaceLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Face Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
