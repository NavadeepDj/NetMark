# NetMark - Instance Network Attendance System
## Interview Explanation Guide

---

## 📱 **Overview**
NetMark is a mobile attendance system that uses face recognition technology to mark student attendance in real-time within a local network (instance network). The app ensures secure, automated attendance tracking with biometric verification.

---

## 🛠️ **Tech Stack**

### **Frontend (Mobile App)**
- **Framework**: Flutter (Dart SDK 3.6.0)
- **Platform**: Cross-platform (Android, iOS, Web, Windows, macOS, Linux)
- **UI Framework**: Material Design with custom gradients and animations

### **Key Dependencies**:
1. **Face Recognition & Camera**:
   - `camera: ^0.10.5+5` - Camera access and image capture
   - `image: ^3.0.2` - Image processing for face detection
   - Custom TFLite model (`output_model.tflite`) for face embedding extraction

2. **Backend Communication**:
   - `http: ^1.1.0` - REST API calls to Flask server
   - `file_picker: ^10.3.3` - CSV file uploads for admin

3. **Data Storage**:
   - `shared_preferences: ^2.2.2` - Local storage for user data and face embeddings
   - `cloud_firestore: ^4.10.0` - Cloud database for user synchronization
   - `firebase_core: ^2.11.0` - Firebase initialization

4. **Utilities**:
   - `permission_handler: ^11.3.1` - Camera and storage permissions
   - `device_info_plus: ^9.0.2` - Device identification
   - `logger: ^2.0.2+1` - Debugging and logging
   - `crypto: ^3.0.3` - Cryptographic operations for face embeddings

### **Backend (Server)**
- **Framework**: Flask (Python)
- **Network**: Local instance network (default: `http://10.2.8.97:5000`)
- **Data Format**: JSON for API communication, CSV for student data upload

---

## 🏗️ **Architecture Overview**

### **App Structure**:
```
lib/
├── main.dart                    # Entry point, routing configuration
├── config.dart                  # Server URL configuration
├── login_page.dart              # Home/login screen
├── user_screen.dart             # Student attendance marking
├── upload_csv_screen.dart       # Admin dashboard
├── student_list_screen.dart     # Student list viewer
├── screens/
│   ├── signup_screen.dart      # User registration with face capture
│   └── face_verification_screen.dart  # Face verification for login
├── services/
│   ├── face_auth_service_mobile.dart  # Face authentication service
│   └── real_face_recognition_service.dart  # TFLite-based face recognition
├── widgets/
│   └── face_verification_camera.dart  # Camera widget for verification
└── utils/
    ├── face_recognition_config.dart   # Face recognition settings
    ├── storage_manager.dart           # Local storage management
    └── face_embedding_debug.dart      # Debug utilities
```

---

## 🗺️ **Routing Structure**

The app uses Flutter's named routing system with the following routes:

### **Route Definitions** (in `main.dart`):

```dart
routes: {
  '/auth_check': (context) => AuthCheck(),           // Initial auth check
  '/login': (context) => LoginPage(),                 // Home/login screen
  '/admin': (context) => UploadCSVScreen(),           // Admin dashboard
  '/user': (context) => UserScreen(),                 // Student screen
  '/signup': (context) => SignupScreen(),              // Registration
  '/face_verification': (context) => FaceVerificationScreen(),  // Face login
}
```

### **Dynamic Routes**:
- `/student_list` - Navigated with arguments:
  ```dart
  Navigator.pushNamed(context, '/student_list', arguments: {
    'showPresent': true/false,
    'showAbsent': true/false,
  });
  ```

### **Navigation Flow**:

1. **App Launch** → `/auth_check`
   - Checks if user is registered
   - If registered → `/face_verification`
   - If not → `/login`

2. **Login Screen** (`/login`) → Options:
   - **User Sign Up** → `/signup`
   - **Existing User Login** → `/face_verification`
   - **Admin Login** → `/admin` (after credential verification)

3. **Signup Flow** (`/signup`) → After registration → `/user`

4. **Face Verification** (`/face_verification`) → On success → `/user`

5. **User Screen** (`/user`) → Mark attendance → Back to `/login`

6. **Admin Screen** (`/admin`) → Can navigate to `/student_list` with filters

---

## 🔄 **Application Flow**

