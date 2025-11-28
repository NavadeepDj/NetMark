import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/face_auth_service.dart';

class FaceVerificationModal extends StatefulWidget {
  final Map<String, List<double>> storedEmbeddings; // registrationNumber -> embedding
  final Function(String) onSuccess; // Returns registration number
  final VoidCallback onCancel;

  const FaceVerificationModal({
    super.key,
    required this.storedEmbeddings,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  _FaceVerificationModalState createState() => _FaceVerificationModalState();
}

class _FaceVerificationModalState extends State<FaceVerificationModal> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Position your face in the frame";
  String? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          setState(() {
            _statusMessage = "Camera permission denied. Please enable camera access in settings.";
          });
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = "No cameras available";
        });
        return;
      }

      // Find front camera (lensFacing: CameraLensDirection.front)
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // If no front camera found, use the first available camera
      if (frontCamera == null) {
        frontCamera = _cameras![0];
        setState(() {
          _statusMessage = "Front camera not available, using back camera";
        });
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Initialize the face authentication service
      bool modelLoaded = await FaceAuthService.initializeModel();
      if (!modelLoaded) {
        setState(() {
          _statusMessage = "Failed to load face recognition model";
        });
        return;
      }

      setState(() {
        _isInitialized = true;
        _statusMessage = "Position your face in the frame";
      });

      // Debug: Print which camera is being used
      print('📷 Using camera: ${frontCamera.name} (${frontCamera.lensDirection})');
    } catch (e) {
      setState(() {
        _statusMessage = "Error initializing camera: $e";
      });
    }
  }

  Future<void> _authenticateFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Authenticating face...";
    });

    try {
      // Capture image from camera
      XFile image = await _cameraController!.takePicture();
      Uint8List imageBytes = await image.readAsBytes();

      print('📸 Image captured: ${imageBytes.length} bytes');

      setState(() {
        _statusMessage = "Processing face with MobileFaceNet...";
      });

      // Find best match from stored embeddings (registration numbers)
      String? matchedRegNumber = await FaceAuthService.findBestMatch(imageBytes, widget.storedEmbeddings);

      if (matchedRegNumber != null) {
        setState(() {
          _authenticatedUser = matchedRegNumber;
          _statusMessage = "Authentication successful!";
        });

        print('✅ Face authentication successful for registration number: $matchedRegNumber');

        // Show success and call onSuccess callback
        _showSuccessAndClose(matchedRegNumber);
      } else {
        setState(() {
          _statusMessage = "Face not recognized. Please try again.";
        });
        print('❌ Face authentication failed - no match found');
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error processing face: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessAndClose(String registrationNumber) {
    // Show brief success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Face verification successful for $registrationNumber!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    
    // Close modal and return registration number
    widget.onSuccess(registrationNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF374151),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.face,
                color: Color(0xFF818cf8),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                "Face Verification",
                style: TextStyle(
                  color: Color(0xFFf9fafb),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(
                  Icons.close,
                  color: Color(0xFF9ca3af),
                ),
              ),
            ],
          ),
        ),

        // Camera preview
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isProcessing ? Color(0xFF10b981) : Color(0xFF374151),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: Color(0xFF1f2937),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Color(0xFF6b7280),
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: Color(0xFF9ca3af),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Instructions and status
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  "Instructions:",
                  style: TextStyle(
                    color: Color(0xFFf9fafb),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "• Position your face in the center of the frame\n• Ensure good lighting\n• Look directly at the front camera\n• Keep your face still",
                  style: TextStyle(
                    color: Color(0xFFd1d5db),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isProcessing
                        ? Color(0xFF10b981)
                        : Color(0xFF9ca3af),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              // Cancel button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6b7280),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onCancel,
                    child: Text("Cancel"),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Verify button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing || !_isInitialized
                          ? Color(0xFF6b7280)
                          : Color(0xFF818cf8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : (!_isInitialized &&
                                _statusMessage.contains("permission"))
                            ? () async {
                                await _initializeCamera();
                              }
                            : _authenticateFace,
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text("Verifying..."),
                            ],
                          )
                        : (!_isInitialized &&
                                _statusMessage.contains("permission"))
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, size: 16),
                                  SizedBox(width: 8),
                                  Text("Retry"),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.face, size: 16),
                                  SizedBox(width: 8),
                                  Text("Verify Face"),
                                ],
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    FaceAuthService.dispose();
    super.dispose();
  }
}
