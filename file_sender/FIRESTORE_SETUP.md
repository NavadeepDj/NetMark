# 🔥 Firestore Setup Guide for Student System

This guide will help you set up Firestore collections for the student login and signup system.

## 📋 Prerequisites

1. Firebase project created (`network-attendance`)
2. Firestore enabled in Firebase Console
3. Authentication enabled
4. Flutter app configured with Firebase

## 🗄️ Collections Structure

### 📝 Document ID Naming Convention

**Students Collection**: Document IDs are based on student names for easy identification:
- **Format**: `{student-name-sanitized}`
- **Example**: `john_doe` (for "John Doe")
- **Sanitization Rules**:
  - Removes special characters
  - Replaces spaces with underscores
  - Converts to lowercase
  - Adds `student_` prefix if name starts with number
  - Limits to 150 characters (Firestore limit)
  - Adds registration number suffix if duplicate exists

**Examples**:
- "John Doe" → `john_doe`
- "Mary Jane Smith" → `mary_jane_smith`
- "123 Student" → `student_123_student`
- "John@Doe!" → `johndoe`

### 1. **Students Collection** (`students`)
```javascript
students/{student-name-sanitized}/  # Document ID is based on student name
├── profile: {
│     email: "student@klu.ac.in",
│     name: "John Doe",
│     registrationNumber: "99220041389",
│     firebaseUid: "firebase_auth_uid",
│     signupDate: timestamp,
│     lastLogin: timestamp,
│     isActive: true,
│     role: "student",
│     department: "Computer Science",
│     year: "2024",
│     phoneNumber: "+1234567890"
│   }
├── faceData: {
│     embedding: [0.1, 0.2, ...], // 128-dimensional array
│     embeddingSize: 128,
│     registeredAt: timestamp,
│     isVerified: true,
│     confidence: 0.95
│   }
└── preferences: {
      notifications: true,
      faceLoginEnabled: true,
      theme: "dark"
    }
```

### 2. **Login Attempts Collection** (`loginAttempts`)
```javascript
loginAttempts/{attemptId}/
├── studentId: "student_id",
├── email: "student@klu.ac.in",
├── ipAddress: "192.168.1.1",
├── userAgent: "Mozilla/5.0...",
├── attemptStatus: "success" | "failed" | "blocked",
├── failureReason: "invalid-credential",
├── attemptedAt: timestamp,
├── deviceInfo: {
│     platform: "Android",
│     version: "13",
│     model: "Samsung Galaxy S21"
│   }
└── location: {
      latitude: 17.3850,
      longitude: 78.4867,
      address: "Hyderabad, India"
    }
```

### 3. **Attendance Collection** (`attendance`)
```javascript
attendance/{attendanceId}/
├── studentId: "student_id",
├── classId: "CS101_2024",
├── className: "Data Structures",
├── attendanceDate: timestamp,
├── status: "present" | "absent" | "late",
├── method: "face_recognition" | "manual",
├── confidence: 0.92,
├── location: {
│     latitude: 17.3850,
│     longitude: 78.4867,
│     address: "KLU Campus, Hyderabad"
│   }
├── facultyId: "faculty_001",
└── remarks: "On time attendance"
```

## 🛠️ Setup Steps