### **1. User Registration Flow**:
```
Login Page → Sign Up Button
    ↓
Signup Screen (3-step process):
    Step 1: Enter Name & Registration Number
    Step 2: Capture Face (Camera → Extract Face Embedding)
    Step 3: Review & Confirm
    ↓
Store Data:
    - Local: SharedPreferences (face embedding, user info)
    - Cloud: Firebase Firestore (synchronization)
    ↓
Navigate to User Screen
```

**Key Code** (`signup_screen.dart`):
- Uses `RealFaceRecognitionService` to extract 64-dimensional face embeddings
- Stores embeddings locally and in Firebase
- Uses device ID for device binding

### **2. User Login Flow**:
```
App Launch → Auth Check
    ↓
Face Verification Screen:
    - Load stored face embedding
    - Capture current face
    - Compare embeddings (cosine similarity)
    - Threshold: 0.75 (configurable)
    ↓
If Match → User Screen
If Failed (3 attempts) → Signup Screen
```

**Key Code** (`face_verification_screen.dart`):
- Uses `RealFaceRecognitionService.verifyFace()`
- Calculates cosine similarity between stored and current embeddings
- Maximum 3 failed attempts before redirecting to signup

### **3. Attendance Marking Flow**:
```
User Screen:
    ↓
1. Enter Registration Number
    ↓
2. Verify Registration (API call: GET /get_user/{regNo})
    - Checks if student exists in classroom database
    - Returns student name
    ↓
3. Face Verification Dialog
    - Capture face
    - Verify against stored embedding
    ↓
4. Mark Attendance (API call: POST /upload_unique_id/{regNo})
    - Sends registration number to server
    - Server marks attendance
    ↓
Success Message
```

**Key Code** (`user_screen.dart`):
- Two-step verification: Registration number + Face verification
- Prevents duplicate attendance marking
- Shows warnings for already marked attendance

### **4. Admin Flow**:
```
Admin Login (admin@kare.edu / admin123)
    ↓
Admin Dashboard:
    - View Statistics (Total, Present, Absent)
    - Upload CSV file (student list)
    - Manual attendance entry
    - View student lists (filtered by present/absent)
```

**Key Code** (`upload_csv_screen.dart`):
- CSV upload via multipart form data
- Real-time statistics from server
- Manual attendance marking capability

---

## 🤖 **Face Recognition Implementation**

### **Technology**:
- **Model**: TensorFlow Lite (TFLite) model (`output_model.tflite`)
- **Embedding Size**: 64 dimensions
- **Input Size**: 112x112 pixels
- **Similarity Metric**: Cosine Similarity
- **Threshold**: 0.75 (configurable via settings)

### **Process**:

1. **Face Detection & Extraction** (`real_face_recognition_service.dart`):
   ```dart
   extractFaceEmbeddingFromFile(imagePath)
   ```
   - Loads image from file/camera
   - Resizes to 112x112
   - Extracts facial features from 20 key regions:
     - Forehead (3 points)
     - Eyes (4 points)
     - Nose (3 points)
     - Mouth (4 points)
     - Chin (2 points)
     - Cheeks (4 points)
   - Generates hash-based 64-dimensional embedding

2. **Face Verification**:
   ```dart
   verifyFace(currentEmbedding, storedEmbedding)
   ```
   - Calculates cosine similarity
   - Compares against threshold (default: 0.75)
   - Returns boolean (match/no match)

3. **Storage**:
   - **Local**: SharedPreferences (encrypted face embeddings)
   - **Cloud**: Firebase Firestore (for multi-device sync)

### **Security Features**:
- Device binding (Android ID / iOS identifierForVendor)
- Local encryption of face embeddings
- Configurable recognition threshold
- Strict mode option for additional verification

---

## 🌐 **Backend API Integration**

### **Server Configuration**:
- Default URL: `http://10.2.8.97:5000` (configurable in app)
- Configurable via Settings button in User/Admin screens

### **API Endpoints Used**:

1. **GET `/get_user/{registrationNumber}`**
   - Purpose: Verify student exists in classroom
   - Response: `{ "Name": "Student Name", "warning": "..." }`
   - Used in: User Screen (registration verification)

2. **POST `/upload_unique_id/{registrationNumber}`**
   - Purpose: Mark student attendance
   - Response: `{ "message": "Attendance marked successfully" }`
   - Used in: User Screen (attendance marking)

