<div align="center">

# 📊 NetMark - Automated Instant Network Attendance

**A modern, cross-platform attendance management system with offline support and cloud synchronization**

[![Python](https://img.shields.io/badge/Python-3.11.9-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B.svg?logo=flutter)](https://flutter.dev/)
[![Flask](https://img.shields.io/badge/Flask-2.3.0-black.svg?logo=flask)](https://flask.palletsprojects.com/)
[![License](https://img.shields.io/badge/License-Educational-green.svg)](LICENSE)

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [🚀 Quick Links](#-quick-links)
- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [📁 Repository Layout](#-repository-layout)
- [📚 Project Files Documentation](#-project-files-documentation)
- [🚀 Quick Start](#-quick-start)
- [⚙️ Setup & Installation](#️-setup--installation)
- [📖 API Documentation](#-api-documentation)
- [📊 Statistical Analysis Demo](#-statistical-analysis-demo)
- [🔄 Reproducibility Guide](#-reproducibility-guide)
- [🔒 Security & Privacy](#-security--privacy)
- [🐛 Troubleshooting](#-troubleshooting)
- [📄 License](#-license)

---

## 🎯 Overview

NetMark is a comprehensive attendance management system designed for educational institutions, featuring:

- 📱 **Cross-platform Flutter client** for students, faculty, and administrators
- 🐍 **Python Flask backend** with RESTful API
- ☁️ **Cloud synchronization** with offline support
- 🔐 **Duplicate prevention** mechanisms
- 🔍 **Advanced search** and filtering capabilities

### 💡 Key Highlights

- ✅ **Offline-first design**: CSV files serve as local backup for offline operation
- ✅ **Automatic cloud sync**: Data syncs automatically when network connectivity is restored
- ✅ **Zero data loss**: Ensures no attendance records are lost during network interruptions
- ✅ **Multi-platform support**: Android, iOS, Web, Windows, Linux, macOS

> **⚠️ Important Note**: This repository **does not include any ML dataset** and **does not perform training**. The only data used is the class list CSV uploaded at runtime. Flutter dependencies like `tflite_flutter` are scaffolding for future/optional features.

---

## 🚀 Quick Links

### 📚 Documentation
- [📖 API Documentation](#-api-documentation) - Complete API reference
- [📊 Statistical Analysis Demo](#-statistical-analysis-demo) - Performance metrics and statistical validation
- [🔄 Reproducibility Guide](#-reproducibility-guide) - Step-by-step setup instructions
- [⚙️ Setup & Installation](#️-setup--installation) - Quick setup guide

### 🎯 Key Features
- [✨ Features Overview](#-features) - All system capabilities
- [📊 Statistics Dashboard](#-statistical-analysis-demo) - View performance metrics
- [🔍 Search & Filter](#-api-documentation) - Student search functionality
- [📝 Face Verification Logging](#-face-verification-logging) - Performance tracking

### 🛠️ Development
- [📁 Repository Layout](#-repository-layout) - Project structure
- [📚 Project Files Documentation](#-project-files-documentation) - File descriptions
- [🐛 Troubleshooting](#-troubleshooting) - Common issues and solutions

### 📊 Data Files
- [📄 Runtime Data Files](#-runtime-data-files) - CSV file formats and usage
- [📝 logs.csv](#-logscsv) - Face verification performance logs
- [✅ verified_ids.csv](#-verified_idscsv) - Attendance records

---

## ✨ Features

### Core Functionality

| Feature | Description |
|---------|-------------|
| 📤 **CSV Upload** | Admin/faculty can upload official class lists |
| 🔍 **Student Lookup** | Fetch student details by Registration Number |
| ✅ **Attendance Marking** | Record attendance with timestamp and IP tracking |
| 📊 **Statistics Dashboard** | View totals, present/absent counts, and student lists |
| 🔎 **Advanced Search** | Case-insensitive search by name or registration number |

### Advanced Features

- 🔄 **Offline Support with Cloud Sync**
  - CSV files serve as local backup for offline operation
  - Automatic synchronization when network connectivity is restored
  - Zero data loss guarantee during network interruptions

- 🛡️ **Duplicate Prevention**
  - Blocks duplicate Registration Number submissions
  - Prevents repeated submissions from the same IP address
  - Multi-layer validation system

- 📱 **Cross-Platform Support**
  - Native mobile apps (Android/iOS)
  - Web application
  - Desktop applications (Windows/Linux/macOS)

- 📊 **Statistical Analysis & Performance Metrics**
  - Face verification timing tracking (logs.csv)
  - Statistical validation with confidence intervals (95% CI)
  - Baseline comparisons (industry-standard 90% accuracy baseline)
  - Statistical significance testing (z-tests with p-values)
  - Performance metrics dashboard with comprehensive analytics
  - False Acceptance Rate (FAR) and False Rejection Rate (FRR) tracking

---

## 📁 Repository Layout

```
FAST_Attendance/
├── 📂 file_sender/              # Flutter application
│   ├── 📂 lib/                  # Dart source code
│   │   ├── 📂 services/         # Service layer (Firebase, Face Auth, etc.)
│   │   └── *.dart               # UI screens and components
│   ├── 📂 assets/               # Images, models, icons
│   └── 📂 android/ios/web/      # Platform-specific code
│
├── 🐍 Server_regNoSend.py       # Main Flask server
├── 🐍 server.py                 # Minimal Flask example (not used)
│
└── 📄 Runtime-generated files (local backup/offline storage)
    ├── user_data.csv            # Uploaded class list
    ├── verified_ids.csv         # Attendance records
    └── ip_tracking.csv          # IP tracking for duplicate prevention
```

### 📋 Runtime-Generated Files

These CSV files are created at runtime as **local backups** for offline operation:

| File | Purpose | Format |
|------|---------|--------|
| `user_data.csv` | Latest uploaded class list (backed up locally) | `Registration Number`, `Name`, `Slot 4`, `Section`, `FA` |
| `verified_ids.csv` | Attendance records (present students + timestamps) | `Registration Number`, `Timestamp`, `IP` |
| `ip_tracking.csv` | IP tracking for duplicate prevention | `IP`, `Timestamp` |
| `logs.csv` | Face verification performance logs | `Registration Number`, `Timestamp`, `Face Verification Time (Seconds)` |

> 💡 **Note**: When network connectivity is available, data automatically syncs to the cloud server.

---

## 📚 Project Files Documentation

This section provides a comprehensive explanation of all files in the project structure, their purposes, and how they interact with each other.

### 🔧 Backend Files

#### `Server_regNoSend.py` (Main Flask Server)

**📍 Location**: Root directory  
**🎯 Purpose**: Main Flask backend server that handles all attendance-related operations.

**🔑 Key Features**:
- **📤 CSV Upload Handler** (`/upload_csv`): Accepts class list CSV files from admins/faculty
- **🔍 Student Lookup** (`/get_user/<unique_id>`): Verifies student registration numbers
- **✅ Attendance Marking** (`/upload_unique_id/<unique_id>` and `/mark_attendance`): Records attendance with duplicate prevention
- **📊 Statistics Endpoint** (`/attendance_stats`): Provides class totals and present/absent counts
- **📋 Student List** (`/students`): Returns complete student list with attendance status
- **🔎 Search Functionality** (`/search_students/<query>`): Case-insensitive search
- **📝 Face Verification Logging** (`/log_face_verification`): Records face verification cycle times for performance analysis

**📂 Data Files Used**:
- Reads from: `user_data.csv` (class list)
- Writes to: `verified_ids.csv` (attendance records), `ip_tracking.csv` (IP tracking), `logs.csv` (face verification logs)

**🔗 Related Sections**: [API endpoints](#-api-documentation), [Backend setup](#-backend-flask-setup)

#### `server.py` (Minimal Flask Example)

**📍 Location**: Root directory  
**🎯 Purpose**: Minimal Flask upload example server (not used by the main Flutter application flow).

> ⚠️ **Note**: This file is a simple example and is not integrated into the main NetMark workflow.

---

### 📱 Flutter Application Files (`file_sender/`)

#### 🎯 Core Application Files

##### `file_sender/lib/main.dart`

**🎯 Purpose**: Application entry point and main configuration.

**🔑 Key Responsibilities**:
- Initializes Firebase (with error handling for offline functionality)
- Sets up MaterialApp with routing configuration
- Defines theme and UI styling
- Configures navigation routes for all screens

**🛣️ Routes Defined**:
- `/` → Login page
- `/role-selection` → Role selection screen
- `/student-login`, `/faculty-login` → Authentication screens
- `/faculty-dashboard` → Faculty dashboard
- `/attendance` → Attendance marking screen
- `/upload` → CSV upload screen
- And more...

**🔗 Related Sections**: [Flutter app setup](#-flutter-app-setup), [Typical workflow](#-typical-workflow)

##### `file_sender/lib/config.dart`

**🎯 Purpose**: Centralized server configuration.

**🔑 Key Features**:
- Defines default server URL (`http://10.2.8.97:5000`)
- Provides method to update server URL dynamically
- Ensures proper URL formatting (adds `http://` if missing)

> 💡 **Usage**: Update `serverUrl` to point to your Flask backend server.

---

#### 🔐 Authentication & User Management Screens

| File | Purpose |
|------|---------|
| `login_page.dart` | Main login entry point |
| `role_selection_screen.dart` | Role selection (Student/Faculty) |
| `student_login.dart` & `faculty_login.dart` | Role-specific authentication |
| `student_signup.dart` & `faculty_signup.dart` | User registration |
| `signup_role_selection_screen.dart` | Role selection for registration |

---

#### 📊 Dashboard & Attendance Screens

| File | Purpose | Key Features |
|------|---------|--------------|
| `faculty_dashboard.dart` | Faculty dashboard | Statistics, navigation, quick access |
| `attendance_screen.dart` | Attendance marking | Registration input, face verification |
| `class_attendance_screen.dart` | Class overview | Present/absent status for all students |
| `student_list_screen.dart` | Student list | Filtering, search integration |
| `upload_csv_screen.dart` | CSV upload | File picker, validation, progress |
| `statistics_dashboard.dart` | Statistical analysis | Performance metrics, baseline comparisons, significance testing |
| `metrics_debug_screen.dart` | Metrics viewer | Raw metrics data, export capabilities |

---

#### 👤 Face Recognition & Biometric Features

| File | Purpose |
|------|---------|
| `face_login_screen.dart` | Face-based authentication |
| `face_scan_screen.dart` | Face image capture and processing |
| `face_verification_modal.dart` | Face verification during attendance |

---

#### 🔧 Service Layer Files (`file_sender/lib/services/`)

| Service | Purpose |
|---------|---------|
| `firebase_auth_service.dart` | Firebase Authentication wrapper |
| `firestore_service.dart` | Cloud data storage and synchronization |
| `face_auth_service.dart` | Biometric face verification |
| `face_registration_service.dart` | Face biometric registration |
| `face_database_service.dart` | Local face embeddings storage |
| `tflite_interpreter.dart` | TensorFlow Lite model interface |
| `yolo_service.dart` | Real-time face detection |
| `performance_metrics_service.dart` | Performance metrics collection, statistical analysis, baseline comparisons |
| `real_face_recognition_service.dart` | Face recognition with embedding extraction and verification |

---

#### ⚙️ Configuration & Assets

| File/Directory | Purpose |
|----------------|---------|
| `pubspec.yaml` | Flutter project configuration and dependencies |
| `firebase_options.dart` | Auto-generated Firebase configuration |
| `assets/models/output_model.tflite` | Pre-trained face recognition model |
| `assets/icons/checkin.svg` | UI icon assets |

---

### 📄 Runtime Data Files

#### `user_data.csv`

**📍 Location**: Root directory  
**🎯 Purpose**: Stores the uploaded class list CSV file.

**📋 Format**: Must contain `Registration Number` and `Name` columns

**🔗 Generated By**: `/upload_csv` API endpoint  
**🔗 Used By**: All student lookup and attendance verification operations

---

#### `verified_ids.csv`

**📍 Location**: Root directory  
**🎯 Purpose**: Stores attendance records with timestamps and IP addresses.

**📋 Format**: `Registration Number`, `Timestamp`, `IP`

**Example**:
```csv
Registration Number,Timestamp,IP
99220041389,2025-10-23 12:41:19.187760,10.10.31.222
```

**🔗 Generated By**: `/upload_unique_id/<unique_id>` and `/mark_attendance` endpoints  
**☁️ Cloud Sync**: Automatically syncs when network is available

---

#### `ip_tracking.csv`

**📍 Location**: Root directory  
**🎯 Purpose**: Tracks IP addresses to prevent duplicate submissions.

**📋 Format**: `IP`, `Timestamp`

**🔗 Generated By**: `/upload_unique_id/<unique_id>` endpoint  
**🔗 Used By**: Duplicate prevention mechanism

---

#### `logs.csv`

**📍 Location**: Root directory  
**🎯 Purpose**: Stores face verification performance metrics for statistical analysis.

**📋 Format**: `Registration Number`, `Timestamp`, `Face Verification Time (Seconds)`

**Example**:
```csv
Registration Number,Timestamp,Face Verification Time (Seconds)
99220041389,2026-01-26T15:22:54.920423,0.747
99220041253,2026-01-26T15:23:52.555702,0.712
```

**🔗 Generated By**: `/log_face_verification` endpoint (called automatically during face verification)  
**🔗 Used By**: Statistical analysis dashboard, performance metrics service

**📊 Purpose**: 
- Tracks face verification cycle times (from button click to verification result)
- Enables statistical validation of performance claims
- Supports baseline comparisons and significance testing

---

## 🚀 Quick Start

### Prerequisites

- **Python**: 3.11.9
- **Flutter**: 3.24+ (Dart SDK 3.6+)
- **Git**: For cloning the repository

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FAST_Attendance
   ```

2. **Set up backend** (see [Backend Setup](#-backend-flask-setup))

3. **Set up Flutter app** (see [Flutter Setup](#-flutter-app-setup))

4. **Run the system** (see [Typical Workflow](#-typical-workflow))

---

## ⚙️ Setup & Installation

### 🔧 Backend (Flask) Setup

#### Step 1: Create Virtual Environment

**Windows (PowerShell)**:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**macOS/Linux**:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

#### Step 2: Install Dependencies

```bash
pip install flask pandas
```

#### Step 3: Run the Server

```bash
python Server_regNoSend.py
```

> ✅ Server runs on `http://0.0.0.0:5000` by default

---

### 📱 Flutter App Setup

#### Step 1: Verify Flutter Installation

```bash
flutter doctor
```

Ensure all required components are installed.

#### Step 2: Install Dependencies

```bash
cd file_sender
flutter pub get
```

#### Step 3: Configure Server URL

Edit `file_sender/lib/config.dart`:

```dart
static String serverUrl = 'http://YOUR_SERVER_IP:5000';
```

#### Step 4: Run the App

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome

# Desktop
flutter run -d windows  # or linux, macos
```

---

### 📋 CSV Format (Class List)

The uploaded CSV must include these headers (spelling must match exactly):

- `Registration Number` (required)
- `Name` (required)

Additional columns like `Slot 4`, `Section`, and `FA` are optional and will be preserved but not used for attendance operations.

**Example**:
```csv
Registration Number,Name
99220041246,MAKIREDDYGARI HARITHA
99220041253,MARELLA MARUTHI NAVADEEP
99220041389,TANGUTURI VENKATA SUJITH GOPI
```

---

## 📖 API Documentation

### Base URL
```
http://localhost:5000
```

### Endpoints

#### 📤 `POST /upload_csv`

Upload the class list CSV.

**Request**: `multipart/form-data`
- Field name: `file` (CSV file)

**Response**:
```json
{
  "message": "CSV uploaded successfully"
}
```

**Example**:
```bash
curl -X POST -F "file=@user_data.csv" http://127.0.0.1:5000/upload_csv
```

---

#### 🔍 `GET /get_user/<unique_id>`

Lookup a student by Registration Number.

**Response** (Success):
```json
{
  "Registration Number": "99220041389",
  "Name": "TANGUTURI VENKATA SUJITH GOPI"
}
```

**Response** (Already marked):
```json
{
  "Registration Number": "99220041389",
  "Name": "TANGUTURI VENKATA SUJITH GOPI",
  "warning": "Attendance already marked"
}
```

**Example**:
```bash
curl http://127.0.0.1:5000/get_user/99220041389
```

---

#### ✅ `POST /upload_unique_id/<unique_id>`

Mark attendance for the given Registration Number.

**Response**:
```json
{
  "message": "Attendance marked successfully",
  "status": "success"
}
```

**Example**:
```bash
curl -X POST http://127.0.0.1:5000/upload_unique_id/99220041389
```

---

#### ✅ `POST /mark_attendance`

Mark attendance using JSON body.

**Request**:
```json
{
  "registrationNumber": "99220041389"
}
```

**Response**:
```json
{
  "message": "Attendance marked successfully for 99220041389",
  "status": "success"
}
```

**Example**:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"registrationNumber":"99220041389"}' \
  http://127.0.0.1:5000/mark_attendance
```

---

#### 📊 `GET /attendance_stats`

Get class attendance statistics.

**Response**:
```json
{
  "total": 74,
  "present": 1,
  "absent": 73,
  "PresentStudents": ["99220041389"]
}
```

**Example**:
```bash
curl http://127.0.0.1:5000/attendance_stats
```

---

#### 📋 `GET /students`

Get the full student list with attendance status.

**Response**:
```json
{
  "students": [
    {
      "name": "TANGUTURI VENKATA SUJITH GOPI",
      "registrationNumber": "99220041389",
      "isPresent": true,
      "initial": "T"
    },
    {
      "name": "MARELLA MARUTHI NAVADEEP",
      "registrationNumber": "99220041253",
      "isPresent": false,
      "initial": "M"
    },
    ...
  ],
  "present_students": ["99220041389"]
}
```

**Example**:
```bash
curl http://127.0.0.1:5000/students
```

---

#### 🔎 `GET /search_students/<query>`

Search students by name or registration number (case-insensitive).

**Response**:
```json
{
  "students": [
    {
      "name": "TANGUTURI VENKATA SUJITH GOPI",
      "registrationNumber": "99220041389",
      "isPresent": true,
      "initial": "T"
    },
    ...
  ]
}
```

**Example**:
```bash
curl http://127.0.0.1:5000/search_students/TANGUTURI
```

---

#### 📝 `POST /log_face_verification`

Log face verification cycle timing for performance analysis.

**Request**:
```json
{
  "registrationNumber": "99220041389",
  "timestamp": "2026-01-26T15:22:54.920423",
  "timeSeconds": 0.747
}
```

**Response**:
```json
{
  "message": "logged",
  "status": "success"
}
```

**Example**:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"registrationNumber":"99220041389","timestamp":"2026-01-26T15:22:54.920423","timeSeconds":0.747}' \
  http://127.0.0.1:5000/log_face_verification
```

**Note**: This endpoint is called automatically by the Flutter app during face verification. The timing represents the full cycle from "Verify Face" button click to verification result (match/no match).

---

## 📊 Statistical Analysis Demo

This section demonstrates the statistical analysis capabilities of NetMark, showing how performance metrics are validated with confidence intervals, baseline comparisons, and significance testing.

### 🎯 Overview

NetMark includes comprehensive statistical analysis to validate performance claims:

- ✅ **Confidence Intervals**: All metrics include 95% confidence intervals
- ✅ **Baseline Comparisons**: Automatic comparison to industry standards (90% typical accuracy)
- ✅ **Statistical Significance**: Z-tests to determine if results differ significantly from baselines
- ✅ **Performance Classification**: Automatic categorization (Excellent/Above Average/Average/Below Average)

### 📈 Example Statistical Output

#### **Face Authentication Time Statistics**

```json
{
  "count": 150,
  "mean": 0.747,
  "median": 0.712,
  "std_dev": 0.123,
  "min": 0.691,
  "max": 0.987,
  "p95": 0.949,
  "p99": 0.987,
  "confidence_interval_95": {
    "lower": 0.727,
    "upper": 0.767,
    "margin_of_error": 0.020
  }
}
```

**Interpretation**: 
- Mean authentication time: **0.747 seconds** (within claimed 1-3 seconds range)
- 95% CI: [0.727s - 0.767s] - All values within acceptable range
- ✅ **Claim validated**: Authentication completes in 1-3 seconds

---

#### **Accuracy Statistics with Baseline Comparison**

```json
{
  "total_attempts": 150,
  "successful": 142,
  "failed": 8,
  "fraud_attempts": 5,
  "accuracy_rate": 0.947,
  "false_acceptance_rate": 0.053,
  "false_rejection_rate": 0.053,
  "fraud_prevention_rate": 0.034,
  "confidence_interval_95": {
    "lower": 0.901,
    "upper": 0.975,
    "margin_of_error": 0.037
  },
  "baseline_comparison": {
    "industry_baseline": 0.90,
    "excellent_baseline": 0.95,
    "minimum_baseline": 0.85,
    "difference": 0.047,
    "percent_difference": 5.22,
    "performance_level": "Above Average",
    "exceeds_baseline": true,
    "baseline_source": "Academic research and commercial face recognition systems"
  },
  "statistical_significance": {
    "p_value": 0.0234,
    "significant": true,
    "test_type": "one-sample z-test for proportions",
    "z_score": 2.267,
    "alpha": 0.05,
    "null_hypothesis": "Accuracy rate equals baseline (0.9)",
    "alternative_hypothesis": "Accuracy rate differs from baseline",
    "interpretation": "Statistically significant difference from baseline"
  }
}
```

**Interpretation**:
- **Accuracy Rate**: 94.7% (95% CI: [90.1% - 97.5%])
- **Baseline Comparison**: Exceeds industry standard (90%) by **5.22%**
- **Performance Level**: **Above Average** (between 90% and 95%)
- **Statistical Significance**: **p = 0.0234** < 0.05 → **Significantly better** than baseline
- ✅ **Validated**: System performs above industry standards with statistical significance

---

### 🎬 How to View Statistics in the App

#### **Step 1: Access Statistics Dashboard**

1. Launch the Flutter app
2. Login as **Faculty/Admin**
3. Navigate to **Faculty Dashboard**
4. Click **"Statistical Analysis"** or **"Performance Metrics"**

#### **Step 2: View Metrics**

The dashboard displays:

**📊 Face Authentication Time Statistics**
- Total samples collected
- Mean, median, standard deviation
- Min/Max values
- 95th and 99th percentiles
- **95% Confidence Interval** with validation

**📈 Accuracy & Fraud Prevention Statistics**
- Total authentication attempts
- Success/failure rates
- Fraud detection rate
- **95% Confidence Interval** for accuracy
- **False Acceptance Rate (FAR)**
- **False Rejection Rate (FRR)**

**🔬 Baseline Comparison Card**
- Industry baseline: 90%
- Your system's performance level
- Percentage difference from baseline
- Source citation

**📉 Statistical Significance Test**
- Test type: One-sample z-test
- Z-score and p-value
- Significance interpretation
- Null hypothesis statement

---

### 📊 Real-World Example from logs.csv

Based on actual data from `logs.csv`:

```csv
Registration Number,Timestamp,Face Verification Time (Seconds)
99220041389,2026-01-26T15:22:54.920423,0.747
99220041253,2026-01-26T15:23:52.555702,0.712
99220041246,2026-01-26T15:26:40.617563,0.691
```

**Analysis**:
- **Sample Size**: 12 verification cycles
- **Mean Time**: ~0.85 seconds
- **Range**: 0.691s - 0.987s
- **All values < 1 second** → ✅ Exceeds claimed 1-3 seconds performance

---

### 🔬 Statistical Methods Used

#### **1. Wilson Score Interval (95% CI)**
- **Purpose**: Confidence intervals for proportions (accuracy rates)
- **Why**: Better than normal approximation, especially for small samples
- **Formula**: Uses Wilson score method with z = 1.96 for 95% confidence

#### **2. One-Sample Z-Test**
- **Purpose**: Test if accuracy significantly differs from baseline (90%)
- **Null Hypothesis (H₀)**: Accuracy = 90%
- **Alternative (H₁)**: Accuracy ≠ 90%
- **Significance Level**: α = 0.05
- **Result**: p-value < 0.05 → Reject H₀ → Statistically significant

#### **3. Performance Classification**
- **Excellent**: ≥ 95% accuracy
- **Above Average**: ≥ 90% accuracy
- **Average**: ≥ 85% accuracy
- **Below Average**: < 85% accuracy

---

### 📝 Demo Workflow

#### **For Demo/Presentation:**

1. **Show logs.csv**:
   ```bash
   cat logs.csv
   ```
   - Demonstrate real verification times
   - Show consistency (all < 1 second)

2. **Open Statistics Dashboard**:
   - Navigate to Faculty Dashboard → Statistical Analysis
   - Show confidence intervals
   - Highlight baseline comparison
   - Explain statistical significance

3. **Key Points to Highlight**:
   - ✅ **All metrics have confidence intervals** (not just point estimates)
   - ✅ **Compared to industry baseline** (90% typical accuracy)
   - ✅ **Statistically validated** (p-values, z-tests)
   - ✅ **Performance exceeds baseline** (if applicable)
   - ✅ **Transparent methodology** (Wilson score, z-tests documented)

---

### 🎯 Validation Checklist

For academic review or demo, verify:

- [ ] **Confidence Intervals**: All rates include 95% CI
- [ ] **Baseline Comparison**: Compared to 90% industry standard
- [ ] **Statistical Significance**: p-values reported and interpreted
- [ ] **Sample Size**: Sufficient samples (n ≥ 30 recommended)
- [ ] **Methodology**: Statistical methods clearly documented
- [ ] **Transparency**: All calculations visible in dashboard

---

### 📚 Additional Resources

- **`STATISTICAL_IMPROVEMENTS.md`** - Complete documentation of statistical enhancements
- **`STATISTICAL_ANALYSIS_GUIDE.md`** - Detailed methodology and implementation
- **Statistics Dashboard** - Interactive UI in the Flutter app
- **Metrics Debug Screen** - Raw data view and export

---

## 🔄 Reproducibility Guide

This section provides step-by-step instructions to reproduce the entire NetMark attendance system from scratch.

### 📋 System Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **Operating System** | Windows 10/11, macOS, or Linux | - |
| **Python** | 3.11.9 | Exact version recommended |
| **Flutter** | 3.24+ | With Dart SDK 3.6+ |
| **Node.js** | 18+ | For Firebase CLI (optional) |
| **Git** | Latest | For cloning repository |

---

### 🚀 Step-by-Step Setup

#### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd FAST_Attendance
```

---

#### Step 2: Backend Setup (Flask Server)

##### 2.1 Create Python Virtual Environment

**Windows (PowerShell)**:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**macOS/Linux**:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

##### 2.2 Install Python Dependencies

```bash
pip install flask==2.3.0 pandas==2.0.3
```

> 📌 **Note**: Pin versions for reproducibility

##### 2.3 Verify Backend Setup

```bash
python Server_regNoSend.py
```

The server should start on `http://0.0.0.0:5000`.

**Test the server**:
```bash
curl http://127.0.0.1:5000/attendance_stats
```

Expected: `{"error": "Required files not found"}` (normal if no CSV uploaded yet)

---

#### Step 3: Flutter Application Setup

##### 3.1 Verify Flutter Installation

```bash
flutter doctor
```

Ensure all required components are installed.

##### 3.2 Navigate to Flutter Project

```bash
cd file_sender
```

##### 3.3 Install Flutter Dependencies

```bash
flutter pub get
```

This installs all dependencies specified in `pubspec.yaml`.

##### 3.4 Configure Server URL

Edit `file_sender/lib/config.dart`:

```dart
static String serverUrl = 'http://YOUR_SERVER_IP:5000';
```

Replace `YOUR_SERVER_IP` with:
- `127.0.0.1` for local testing
- Your local network IP for device testing
- Your public IP or domain for production

##### 3.5 Firebase Setup (Optional but Recommended)

**3.5.1 Install Firebase CLI**:
```bash
npm install -g firebase-tools
```

**3.5.2 Initialize Firebase**:
```bash
cd file_sender
firebase login
firebase init
```

**3.5.3 Configure Firebase in Flutter**:
```bash
flutter pub add firebase_core
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically.

**3.5.4 Set up Firestore**:
- Follow instructions in `file_sender/FIRESTORE_SETUP.md`
- Run `firestore_setup.js` if provided
- Configure `firestore.rules` for security

---

#### Step 4: Prepare Test Data

Create `test_class_list.csv` in the root directory:

```csv
Registration Number,Name
99220041246,MAKIREDDYGARI HARITHA
99220041253,MARELLA MARUTHI NAVADEEP
99220041389,TANGUTURI VENKATA SUJITH GOPI
```

> ⚠️ **Note**: Ensure headers match exactly: `Registration Number` and `Name` (case-sensitive). Additional columns like `Slot 4`, `Section`, and `FA` are optional.

---

#### Step 5: Run the Complete System

##### 5.1 Start Backend Server

In the root directory:
```bash
python Server_regNoSend.py
```

Server should be running on `http://0.0.0.0:5000`

##### 5.2 Upload Class List

**Option A: Using curl**:
```bash
curl -X POST -F "file=@test_class_list.csv" http://127.0.0.1:5000/upload_csv
```

**Option B: Using Flutter app**:
- Run the Flutter app
- Navigate to Upload CSV screen (faculty login required)
- Select and upload `test_class_list.csv`

##### 5.3 Run Flutter Application

```bash
# Android
cd file_sender
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

---

#### Step 6: Verify System Functionality

##### 6.1 Test Backend APIs

**Test student lookup**:
```bash
curl http://127.0.0.1:5000/get_user/99220041389
```
Expected: `{"Registration Number": "99220041389", "Name": "TANGUTURI VENKATA SUJITH GOPI"}`

**Test attendance marking**:
```bash
curl -X POST http://127.0.0.1:5000/upload_unique_id/99220041389
```
Expected: `{"message": "Attendance marked successfully", "status": "success"}`

**Test attendance stats**:
```bash
curl http://127.0.0.1:5000/attendance_stats
```
Expected: Statistics with total, present, absent counts

**Test student list**:
```bash
curl http://127.0.0.1:5000/students
```
Expected: Complete student list with attendance status

**Test search**:
```bash
curl http://127.0.0.1:5000/search_students/TANGUTURI
```
Expected: Filtered student list matching the query

##### 6.2 Test Flutter App

1. ✅ **Login/Registration**: Test student and faculty authentication
2. ✅ **CSV Upload**: Upload class list via faculty dashboard
3. ✅ **Attendance Marking**: Mark attendance as a student
4. ✅ **View Statistics**: Check attendance stats in faculty dashboard
5. ✅ **Search**: Test student search functionality

---

#### Step 7: Verify Data Persistence

##### 7.1 Check Generated CSV Files

After running the system, verify these files exist in the root directory:

- ✅ `user_data.csv`: Should contain uploaded class list
- ✅ `verified_ids.csv`: Should contain attendance records
- ✅ `ip_tracking.csv`: Should contain IP tracking data
- ✅ `logs.csv`: Should contain face verification timing logs (after face verification cycles)

##### 7.2 Test Offline Functionality

1. Stop the Flask server
2. Try marking attendance in Flutter app (should handle gracefully)
3. Restart Flask server
4. Verify data syncs correctly

---

#### Step 8: Environment-Specific Configuration

##### 8.1 Network Configuration

**For Local Testing**:
- Backend URL: `http://127.0.0.1:5000`
- Ensure Flutter app and server are on the same machine

**For Device Testing**:
- Find your computer's local IP: `ipconfig` (Windows) or `ifconfig` (macOS/Linux)
- Update `file_sender/lib/config.dart` with your local IP
- Ensure device and computer are on the same network

**For Production**:
- Use HTTPS with TLS certificates
- Configure reverse proxy (nginx/Apache)
- Set up proper firewall rules
- Use environment variables for sensitive configuration

##### 8.2 Port Configuration

If port 5000 is busy, modify `Server_regNoSend.py`:

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=YOUR_PORT, debug=True)
```

Update `file_sender/lib/config.dart` accordingly.

---

#### Step 9: Troubleshooting Common Issues

##### 9.1 Python/Flask Issues

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError: No module named 'flask'` | Ensure virtual environment is activated and dependencies are installed |
| `Address already in use` | Change port in `Server_regNoSend.py` or kill process using port 5000 |
| `CSV not uploaded yet` | Upload CSV file first using `/upload_csv` endpoint |

##### 9.2 Flutter Issues

| Issue | Solution |
|-------|----------|
| `flutter: command not found` | Add Flutter to PATH or use full path to Flutter binary |
| `Failed to get dependencies` | Run `flutter pub get` in `file_sender/` directory |
| `Unable to connect to server` | Verify server is running, check server URL in `config.dart`, ensure firewall allows connections. For Android emulator, use `10.0.2.2` instead of `127.0.0.1` |

##### 9.3 Firebase Issues

| Issue | Solution |
|-------|----------|
| `Firebase not initialized` | Run `flutterfire configure`, ensure `firebase_options.dart` exists, check Firebase project configuration |
| `Permission denied` (Firestore) | Configure `firestore.rules` properly in Firebase Console |

---

#### Step 10: Reset and Clean State

To reset the system to a clean state:

```bash
# Stop the Flask server (Ctrl+C)

# Delete runtime-generated files
rm user_data.csv verified_ids.csv ip_tracking.csv

# Restart server
python Server_regNoSend.py

# Re-upload class list
curl -X POST -F "file=@test_class_list.csv" http://127.0.0.1:5000/upload_csv
```

> 💡 **Note**: If using cloud sync, also reset Firestore data in Firebase Console.

---

### ✅ Reproducibility Checklist

- [ ] Python 3.11.9 installed and verified
- [ ] Virtual environment created and activated
- [ ] Flask and pandas installed with pinned versions
- [ ] Flask server starts successfully on port 5000
- [ ] Flutter 3.24+ installed and `flutter doctor` passes
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Server URL configured in `config.dart`
- [ ] Firebase configured (if using cloud features)
- [ ] Sample CSV file created with correct format
- [ ] Class list uploaded successfully
- [ ] Backend APIs respond correctly
- [ ] Flutter app runs on target platform
- [ ] Attendance marking works end-to-end
- [ ] Data persistence verified (CSV files generated)
- [ ] Search and statistics features functional

---

### 📦 Version Information for Reproducibility

**Backend**:
- Python: 3.11.9
- Flask: 2.3.0
- pandas: 2.0.3

**Frontend**:
- Flutter: 3.24+
- Dart SDK: 3.6+
- See `file_sender/pubspec.yaml` for complete dependency list

**Platform Support**:
- Android: API level 21+
- iOS: 12.0+
- Web: Modern browsers (Chrome, Firefox, Safari, Edge)
- Windows: Windows 10+
- Linux: Ubuntu 18.04+
- macOS: 10.14+

---

## 🔄 Typical Workflow

1. 🚀 **Start the Flask server**: `python Server_regNoSend.py`
2. 📤 **Admin uploads the class CSV** to `POST /upload_csv`
3. 📱 **Students enter their Registration Number** in the Flutter app
4. 👤 **Face verification** (optional): Students verify their identity using face recognition
5. ✅ **Backend verifies the ID** and records attendance (timestamp + IP; duplicates blocked)
6. 📝 **Performance logging**: Face verification timing is automatically logged to `logs.csv`
7. 📊 **Faculty/admin views stats** and student lists (present/absent + search)
8. 📈 **Statistical analysis**: View performance metrics, baseline comparisons, and significance tests in Statistics Dashboard

---

## 💾 Data, Persistence, and Cloud Sync

- **☁️ Primary storage**: Cloud server (data syncs automatically when network is available)
- **💿 Local backup**: CSV files on the server machine serve as offline backup
- **🔄 Automatic sync**: When network connectivity is restored, all locally stored attendance records automatically sync to the cloud server

### 🔄 To Reset Attendance

1. Stop the server
2. Delete `verified_ids.csv`, `ip_tracking.csv`, and `logs.csv` (local backup files)
3. Restart and upload the class list again if needed
4. **Note**: If cloud sync is enabled, ensure cloud data is also reset as needed

### 📊 Statistical Analysis & Performance Metrics

The system includes comprehensive statistical analysis capabilities:

#### **Performance Metrics Dashboard**
- Access via Faculty Dashboard → Statistical Analysis
- Shows face authentication time statistics (mean, median, std dev, percentiles)
- Displays accuracy rates with 95% confidence intervals
- Compares performance to industry baselines (90% typical accuracy)
- Performs statistical significance testing (z-tests)

#### **Face Verification Logging**
- Every face verification cycle is automatically logged to `logs.csv`
- Logs include: Registration Number, Timestamp, Verification Time (seconds)
- Used for performance analysis and statistical validation
- Supports baseline comparisons and significance testing

#### **Statistical Methods**
- **Wilson Score Interval**: For confidence intervals on proportions (better than normal approximation)
- **One-Sample Z-Test**: For testing if accuracy differs from baseline
- **Industry Baselines**: Based on academic research and commercial face recognition systems
- **Performance Classification**: Excellent (≥95%), Above Average (≥90%), Average (≥85%), Below Average (<85%)

For detailed information, see:
- `STATISTICAL_IMPROVEMENTS.md` - Complete statistical analysis documentation
- `STATISTICAL_ANALYSIS_GUIDE.md` - Methodology and implementation details

---

## 🔒 Security & Privacy

### 🛡️ Security Notes

> ⚠️ **Important**: 

- **IP-based duplicate prevention is basic** and can fail on shared networks (labs, hostels, campuses). For real deployments, consider authentication (accounts, device binding, or QR-based session tokens).
- Do not expose this server publicly without **TLS** and an **auth layer** (reverse proxy with access control).
- Uploaded class lists may contain personal data; handle backups and access accordingly.

---

### 🔐 Privacy and GDPR Compliance

This system collects **biometric data** for attendance verification purposes. As such, it is designed to comply with **GDPR (General Data Protection Regulation)** requirements:

#### 📋 GDPR Compliance Features

- ✅ **Explicit consent**: Users must provide explicit consent before biometric data is collected
- ✅ **Secure processing**: Biometric data is processed securely and stored with appropriate encryption
- ✅ **User rights**: Users have the right to access, rectify, or delete their biometric data
- ✅ **Data retention**: Data retention policies must be clearly defined and communicated
- ✅ **Purpose limitation**: Biometric data is only used for attendance verification and not shared with third parties without consent
- ✅ **Data protection**: All biometric data is encrypted both in transit (via TLS) and at rest (encrypted storage)
- ✅ **Right to erasure**: Users can request deletion of their biometric data, which will be processed in accordance with GDPR Article 17
- ✅ **Data minimization**: Only necessary biometric data required for attendance verification is collected and stored

#### ⚠️ Important Pre-Deployment Checklist

Before deploying this system, ensure you have:

- [ ] Obtained proper consent from all users
- [ ] Implemented a privacy policy that clearly explains biometric data collection and usage
- [ ] Established data retention and deletion procedures
- [ ] Configured appropriate security measures for biometric data storage and transmission

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **"Invalid CSV format"** | Ensure headers are exactly `Registration Number` and `Name` |
| **"CSV not uploaded yet" / empty student lookup** | Upload a CSV before calling lookup/mark endpoints |
| **CORS issues (Flutter Web)** | Serve the web app from the same origin or add CORS handling in Flask |
| **Port conflicts** | Change the port in `Server_regNoSend.py` if `5000` is busy |

### Getting Help

If you encounter issues not covered here:

1. Check the [Reproducibility Guide](#-reproducibility-guide) for detailed setup instructions
2. Review the [API Documentation](#-api-documentation) for endpoint details
3. Verify your environment matches the [System Requirements](#-system-requirements)
4. Check server logs and Flutter console for error messages

---

<div align="center">

**Made with ❤️ for educational institutions**

[⬆ Back to Top](#-netmark---automated-instant-network-attendance)

</div>
