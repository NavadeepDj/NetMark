import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../services/real_face_recognition_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final Logger _logger = Logger();
  final RealFaceRecognitionService _faceAuthService = RealFaceRecognitionService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  List<double>? _capturedEmbedding;
  int _currentStep = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeFaceService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _nameController.dispose();
    _regNoController.dispose();
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

  Future<void> _initializeFaceService() async {
    try {
      await _faceAuthService.initialize();
      _logger.i('Real face recognition service initialized');
    } catch (e) {
      _logger.e('Error initializing real face recognition service: $e');
      _showErrorDialog('Initialization Error', 'Failed to initialize real face recognition service');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        _showErrorDialog('Permission Required', 'Camera permission is required for face registration');
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorDialog('Camera Error', 'No cameras available on this device');
        return;
      }

      // Use front camera for face registration
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

  Future<void> _captureFace() async {
    if (!_isCameraInitialized || _cameraController == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // Take picture from camera
      final image = await _cameraController!.takePicture();

      _logger.i('Camera picture captured, processing face recognition...');

      // Convert to XFile for easier handling
      final xFile = XFile(image.path);

      // Extract real face embedding using TFLite
      final embedding = await _faceAuthService.extractFaceEmbeddingFromFile(xFile.path);

      if (embedding == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No face detected or failed to extract face embedding. Please try again.';
        });
        _logger.w('Failed to extract face embedding');
        return;
      }

      setState(() {
        _capturedEmbedding = embedding;
        _faceDetected = true;
        _isProcessing = false;
      });

      _logger.i('Real face embedding extracted successfully (${embedding.length} dimensions)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.e('Error capturing face: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to capture face: $e';
      });
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() != true || _capturedEmbedding == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      await _faceAuthService.registerUser(
        name: _nameController.text.trim(),
        registrationNumber: _regNoController.text.trim(),
        faceEmbedding: _capturedEmbedding!,
      );

      _logger.i('User registered successfully');

      // Show success dialog and navigate to main app
      _showSuccessDialog();
    } catch (e) {
      _logger.e('Error registering user: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Registration Successful!',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 50, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Your face has been registered successfully.\nYou can now mark your attendance using face recognition.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/user'); // Navigate to user screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Get Started', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Step> _getSteps() {
    // Remove the null check that's causing infinite loading
    return [
      Step(
        title: Text('Personal Info'),
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _regNoController,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.numbers, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your registration number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text('Face Registration'),
        content: Column(
          children: [
            Text(
              'Position your face in the frame and capture your photo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isCameraInitialized && _cameraController != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CameraPreview(_cameraController!),
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
            SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            if (_faceDetected)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Face captured successfully', style: TextStyle(color: Colors.green)),
                ],
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _captureFace,
              style: ElevatedButton.styleFrom(
                backgroundColor: _faceDetected ? Colors.grey : Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_faceDetected ? 'Face Captured' : 'Capture Face'),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: Text('Confirmation'),
        content: Column(
          children: [
            Text(
              'Review your information and confirm registration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Name: ${_nameController.text}'),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.numbers, size: 20),
                        SizedBox(width: 8),
                        Text('Reg No: ${_regNoController.text}'),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.face, size: 20),
                        SizedBox(width: 8),
                        Text('Face: ${_faceDetected ? 'Registered' : 'Not registered'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing || !_faceDetected ? null : _registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Complete Registration'),
            ),
          ],
        ),
        isActive: _currentStep >= 2,
      ),
      ];
    }

  void _nextStep() {
    if (_currentStep < _getSteps().length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Registration'),
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
            children: [
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  steps: _getSteps(),
                  onStepContinue: _nextStep,
                  onStepCancel: _previousStep,
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: Text('Previous'),
                          ),
                        Spacer(),
                        if (_currentStep < _getSteps().length - 1)
                          ElevatedButton(
                            onPressed: _currentStep == 0 && (_formKey.currentState?.validate() != true)
                                ? null
                                : details.onStepContinue,
                            child: Text('Next'),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}