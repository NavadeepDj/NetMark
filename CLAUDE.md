# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CV-based Face Recognition Attendance System (FAST - Face Attendance System with Tracking) that integrates:
- Flutter mobile app for attendance marking and CSV management
- Python Flask backend server for data processing
- Firebase authentication for admin access
- CSV-based student data management

## Architecture

### Flutter App (`file_sender/`)
- **Main Entry**: `file_sender/lib/main.dart` - App initialization and routing
- **Authentication**: `file_sender/lib/login_page.dart` - Firebase Auth integration
- **Admin Features**: `file_sender/lib/upload_csv_screen.dart` - CSV upload and management
- **User Features**: `file_sender/lib/user_screen.dart` - Attendance marking interface
- **Student List**: `file_sender/lib/student_list_screen.dart` - Display students with attendance status
- **Configuration**: `file_sender/lib/config.dart` - Dynamic server URL management

### Backend Servers
- **Main Server**: `Server_regNoSend.py` - Primary Flask server with comprehensive attendance API
- **Simple Server**: `server.py` - Basic file upload server (legacy)

### Data Files
- **Student Data**: CSV files with student information uploaded by admin
- **Attendance Records**: `verified_ids.csv` - Tracks marked attendance with timestamps
- **IP Tracking**: `ip_tracking.csv` - Prevents multiple attendance attempts from same device

## Development Commands

### Flutter App (in `file_sender/` directory)
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for release (Android)
flutter build apk

# Build for release (iOS)
flutter build ios
```

### Python Backend
```bash
# Install required packages
pip install flask pandas

# Run main server
python Server_regNoSend.py

# Run simple server (if needed)
python server.py
```

## Key Features

### Authentication Flow
- Admin login via Firebase Auth (email/password)
- Direct user access without authentication
- Route-based navigation between admin and user interfaces

### Attendance System
- CSV upload for student data management
- Registration number-based attendance marking
- IP tracking to prevent duplicate attendance
- Real-time attendance statistics
- Search functionality for students

### Server Configuration
- Dynamic server URL configuration in `config.dart`
- Default server: `http://10.2.8.97:5000`
- Server URL can be updated at runtime

## API Endpoints (Server_regNoSend.py)

- `POST /upload_csv` - Admin CSV file upload
- `GET /get_user/<unique_id>` - Fetch user details by registration number
- `POST /upload_unique_id/<unique_id>` - Mark attendance with IP validation
- `GET /attendance_stats` - Get attendance statistics
- `GET /students` - Get all students with attendance status
- `GET /search_students/<query>` - Search students by name/registration
- `POST /mark_attendance` - Direct attendance marking

## Important Notes

- The system uses IP-based tracking to prevent multiple attendance submissions
- Firebase is initialized in the main app with error handling
- All timestamps are recorded in UTC format
- Registration numbers are handled as strings to preserve leading zeros
- The app supports both admin and user workflows with different navigation paths