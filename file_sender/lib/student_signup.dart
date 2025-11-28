import 'package:flutter/material.dart';
import 'face_scan_screen.dart';
import 'services/face_database_service.dart';
import 'services/firestore_service.dart';
import 'services/firebase_auth_service.dart';

class StudentSignup extends StatefulWidget {
  const StudentSignup({super.key});

  @override
  _StudentSignupState createState() => _StudentSignupState();
}

class _StudentSignupState extends State<StudentSignup> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  List<double>? _faceEmbedding;
  bool _isFaceRegistered = false;
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text;
      String name = _nameController.text.trim();
      String regNumber = _regNumberController.text.trim();

      // Create Firebase user account
      print('🔥 Creating Firebase user account...');
      var userCredential = await FirebaseAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      if (userCredential?.user != null) {
        print(
            '✅ Firebase user created successfully: ${userCredential!.user!.uid}');

        // Store student data in Firestore
        String studentId = await FirestoreService.createStudent(
          email: email,
          name: name,
          registrationNumber: regNumber,
          firebaseUid: userCredential.user!.uid,
          faceEmbedding: _faceEmbedding,
          department: 'Computer Science', // You can make this dynamic
          year: '2024', // You can make this dynamic
        );

        // Also store locally for offline access
        Map<String, dynamic> userData = {
          'name': name,
          'email': email,
          'registrationNumber': regNumber,
          'firebaseUid': userCredential.user!.uid,
          'signupDate': DateTime.now().toIso8601String(),
        };

        bool userDataStored =
            await FaceDatabaseService.storeUserData(regNumber, userData);
        bool embeddingStored = await FaceDatabaseService.storeFaceEmbedding(
            regNumber, _faceEmbedding!);

        if (studentId.isNotEmpty && userDataStored && embeddingStored) {
          print('✅ User registration completed successfully');
          print('Student ID: $studentId');
          print('Face embedding dimensions: ${_faceEmbedding!.length}');
          print('Face embedding preview: ${_faceEmbedding!.take(5).toList()}');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to student dashboard
          Navigator.pushReplacementNamed(context, '/user');
        } else {
          // If storage fails, delete the Firebase user
          await userCredential.user!.delete();
          throw Exception('Failed to save registration data');
        }
      } else {
        throw Exception('Failed to create Firebase user account');
      }
    } catch (e) {
      print('❌ Error during signup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121416), // Background color
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
                      "Student Sign Up",
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

                    // Name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name",
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
                            color: Color(0xFF2c3035), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter your full name",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3), // Text secondary
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
                            color: Color(0xFF2c3035), // Secondary color
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
                                color: Color(0xFFa2abb3), // Text secondary
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

                    // Registration Number field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Registration Number",
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
                            color: Color(0xFF2c3035), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _regNumberController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "e.g., 2023-CS-12",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3), // Text secondary
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

                    SizedBox(height: 32),

                    // Face Scan section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Face Scan",
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
                            color: Color(0xFF2c3035), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  _isFaceRegistered
                                      ? "Face registered successfully ✓"
                                      : "Face Scan for quick access",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _isFaceRegistered
                                        ? Color(0xFF10b981) // Green for success
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  // Navigate to face scan screen
                                  if (_nameController.text.isNotEmpty &&
                                      _regNumberController.text.isNotEmpty) {
                                    final result =
                                        await Navigator.push<List<double>>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FaceScanScreen(
                                          name: _nameController.text,
                                          registrationNumber:
                                              _regNumberController.text,
                                        ),
                                      ),
                                    );

                                    if (result != null) {
                                      print(
                                          '✅ Received face embedding from scan: ${result.length} dimensions');
                                      print(
                                          '📊 Embedding preview: ${result.take(5).toList()}');
                                      setState(() {
                                        _faceEmbedding = result;
                                        _isFaceRegistered = true;
                                      });
                                      print(
                                          '🎯 Face registration status updated: $_isFaceRegistered');

                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Face registration completed successfully!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      print(
                                          '❌ No face embedding received from scan');
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter name and registration number first'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.face,
                                    color: Color(0xFFdce7f3), // Primary color
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
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
                          "Set Password",
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
                            color: Color(0xFF2c3035), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "Create a strong password",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3), // Text secondary
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

                    // Confirm Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Confirm Password",
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
                            color: Color(0xFF2c3035), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "Confirm your password",
                              hintStyle: TextStyle(
                                color: Color(0xFFa2abb3), // Text secondary
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

                    SizedBox(height: 32), // Extra space at bottom for scrolling
                  ],
                ),
              ),
            ),

            // Footer with signup button
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFdce7f3), // Primary color
                        foregroundColor: Color(0xFF121416), // Background color
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              // Handle signup logic
                              if (_nameController.text.isNotEmpty &&
                                  _emailController.text.isNotEmpty &&
                                  _regNumberController.text.isNotEmpty &&
                                  _passwordController.text.isNotEmpty &&
                                  _confirmPasswordController.text.isNotEmpty) {
                                // Check if passwords match
                                if (_passwordController.text ==
                                    _confirmPasswordController.text) {
                                  // Check if face is registered
                                  if (_isFaceRegistered &&
                                      _faceEmbedding != null) {
                                    // Store user data and face embedding in database
                                    _handleSignup();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please complete face registration'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Passwords do not match'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please fill in all required fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
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
                                  "Creating Account...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFa2abb3), // Text secondary
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFdce7f3), // Primary color
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
