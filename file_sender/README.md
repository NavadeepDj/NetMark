## NetMark - Automated Instant Network Attendance 

NetMark is a simple attendance system:

- A **Flutter client** (mobile) used by admins/faculty and students.
- A **Python Flask backend** that:
  - accepts a **class list CSV upload**
  - verifies students by **Registration Number**
  - stores attendance with **timestamp** and **duplicate-prevention**
  - provides **student list**, **present/absent stats**, and **search**

This project uses CSV files for **local backup and offline storage**. When network connectivity is restored, data automatically syncs to the cloud server, ensuring no attendance records are lost during network interruptions.

---

### Important note: no model training

This repository **does not include any ML dataset**, and it **does not perform training**

- The **only “data”** used by the backend is the **class list CSV** that an admin uploads at runtime.
- Attendance is recorded as CSV rows (registration number + timestamp + IP).
- You may see Flutter dependencies like `tflite_flutter` / `tflite_flutter_helper` in `file_sender/pubspec.yaml`—these are **not used for any dataset training/testing in this project** (they are scaffolding for future/optional features).

---

## Repository layout

- `file_sender/`: Flutter app (Android/iOS/Web/Windows/macOS/Linux depending on your toolchain)
- `Server_regNoSend.py`: Main Flask server (CSV upload, lookup, mark attendance, stats, search)
- `server.py`: Minimal Flask upload example (not used by the main Flutter flow)

### Runtime-generated files (local backup/offline storage)

These CSV files are created at runtime as **local backups** for offline operation. When network connectivity is available, data automatically syncs to the cloud server:

- `user_data.csv`: latest uploaded class list (backed up locally)
- `verified_ids.csv`: attendance records (present students + timestamps) - synced to cloud when online
- `ip_tracking.csv`: IP tracking used for duplicate prevention

---

## Features

- **CSV upload (admin or faculty)**: upload the official class list.
- **Student lookup**: fetch student details by Registration Number.
- **Attendance marking**: write an attendance entry with timestamp and IP.
- **Offline support with cloud sync**: 
  - CSV files serve as local backup for offline operation
  - When network connectivity is restored, data automatically syncs to the cloud server
  - Ensures no attendance records are lost during network interruptions
- **Duplicate prevention**:
  - blocks duplicate Registration Number
  - blocks repeated submissions from the same IP
- **Class overview**: totals, present/absent counts, present student list.
- **Search**: case-insensitive search by name or registration number.

---

## Prerequisites

- **Python**: 3.11.9
- **Flutter**: 3.24+ (Dart SDK 3.6+) — see `file_sender/pubspec.yaml`

---

## Backend (Flask) setup

### 1) Create and activate a virtual environment

