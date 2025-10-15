import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../services/real_face_recognition_service.dart';
import '../user_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({Key? key}) : super(key: key);

  @override
  _FaceVerificationScreenState createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger();
  final RealFaceRecognitionService _faceAuthService = RealFaceRecognitionService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isVerifying = false;
  String _userName = '';
  String _regNo = '';
  List<double>? _storedEmbedding;
  String _errorMessage = '';
  int _failedAttempts = 0;
  static const int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize real face recognition service
      await _faceAuthService.initialize();

      // Get current user info
      final currentRegNo = await _faceAuthService.getCurrentUserRegNo();
      if (currentRegNo == null) {
        _navigateToSignup();
        return;
      }

      final userInfo = await _faceAuthService.authenticateUser(currentRegNo);
      if (userInfo == null) {
        _showErrorDialog('Authentication Failed', 'User data not found. Please register again.');
        return;
      }

      setState(() {
        _regNo = userInfo['registrationNumber'];
        _userName = userInfo['name'];
        _storedEmbedding = userInfo['faceEmbedding'];
      });

      // Initialize camera
      await _initializeCamera();
    } catch (e) {
      _logger.e('Error initializing services: $e');
      _showErrorDialog('Initialization Error', 'Failed to initialize real face recognition service');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        _showErrorDialog('Permission Required', 'Camera permission is required for face verification');
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorDialog('Camera Error', 'No cameras available on this device');
        return;
      }

      // Use front camera for face verification
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _logger.e('Error initializing camera: $e');
      _showErrorDialog('Camera Error', 'Failed to initialize camera');
    }
  }

  Future<void> _verifyFace() async {
    if (!_isCameraInitialized || _cameraController == null || _isProcessing || _storedEmbedding == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();

      _logger.i('Camera picture captured for face verification...');

      // Convert to XFile for easier handling
      final xFile = XFile(image.path);

      // Extract real face embedding using TFLite
      final currentEmbedding = await _faceAuthService.extractFaceEmbeddingFromFile(xFile.path);

      if (currentEmbedding == null) {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
          _errorMessage = 'No face detected or failed to extract face embedding. Please try again.';
        });
        _logger.w('Failed to extract face embedding for verification');
        return;
      }

      // Verify face with stored embedding
      if (_storedEmbedding == null) {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
          _errorMessage = 'No face data available. Please register first.';
        });
        return;
      }

      // Calculate similarity for logging
      final similarity = _faceAuthService.calculateCosineSimilarity(currentEmbedding, _storedEmbedding!);
      _logger.i('Face similarity calculated: $similarity');

      final isVerified = await _faceAuthService.verifyFace(currentEmbedding, _storedEmbedding!);

      _logger.i('Real face verification result: $isVerified (similarity: $similarity)');

      if (isVerified) {
        _logger.i('Face verification successful for $_regNo');
        _navigateToUserScreen();
      } else {
        _handleVerificationFailure();
      }
    } catch (e) {
      _logger.e('Error during real face verification: $e');
      setState(() {
        _isProcessing = false;
        _isVerifying = false;
        _errorMessage = 'Verification failed: $e';
      });
    }
  }

  void _handleVerificationFailure() {
    setState(() {
      _failedAttempts++;
      _isProcessing = false;
      _isVerifying = false;
    });

    if (_failedAttempts >= _maxAttempts) {
      _showErrorDialog(
        'Verification Failed',
        'Too many failed attempts. Please contact support or try registering again.',
      );
      _navigateToSignup();
    } else {
      setState(() {
        _errorMessage = 'Face not recognized. Attempt ${_failedAttempts}/$_maxAttempts. Please try again.';
      });
    }
  }

  void _navigateToUserScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserScreen()),
    );
  }

  void _navigateToSignup() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Logout',
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, size: 50, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Are you sure you want to logout? You will need to register again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _faceAuthService.logout();
              _navigateToSignup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Verification'),
        backgroundColor: Colors.blue[700],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.grey[200]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User info card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_userName.isNotEmpty)
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_regNo.isNotEmpty)
                        Text(
                          'Reg No: $_regNo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Camera preview
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _isVerifying ? Colors.green : Colors.blue,
                      width: _isVerifying ? 3 : 2,
                    ),
                  ),
                  child: _isCameraInitialized && _cameraController != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            children: [
                              CameraPreview(_cameraController!),
                              if (_isVerifying)
                                Container(
                                  color: Colors.white.withOpacity(0.7),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Verifying face...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Initializing camera...'),
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),

              // Instructions
              Text(
                'Position your face in the frame and tap verify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Verify button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _verifyFace,
                  child: _isProcessing
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Verify Face',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}