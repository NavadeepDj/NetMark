# NetMark - Quick Interview Reference

## 🎯 **30-Second Elevator Pitch**
"NetMark is a Flutter mobile app that uses face recognition to mark student attendance in real-time on a local network. It combines biometric authentication with a Flask backend for secure, automated attendance tracking."

---

## 🛠️ **Tech Stack (Quick)**
- **Frontend**: Flutter (Dart)
- **Face Recognition**: TensorFlow Lite (TFLite)
- **Backend**: Flask (Python) - REST API
- **Database**: Firebase Firestore + Local Storage (SharedPreferences)
- **Network**: Local instance network (HTTP)

---

## 🗺️ **Routes (Quick)**
```
/auth_check → Initial check
/login → Home screen
/signup → Registration (3 steps)
/face_verification → Face login
/user → Student attendance
/admin → Admin dashboard
/student_list → Student list (with filters)
```

---

## 🔄 **Key Flows**

### **Registration**:
Login → Sign Up → Enter Info → Capture Face → Store (Local + Firebase) → User Screen

### **Login**:
App Launch → Auth Check → Face Verification → Compare Embeddings → User Screen

### **Attendance**:
User Screen → Enter Reg No → Verify → Face Check → Mark Attendance → Success

### **Admin**:
Login → Dashboard → Upload CSV / View Stats / Manual Entry

---

## 🤖 **Face Recognition (Quick)**
- **Model**: TFLite (64-dim embeddings)
- **Process**: Image → Resize (112x112) → Extract 20 facial points → Generate embedding
- **Verification**: Cosine similarity (threshold: 0.75)
- **Storage**: SharedPreferences (local) + Firebase (cloud)

---

## 🌐 **API Endpoints**
- `GET /get_user/{regNo}` - Verify student
- `POST /upload_unique_id/{regNo}` - Mark attendance
- `POST /upload_csv` - Upload student list
- `GET /attendance_stats` - Get statistics
- `GET /students` - Get all students
- `POST /mark_attendance` - Manual marking (admin)

---

## 🔑 **Key Features**
1. Face recognition registration & login
2. Real-time attendance marking
3. Admin dashboard with statistics
4. CSV upload for student management
5. Offline support with cloud sync
6. Configurable recognition threshold
7. Device binding for security

---

## 💡 **Interview Talking Points**

### **Architecture**:
- "Clean separation: screens, services, widgets, utils"
- "Singleton pattern for face recognition service"
- "Named routing for navigation management"

### **Security**:
- "Two-factor: registration number + face verification"
- "Device binding prevents account sharing"
- "Local encryption of biometric data"

### **Performance**:
- "On-device face recognition (no server dependency)"
- "Local caching for offline support"
- "Efficient 64-dim embeddings (not full images)"

### **User Experience**:
- "Intuitive 3-step registration"
- "Real-time feedback and error handling"
- "Configurable settings for accuracy"

---

## 📊 **Data Flow**
```
User Input → Face Capture → TFLite Processing → Embedding Extraction
    ↓
Local Storage (SharedPreferences) + Firebase Firestore
    ↓
Face Verification → Cosine Similarity → Match/No Match
    ↓
API Call → Flask Server → Attendance Marked
```

---

## 🎨 **UI Highlights**
- Material Design with gradients
- Responsive layouts
- Loading states & error dialogs
- Smooth animations
- Clear user feedback

---

## ⚡ **Quick Answers**

**Q: Why Flutter?**
A: Cross-platform, single codebase, excellent performance, rich UI widgets.

**Q: Why TFLite?**
A: On-device processing, fast inference, privacy (no data sent to server), small model size.

**Q: How does face recognition work?**
A: Extract 64-dim embeddings from 20 facial key points, compare using cosine similarity.

**Q: Security concerns?**
A: Device binding, local encryption, two-factor verification, duplicate prevention.

**Q: Scalability?**
A: Local network instance, Firebase for sync, efficient embeddings, configurable thresholds.

---

**Remember**: Be confident, explain the flow clearly, and highlight the technical decisions you made! 🚀