### Step 1: Enable Firestore
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`network-attendance`)
3. Navigate to **Firestore Database**
4. Click **Create database**
5. Choose **Start in test mode** (we'll add security rules later)
6. Select a location (choose closest to your users)

### Step 2: Deploy Security Rules
1. In Firebase Console, go to **Firestore Database** > **Rules**
2. Replace the default rules with the content from `firestore.rules`
3. Click **Publish**

### Step 3: Create Collections (Optional - Auto-created)
Collections will be created automatically when you add the first document. However, you can create them manually:

1. Go to **Firestore Database** > **Data**
2. Click **Start collection**
3. Create these collections:
   - `students`
   - `loginAttempts`
   - `attendance`
   - `classes`
   - `faculty`

### Step 4: Install Dependencies
```bash
cd file_sender
flutter pub get
```

### Step 5: Test the Setup
Run the app and test student signup/login functionality.

## 🔐 Security Rules Explained

### Students Collection
- **Students**: Can read/write their own data
- **Faculty**: Can read student data
- **Admin**: Can read/write all student data

### Login Attempts Collection
- **Students**: Can read their own login attempts
- **Faculty/Admin**: Can read all login attempts
- **System**: Can write login attempts

### Attendance Collection
- **Students**: Can read their own attendance
- **Faculty**: Can read/write attendance for their classes
- **Admin**: Can read/write all attendance

## 📊 Indexes

Firestore will automatically create indexes when you run queries. However, for better performance, you can create composite indexes manually:

### Required Indexes:
1. **Students Collection**:
   - `profile.firebaseUid` (Ascending)
   - `profile.isActive` (Ascending)

2. **Login Attempts Collection**:
   - `email` (Ascending)
   - `attemptStatus` (Ascending)
   - `attemptedAt` (Descending)

3. **Attendance Collection**:
   - `studentId` (Ascending)
   - `attendanceDate` (Descending)

## 🚀 Usage Examples

### Create a Student
```dart
final studentId = await FirestoreService.createStudent(
  email: 'student@klu.ac.in',
  name: 'John Doe',
  registrationNumber: '99220041389',
  firebaseUid: 'firebase_auth_uid',
  faceEmbedding: [0.1, 0.2, ...], // 128-dimensional array
  department: 'Computer Science',
  year: '2024',
);
```

### Authenticate Student
```dart
final student = await FirestoreService.getStudentByFirebaseUid('firebase_auth_uid');
if (student != null) {
  await FirestoreService.updateLastLogin(student['id']);
}
```

### Face Recognition Login
```dart
final student = await FirestoreService.findStudentByFaceSimilarity(
  capturedEmbedding,
  threshold: 0.75,
);
```

### Record Attendance
```dart
await FirestoreService.recordAttendance(
  studentId: 'student_id',
  classId: 'CS101_2024',
  className: 'Data Structures',
  status: 'present',
  method: 'face_recognition',
  confidence: 0.92,
);
```

## 🔍 Monitoring and Analytics

### View Data in Firebase Console
1. Go to **Firestore Database** > **Data**
2. Browse collections and documents
3. Use the query interface to filter data

### Monitor Usage
1. Go to **Firestore Database** > **Usage**
2. View read/write operations
3. Monitor storage usage

### Security Monitoring
1. Go to **Authentication** > **Users**
2. View user activity
3. Monitor failed login attempts

## 🛠️ Troubleshooting

### Common Issues:

1. **Permission Denied**:
   - Check security rules
   - Verify user authentication
   - Ensure proper role assignment

2. **Index Errors**:
   - Create required indexes in Firebase Console
   - Wait for index creation to complete

3. **Data Not Appearing**:
   - Check collection names (case-sensitive)
   - Verify field names match exactly
   - Check security rules

### Debug Tips:
- Use Firebase Console to inspect data
- Check Flutter console for error messages
- Verify Firebase project configuration
- Test with simple queries first

## 📈 Performance Optimization

1. **Use Indexes**: Create composite indexes for complex queries
2. **Limit Results**: Use `.limit()` for large datasets
3. **Pagination**: Implement pagination for large lists
4. **Caching**: Use local caching for frequently accessed data
5. **Batch Operations**: Use batch writes for multiple operations

## 🔒 Security Best Practices

1. **Validate Data**: Always validate input data
2. **Use Security Rules**: Implement proper access control
3. **Monitor Activity**: Track suspicious login attempts
4. **Regular Audits**: Review security rules periodically
5. **Data Encryption**: Consider encrypting sensitive data

## 📞 Support

If you encounter issues:
1. Check Firebase Console for errors
2. Review Flutter console logs
3. Verify network connectivity
4. Check Firebase project configuration
5. Consult Firebase documentation

---

**Note**: This setup provides a complete student management system with Firebase Firestore. All collections will be created automatically when you start using the app.
