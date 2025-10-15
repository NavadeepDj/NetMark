// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_picker/file_picker.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'login_page.dart';
// import 'upload_csv_screen.dart';
// import 'user_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     print('Firebase initialized successfully');
//   } catch (e) {
//     print('Error initializing Firebase: $e');
//   }
  
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'KARE FAST',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.grey[100],
//         appBarTheme: AppBarTheme(
//           elevation: 4,
//           backgroundColor: Colors.blue,
//         ),
//         cardTheme: CardTheme(
//           elevation: 4,
//           margin: EdgeInsets.symmetric(vertical: 8),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//       ),
//       home: LoginPage(),
//       routes: {
//         '/login': (context) => LoginPage(),
//         '/admin': (context) => UploadCSVScreen(),
//         '/user': (context) => UserScreen(),
//       },
//     );
//   }
// }

// class UploadCSVScreen extends StatefulWidget {
//   @override
//   _UploadCSVScreenState createState() => _UploadCSVScreenState();
// }

// class _UploadCSVScreenState extends State<UploadCSVScreen> {
//   String? _filePath;
//   bool _isUploading = false;
//   String _serverResponse = "";
//   String _userName = "";
//   String _uniqueIdResponse = "";
//   final TextEditingController _uniqueIdController = TextEditingController();

//   Future<void> pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['csv'],
//     );

//     if (result != null) {
//       setState(() {
//         _filePath = result.files.single.path;
//       });
//     }
//   }

//   Future<void> uploadFile() async {
//     if (_filePath == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Please select a CSV file first")),
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     var request = http.MultipartRequest(
//       'POST',
//       Uri.parse('http://10.2.8.97:5000/upload_csv'), // Change this to your Flask server IP
//     );

//     request.files.add(
//       await http.MultipartFile.fromPath('file', _filePath!),
//     );

//     try {
//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
//       var jsonResponse = json.decode(responseData);

//       setState(() {
//         _serverResponse = jsonResponse['message'] ?? "Unknown response";
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(jsonResponse['message'])),
//       );

//       if (response.statusCode == 200) {
//         // Navigate to the next screen after successful upload
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => RegistrationScreen(responseText: _serverResponse)),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error uploading file")),
//       );
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }

//   Future<void> fetchUserDetails(String uniqueId) async {
//     final response = await http.get(
//       Uri.parse('http://10.2.8.97:5000/get_user/$uniqueId'),
//     );

//     if (response.statusCode == 200) {
//       final jsonResponse = json.decode(response.body);
//       setState(() {
//         _userName = jsonResponse['Name'];
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("User found: ${jsonResponse['Name']}")),
//       );
//     } else {
//       final jsonResponse = json.decode(response.body);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(jsonResponse['error'] ?? "Error fetching user")),
//       );
//     }
//   }

//   Future<void> uploadUniqueId(String uniqueId) async {
//     final response = await http.post(
//       Uri.parse('http://10.2.8.97:5000/upload_unique_id/$uniqueId'),
//     );

//     if (response.statusCode == 200) {
//       final jsonResponse = json.decode(response.body);
//       setState(() {
//         _uniqueIdResponse = jsonResponse['message'];
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(jsonResponse['message'])),
//       );
//     } else {
//       final jsonResponse = json.decode(response.body);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(jsonResponse['error'] ?? "Error uploading ID")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Upload CSV")),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: pickFile,
//               child: Text("Select CSV File"),
//             ),
//             if (_filePath != null)
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text("Selected: ${_filePath!.split('/').last}"),
//               ),
//             SizedBox(height: 10),
//             _isUploading
//                 ? CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: uploadFile,
//                     child: Text("Upload"),
//                   ),
//             SizedBox(height: 20),
//             if (_serverResponse.isNotEmpty)
//               Text(
//                 "Server Response: $_serverResponse",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             SizedBox(height: 20),
//             TextField(
//               controller: _uniqueIdController,
//               decoration: InputDecoration(
//                 labelText: "Enter Registration Number",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 // Use the input from the TextField
//                 fetchUserDetails(_uniqueIdController.text.trim());
//               },
//               child: Text("Fetch User Details"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // Use the input from the TextField
//                 uploadUniqueId(_uniqueIdController.text.trim());
//               },
//               child: Text("Upload Unique ID"),
//             ),
//             if (_userName.isNotEmpty)
//               Text(
//                 "User Name: $_userName",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             if (_uniqueIdResponse.isNotEmpty)
//               Text(
//                 "Response: $_uniqueIdResponse",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class RegistrationScreen extends StatelessWidget {
//   final String responseText;

//   RegistrationScreen({required this.responseText});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Registration")),
//       body: Center(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text(
//             responseText,
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'upload_csv_screen.dart';
import 'user_screen.dart';
import 'student_list_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/face_verification_screen.dart';
import 'services/face_auth_service_mobile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  print('Face Recognition Attendance System Starting...');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KARE FAST',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 4,
          backgroundColor: Colors.blue,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      initialRoute: '/auth_check',
      routes: {
        '/auth_check': (context) => AuthCheck(),
        '/login': (context) => LoginPage(),
        '/admin': (context) => UploadCSVScreen(),
        '/user': (context) => UserScreen(),
        '/signup': (context) => SignupScreen(),
        '/face_verification': (context) => FaceVerificationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/student_list') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => StudentListScreen(
              showPresent: args?['showPresent'] ?? false,
              showAbsent: args?['showAbsent'] ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final FaceAuthService _faceAuthService = FaceAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await _faceAuthService.initialize();
      final isRegistered = await _faceAuthService.isUserRegistered();

      if (isRegistered) {
        // User is registered, navigate to face verification
        Navigator.pushReplacementNamed(context, '/face_verification');
      } else {
        // New user, navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Error checking auth status, navigate to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[500]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'KARE FAST',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Face Recognition Attendance System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}