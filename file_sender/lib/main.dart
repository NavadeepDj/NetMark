import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'user_screen.dart';
import 'student_list_screen.dart';
import 'upload_csv_screen.dart';
import 'role_selection_screen.dart';
import 'student_login.dart';
import 'faculty_login.dart';
import 'student_signup.dart';
import 'faculty_signup.dart';
import 'signup_role_selection_screen.dart';
import 'faculty_dashboard.dart';
import 'attendance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    // Continue app initialization even if Firebase fails
    // This allows the app to work with offline functionality
  }

  runApp(NetMarkApp());
}

class NetMarkApp extends StatelessWidget {
  const NetMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NetMark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 4,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/role-selection': (context) => RoleSelectionScreen(),
        '/signup-role-selection': (context) => SignupRoleSelectionScreen(),
        '/student-login': (context) => StudentLogin(),
        '/faculty-login': (context) => FacultyLogin(),
        '/student-signup': (context) => StudentSignup(),
        '/faculty-signup': (context) => FacultySignup(),
        '/faculty-dashboard': (context) => FacultyDashboard(),
        '/attendance': (context) => AttendanceScreen(),
        '/user': (context) => UserScreen(),
        '/admin': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return StudentListScreen(
            showPresent: args?['showPresent'] ?? false,
            showAbsent: args?['showAbsent'] ?? false,
          );
        },
        '/upload': (context) => UploadCSVScreen(),
      },
    );
  }
}
