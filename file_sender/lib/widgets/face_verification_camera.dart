import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import '../services/real_face_recognition_service.dart';

class FaceVerificationCamera extends StatefulWidget {
  final CameraController cameraController;
  final RealFaceRecognitionService faceAuthService;

  const FaceVerificationCamera({
    Key? key,
    required this.cameraController,
    required this.faceAuthService,
  }) : super(key: key);

  @override
  _FaceVerificationCameraState createState() => _FaceVerificationCameraState();
}

class _FaceVerificationCameraState extends State<FaceVerificationCamera> {
  final Logger _logger = Logger();
  bool _isProcessing = false;
  bool _isVerifying = false;
  String _errorMessage = '';
  List<double>? _storedEmbedding;

  @override
  void initState() {
    super.initState();
    _initializeFaceService();
  }

  Future<void> _initializeFaceService() async {
    try {
      await widget.faceAuthService.initialize();

      // Get current user info
      final currentRegNo = await widget.faceAuthService.getCurrentUserRegNo();
      if (currentRegNo == null) {
        setState(() {
          _errorMessage = 'User not found. Please register again.';
        });
        return;
      }

      final userInfo = await widget.faceAuthService.authenticateUser(currentRegNo);
      if (userInfo == null) {
        setState(() {
          _errorMessage = 'User data not found. Please register again.';
        });
        return;
      }

      setState(() {
        _storedEmbedding = userInfo['faceEmbedding'];
      });
    } catch (e) {
      _logger.e('Error initializing face service: $e');
      setState(() {
        _errorMessage = 'Failed to initialize face recognition';
      });
    }
  }

  Future<void> _verifyFace() async {
    if (!widget.cameraController.value.isInitialized || _isProcessing || _storedEmbedding == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Capture image
      final image = await widget.cameraController.takePicture();
      _logger.i('Face verification image captured');

      // Extract face embedding
      final currentEmbedding = await widget.faceAuthService.extractFaceEmbeddingFromFile(image.path);

      if (currentEmbedding == null) {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
          _errorMessage = 'No face detected. Please try again.';
        });
        return;
      }

      // LOGGING: Show current face embedding details
      _logger.i('📸 CURRENT FACE EMBEDDING CAPTURED:');
      _logger.i('   • Embedding length: ${currentEmbedding.length} dimensions');
      _logger.i('   • First 10 values: [${currentEmbedding.take(10).map((v) => v.toStringAsFixed(4)).join(', ')}...]');
      _logger.i('   • Embedding hash: ${currentEmbedding.map((v) => v.toStringAsFixed(2)).join(',')}');

      // LOGGING: Show stored face embedding details
      _logger.i('🔒 STORED FACE EMBEDDING:');
      _logger.i('   • Stored embedding length: ${_storedEmbedding!.length} dimensions');
      _logger.i('   • First 10 values: [${_storedEmbedding!.take(10).map((v) => v.toStringAsFixed(4)).join(', ')}...]');
      _logger.i('   • Stored embedding hash: ${_storedEmbedding!.map((v) => v.toStringAsFixed(2)).join(',')}');

      // Calculate similarity for logging
      final similarity = widget.faceAuthService.calculateCosineSimilarity(currentEmbedding, _storedEmbedding!);
      final threshold = widget.faceAuthService.faceThreshold;
      _logger.i('🎯 FACE COMPARISON:');
      _logger.i('   • Cosine similarity: ${similarity.toStringAsFixed(4)}');
      _logger.i('   • Threshold: ${threshold.toStringAsFixed(2)}');  // Using dynamic threshold from service
      _logger.i('   • Verification result: ${similarity >= threshold ? '✅ VERIFIED' : '❌ FAILED'}');

      // Verify face
      final isVerified = await widget.faceAuthService.verifyFace(currentEmbedding, _storedEmbedding!);

      if (isVerified) {
        _logger.i('Face verification successful');
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
          _errorMessage = 'Face not recognized. Please try again.';
        });
      }
    } catch (e) {
      _logger.e('Error during face verification: $e');
      setState(() {
        _isProcessing = false;
        _isVerifying = false;
        _errorMessage = 'Verification failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Face Verification'),
        backgroundColor: Colors.blue[700],
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isVerifying ? Colors.green : Colors.blue,
                  width: _isVerifying ? 3 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    CameraPreview(widget.cameraController),
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
              ),
            ),
          ),

          // Instructions and controls
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Position your face in the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ensure good lighting and face the camera directly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Spacer(),

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

                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}