3. **POST `/upload_csv`**
   - Purpose: Upload student list CSV file
   - Method: Multipart form data
   - Used in: Admin Screen (CSV upload)

4. **GET `/attendance_stats`**
   - Purpose: Get attendance statistics
   - Response: `{ "total": 50, "present": 30, "absent": 20 }`
   - Used in: Admin Screen (dashboard statistics)

5. **GET `/students`**
   - Purpose: Get list of all students with attendance status
   - Response: `{ "students": [...] }`
   - Used in: Student List Screen

6. **POST `/mark_attendance`**
   - Purpose: Manual attendance marking (admin)
   - Body: `{ "registrationNumber": "..." }`
   - Used in: Admin Screen (manual entry)

---

## 💾 **Data Storage**

### **Local Storage (SharedPreferences)**:
- `userRegNo`: Registration number
- `userName`: User's name
- `macAddress`: Device identifier
- `faceEmbedding`: Face embedding (as string list)
- Face recognition settings (threshold, strict mode)

### **Cloud Storage (Firebase Firestore)**:
- Collection: `users`
- Document ID: Registration number
- Fields:
  - `name`: String
  - `registrationNumber`: String
  - `deviceId`: String
  - `faceEmbedding`: Array of numbers (64 dimensions)
  - `createdAt`: Timestamp

### **Server Storage**:
- CSV file with student data
- Attendance records (present/absent status)
- Real-time statistics

---

## 🎨 **UI/UX Features**

1. **Material Design**: Modern, gradient-based UI
2. **Responsive Layout**: Works on all screen sizes
3. **Loading States**: Progress indicators for async operations
4. **Error Handling**: User-friendly error dialogs
5. **Animations**: Fade transitions, gradient buttons
6. **Accessibility**: Clear labels, icons, and feedback

---

## 🔒 **Security Features**

1. **Biometric Authentication**: Face recognition required for attendance
2. **Device Binding**: Prevents account sharing
3. **Duplicate Prevention**: Server-side checks for already marked attendance
4. **Network Security**: Local network instance (not exposed to internet)
5. **Data Encryption**: Face embeddings stored securely

---

## 📊 **Key Features**

1. ✅ **Face Recognition Registration**: Multi-step registration with face capture
2. ✅ **Face Verification Login**: Secure biometric login
3. ✅ **Real-time Attendance**: Instant attendance marking with verification
4. ✅ **Admin Dashboard**: Statistics, CSV upload, manual entry
5. ✅ **Student List View**: Filter by present/absent students
6. ✅ **Offline Support**: Local storage for face data
7. ✅ **Cloud Sync**: Firebase for multi-device access
8. ✅ **Configurable Settings**: Adjustable face recognition threshold
9. ✅ **Error Recovery**: Graceful error handling and user feedback

---

## 🚀 **How to Explain in Interview**

### **Opening Statement**:
"NetMark is a Flutter-based mobile attendance system that uses face recognition technology to automate and secure student attendance tracking within a local network environment."

### **Tech Stack Highlights**:
- "Built with Flutter for cross-platform compatibility"
- "Uses TensorFlow Lite for on-device face recognition"
- "Integrates with Flask backend via REST APIs"
- "Implements Firebase for cloud synchronization"

### **Architecture**:
- "Follows a clean architecture with separation of concerns: screens, services, widgets, and utilities"
- "Uses named routing for navigation management"
- "Implements singleton pattern for face recognition service"

### **Face Recognition**:
- "Extracts 64-dimensional face embeddings using TFLite model"
- "Uses cosine similarity for face matching with configurable threshold"
- "Implements 20-point facial feature extraction for accuracy"

### **Security**:
- "Two-factor verification: registration number + face recognition"
- "Device binding prevents unauthorized access"
- "Local encryption of biometric data"

### **User Experience**:
- "Three-step registration process with real-time face capture"
- "Intuitive admin dashboard with real-time statistics"
- "Comprehensive error handling and user feedback"

---

## 📝 **Additional Notes**

- The app is designed for **instance network** usage (local classroom network)
- Server URL is configurable to work with different classroom setups
- Face recognition threshold can be adjusted per user for better accuracy
- Supports both online (Firebase) and offline (local storage) modes
- Admin can upload CSV files to initialize student database
- Real-time attendance statistics update automatically

---

**Good luck with your interview!** 🎯

