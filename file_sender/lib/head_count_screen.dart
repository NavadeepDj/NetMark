import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/yolo_service.dart';

class HeadCountScreen extends StatefulWidget {
  final String className;
  final String section;

  const HeadCountScreen({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  _HeadCountScreenState createState() => _HeadCountScreenState();
}

class _HeadCountScreenState extends State<HeadCountScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  int _headCount = 0;
  bool _isProcessing = false;
  String _processingStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0d1117), // Background color
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0d1117).withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF21262d), // Border color
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
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
                          color: Color(0xFF7d8590), // Text secondary
                          size: 24,
                        ),
                      ),
                    ),
                    // Title
                    Expanded(
                      child: Text(
                        "Head Count",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFe6edf3), // Text primary
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Placeholder for symmetry
                    SizedBox(
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course info
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF161b22), // Card color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF21262d), // Border color
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Course: ${widget.className}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFe6edf3), // Text primary
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Section: ${widget.section}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7d8590), // Text secondary
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Photo section
                    Text(
                      "Take Photo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFe6edf3), // Text primary
                      ),
                    ),
                    SizedBox(height: 12),

                    // Photo container
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Color(0xFF161b22), // Card color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF21262d), // Border color
                          width: 1,
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF7d8590), // Text secondary
                                  size: 48,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "No photo taken",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7d8590), // Text secondary
                                  ),
                                ),
                              ],
                            ),
                    ),

                    SizedBox(height: 16),

                    // Photo buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color(0xFF0b79ef), // Primary color
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _takePhoto,
                            icon: Icon(Icons.camera_alt, size: 20),
                            label: Text("Take Photo"),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF161b22), // Card color
                              foregroundColor:
                                  Color(0xFFe6edf3), // Text primary
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Color(0xFF21262d), // Border color
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: _pickImage,
                            icon: Icon(Icons.photo_library, size: 20),
                            label: Text("Upload"),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Auto count section
                    Text(
                      "Auto Count",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFe6edf3), // Text primary
                      ),
                    ),
                    SizedBox(height: 12),

                    // Auto count button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF161b22), // Card color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF21262d), // Border color
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0b79ef), // Primary color
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _imageFile != null ? _processImageWithYOLO : null,
                        icon: Icon(Icons.auto_awesome, size: 20),
                        label: Text("Auto Count with YOLOv8"),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Head count section
                    Text(
                      "Manual Count",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFe6edf3), // Text primary
                      ),
                    ),
                    SizedBox(height: 12),

                    // Count controls
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF161b22), // Card color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF21262d), // Border color
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_isProcessing)
                            Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0b79ef), // Primary color
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _processingStatus,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7d8590), // Text secondary
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_headCount > 0) {
                                      setState(() {
                                        _headCount--;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          Color(0xFF2c3035), // Secondary color
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Color(0xFFdce7f3), // Primary color
                                      size: 24,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 24),
                                Text(
                                  "$_headCount",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFe6edf3), // Text primary
                                  ),
                                ),
                                SizedBox(width: 24),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _headCount++;
                                    });
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0b79ef), // Primary color
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 16),
                          Text(
                            _isProcessing
                                ? "Processing..."
                                : "Students Present",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7d8590), // Text secondary
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0d1117), // Background color
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF21262d), // Border color
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0b79ef), // Primary color
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Back to Attendance",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processImageWithYOLO() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Initializing YOLOv8...';
    });

    try {
      // Initialize YOLO model
      setState(() {
        _processingStatus = 'Loading YOLOv8 model...';
      });
      await YOLOService.initializeModel();

      setState(() {
        _processingStatus = 'Analyzing image...';
      });

      // Perform head detection
      setState(() {
        _processingStatus = 'Detecting heads...';
      });

      final int detectedHeads = await YOLOService.detectHeads(_imageFile!);

      setState(() {
        _headCount = detectedHeads;
        _isProcessing = false;
        _processingStatus = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('YOLOv8 detected $_headCount students'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
