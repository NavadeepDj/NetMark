// Firestore Setup Script for Student System
// Run this script to initialize Firestore collections

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://network-attendance-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

// Collection names
const COLLECTIONS = {
  STUDENTS: 'students',
  LOGIN_ATTEMPTS: 'loginAttempts',
  ATTENDANCE: 'attendance',
  CLASSES: 'classes',
  FACULTY: 'faculty'
};

// Create sample student document structure
const createSampleStudent = async () => {
  try {
    const studentsRef = db.collection(COLLECTIONS.STUDENTS);
    
    // Sample student data
    const sampleStudent = {
      profile: {
        email: 'sample@klu.ac.in',
        name: 'Sample Student',
        registrationNumber: '99220041389',
        firebaseUid: 'sample_firebase_uid',
        signupDate: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: null,
        isActive: true,
        role: 'student',
        department: 'Computer Science',
        year: '2024',
        phoneNumber: '+1234567890'
      },
      faceData: {
        embedding: new Array(128).fill(0).map(() => Math.random()),
        embeddingSize: 128,
        registeredAt: admin.firestore.FieldValue.serverTimestamp(),
        isVerified: true,
        confidence: 0.95
      },
      preferences: {
        notifications: true,
        faceLoginEnabled: true,
        theme: 'dark'
      }
    };
    
    // Add sample student
    const docRef = await studentsRef.add(sampleStudent);
    console.log('✅ Sample student created with ID:', docRef.id);
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Error creating sample student:', error);
    throw error;
  }
};

// Create sample login attempt
const createSampleLoginAttempt = async (studentId) => {
  try {
    const loginAttemptsRef = db.collection(COLLECTIONS.LOGIN_ATTEMPTS);
    
    const sampleAttempt = {
      studentId: studentId,
      email: 'sample@klu.ac.in',
      ipAddress: '192.168.1.100',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      attemptStatus: 'success',
      failureReason: null,
      attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      deviceInfo: {
        platform: 'Android',
        version: '13',
        model: 'Samsung Galaxy S21'
      },
      location: {
        latitude: 17.3850,
        longitude: 78.4867,
        address: 'Hyderabad, India'
      }
    };
    
    const docRef = await loginAttemptsRef.add(sampleAttempt);
    console.log('✅ Sample login attempt created with ID:', docRef.id);
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Error creating sample login attempt:', error);
    throw error;
  }
};

// Create sample attendance record
const createSampleAttendance = async (studentId) => {
  try {
    const attendanceRef = db.collection(COLLECTIONS.ATTENDANCE);
    
    const sampleAttendance = {
      studentId: studentId,
      classId: 'CS101_2024',
      className: 'Data Structures',
      attendanceDate: admin.firestore.FieldValue.serverTimestamp(),
      status: 'present',
      method: 'face_recognition',
      confidence: 0.92,
      location: {
        latitude: 17.3850,
        longitude: 78.4867,
        address: 'KLU Campus, Hyderabad'
      },
      facultyId: 'faculty_001',
      remarks: 'On time attendance'
    };
    
    const docRef = await attendanceRef.add(sampleAttendance);
    console.log('✅ Sample attendance record created with ID:', docRef.id);
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Error creating sample attendance record:', error);
    throw error;
  }
};

// Create indexes for better query performance
const createIndexes = async () => {
  try {
    console.log('📊 Creating Firestore indexes...');
    
    // Note: Indexes are created automatically by Firestore when you run queries
    // But you can also create them manually in the Firebase Console
    
    console.log('✅ Indexes will be created automatically when queries are run');
    console.log('💡 You can also create them manually in Firebase Console > Firestore > Indexes');
    
  } catch (error) {
    console.error('❌ Error creating indexes:', error);
  }
};

// Main setup function
const setupFirestore = async () => {
  try {
    console.log('🚀 Setting up Firestore collections for Student System...');
    
    // Create sample data
    const studentId = await createSampleStudent();
    await createSampleLoginAttempt(studentId);
    await createSampleAttendance(studentId);
    
    // Create indexes info
    await createIndexes();
    
    console.log('✅ Firestore setup completed successfully!');
    console.log('📋 Collections created:');
    console.log('   - students');
    console.log('   - loginAttempts');
    console.log('   - attendance');
    
  } catch (error) {
    console.error('❌ Setup failed:', error);
  }
};

// Run setup
setupFirestore();