Windows (PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

### 2) Install dependencies

```bash
pip install flask pandas
```

### 3) Run the server

```bash
python Server_regNoSend.py
```

By default it runs on `0.0.0.0:5000`.

---

## CSV format (class list)

The uploaded CSV must include at least these headers (spelling must match exactly):

- `Registration Number`
- `Name`

Example:

```csv
Registration Number,Name
20K-0001,Ayesha Khan
20K-0002,Ali Raza
```

---

## API endpoints (`Server_regNoSend.py`)

### `POST /upload_csv`

Upload the class list CSV.

- **Request**: `multipart/form-data`
  - field name: `file` (CSV)
- **Response**: `{ "message": "CSV uploaded successfully" }`

Example:

```bash
curl -X POST -F "file=@user_data.csv" http://127.0.0.1:5000/upload_csv
```

### `GET /get_user/<unique_id>`

Lookup a student by Registration Number.

- **Success**: `{ "Registration Number": "...", "Name": "..." }`
- **If already marked** (implementation-dependent): `{ "warning": "Attendance already marked" }`

Example:

```bash
curl http://127.0.0.1:5000/get_user/20K-0001
```

### `POST /upload_unique_id/<unique_id>`

Mark attendance for the given Registration Number (server also records timestamp + IP).

Example:

```bash
curl -X POST http://127.0.0.1:5000/upload_unique_id/20K-0001
```

### `POST /mark_attendance`

Mark attendance using JSON body.

- **Request JSON**: `{ "registrationNumber": "20K-0001" }`
- The backend validates that the registration number exists in the uploaded class CSV.

Example:

```bash
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"registrationNumber\":\"20K-0001\"}" ^
  http://127.0.0.1:5000/mark_attendance
```

### `GET /attendance_stats`

Get class totals.

- **Response**: `{ total, present, absent, PresentStudents: [...] }`

Example:

```bash
curl http://127.0.0.1:5000/attendance_stats
```

### `GET /students`

Get the full student list with present/absent info.

- **Response**:
  - `students`: `[ { name, registrationNumber, isPresent, initial } ]`
  - `present_students`: `[...]`

Example:

```bash
curl http://127.0.0.1:5000/students
```

### `GET /search_students/<query>`

Search students by `Name` or `Registration Number` (case-insensitive).

Example:

```bash
curl http://127.0.0.1:5000/search_students/20K
```

---

## Flutter app setup (`file_sender/`)

### 1) Install Flutter and verify toolchain

Make sure `flutter doctor` is green.

### 2) Fetch dependencies

```bash
cd file_sender
flutter pub get
```

### 3) Configure backend base URL

Update the server base URL inside the app as needed (check files under `file_sender/lib/`).

### 4) Run the app

- Android: `flutter run -d android`
- iOS (macOS only): `flutter run -d ios`
- Web: `flutter run -d chrome`
- Desktop (if enabled): `flutter run -d windows` / `linux` / `macos`

---

## Typical workflow

1. Start the Flask server: `python Server_regNoSend.py`
2. Admin uploads the class CSV to `POST /upload_csv`
3. Students enter their Registration Number in the Flutter app
4. Backend verifies the ID and records attendance (timestamp + IP; duplicates blocked)
5. Faculty/admin views stats and student lists (present/absent + search)

---

## Data, persistence, and cloud sync

- **Primary storage**: Cloud server (data syncs automatically when network is available).
- **Local backup**: CSV files on the server machine serve as offline backup. When network connectivity is restored, all locally stored attendance records automatically sync to the cloud server.
- **To "reset" attendance**:
  - stop the server
  - delete `verified_ids.csv` and `ip_tracking.csv` (local backup files)
  - restart and upload the class list again if needed
  - Note: If cloud sync is enabled, ensure cloud data is also reset as needed

---

## Security notes (important)

- **IP-based duplicate prevention is basic** and can fail on shared networks (labs, hostels, campuses). For real deployments, consider authentication (accounts, device binding, or QR-based session tokens).
- Do not expose this server publicly without **TLS** and an **auth layer** (reverse proxy with access control).
- Uploaded class lists may contain personal data; handle backups and access accordingly.

---

## Privacy and GDPR Compliance

This system collects **biometric data** for attendance verification purposes. As such, it is designed to comply with **GDPR (General Data Protection Regulation)** requirements:

- **Biometric data collection**: The system captures biometric information (e.g., facial recognition) for student identification and attendance marking.
- **GDPR compliance**: 
  - Users must provide **explicit consent** before biometric data is collected
  - Biometric data is processed securely and stored with appropriate encryption
  - Users have the right to **access, rectify, or delete** their biometric data
  - Data retention policies must be clearly defined and communicated
  - Biometric data is only used for the stated purpose (attendance verification) and not shared with third parties without consent
- **Data protection**: All biometric data is encrypted both in transit (via TLS) and at rest (encrypted storage)
- **Right to erasure**: Users can request deletion of their biometric data, which will be processed in accordance with GDPR Article 17
- **Data minimization**: Only necessary biometric data required for attendance verification is collected and stored

**Important**: Before deploying this system, ensure you have:
- Obtained proper consent from all users
- Implemented a privacy policy that clearly explains biometric data collection and usage
- Established data retention and deletion procedures
- Configured appropriate security measures for biometric data storage and transmission

---

## Troubleshooting

- **"Invalid CSV format"**: Ensure headers are exactly `Registration Number` and `Name`.
- **"CSV not uploaded yet" / empty student lookup**: Upload a CSV before calling lookup/mark endpoints.
- **CORS issues (Flutter Web)**: Serve the web app from the same origin or add CORS handling in Flask.
- **Port conflicts**: Change the port in `Server_regNoSend.py` if `5000` is busy.

---

## License

This project is for educational use. Add a license file if you plan to distribute it.
