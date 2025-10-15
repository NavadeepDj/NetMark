import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'config.dart';
import 'services/face_auth_service_mobile.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _uniqueIdController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final Logger _logger = Logger();
  final FaceAuthService _faceAuthService = FaceAuthService();
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  Future<void> fetchUserDetails(String uniqueId) async {
    setState(() {
      _isLoading = true;
      _userFound = false;
      _userName = "";
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.serverUrl}/get_user/$uniqueId'),
      ).timeout(Duration(seconds: 5));

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

  Future<void> uploadUniqueId(String uniqueId) async {
    if (!_userFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please verify your registration number first")),
      );
      return;
    }

    // Show face verification dialog before marking attendance
    final verified = await _showFaceVerificationDialog();
    if (!verified) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.serverUrl}/upload_unique_id/$uniqueId'),
      ).timeout(Duration(seconds: 5));

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() => _uniqueIdResponse = jsonResponse['message']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'])),
        );
        // Refresh student list after marking attendance
        // _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['error'] ?? "Error uploading ID")),
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
            Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Colors.orange,
            ),
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
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Colors.orange,
            ),
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
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<bool> _showFaceVerificationDialog() async {
    bool verified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.face, color: Colors.blue),
              SizedBox(width: 8),
              Text('Face Verification Required'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please verify your identity before marking attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Face Scanner', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This ensures only you can mark your attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() => verified = true);
                await Future.delayed(Duration(milliseconds: 1500)); // Simulate face scan
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Verify Face'),
            ),
          ],
        ),
      ),
    );

    return verified;
  }

  void _showServerUrlDialog() {
    _urlController.text = Config.serverUrl;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://server-ip:port',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Example: http://10.2.8.97:5000',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Config.updateServerUrl(_urlController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL updated')),
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
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          title: Text(
            "KARE FAST · USER",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _showServerUrlDialog,
              tooltip: 'Configure Server URL',
            ),
          ],
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _uniqueIdController,
                          decoration: InputDecoration(
                            labelText: "Enter Registration Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.numbers, color: Colors.blue),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => fetchUserDetails(_uniqueIdController.text.trim()),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text("Verify Registration Number", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_userName.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 8,
                      margin: EdgeInsets.only(top: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "User Found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => uploadUniqueId(_uniqueIdController.text.trim()),
                              child: Text("Mark Attendance"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_uniqueIdResponse.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _uniqueIdResponse,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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