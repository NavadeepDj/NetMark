## FAST Attendance
An attendance system with a Flutter client and a Python Flask backend. Admins upload a class CSV, students identify themselves by registration number, and the server records attendance with timestamps and basic IP-based duplicate detection. The app also shows class lists, present/absent counts, and search.

### Repository layout
- `file_sender/` — Flutter app (Android, iOS, web, desktop)
- `Server_regNoSend.py` — Main Flask server for CSV upload, student lookup, attendance marking, stats and search
- `server.py` — Minimal Flask file-upload example (not used in main flow)
- `user_data.csv` — Latest uploaded class list (generated at runtime)
- `verified_ids.csv` — Attendance records (generated at runtime)
- `ip_tracking.csv` — IP tracking for duplicate prevention (generated at runtime)

## Features
- **CSV upload**: Admin uploads a CSV of students.
- **Student verification**: Lookup by Registration Number with name confirmation.
- **Attendance marking**: Records Registration Number, timestamp, and IP.
- **Duplicate prevention**: Blocks multiple submissions from the same IP or for the same Registration Number.
- **Class stats**: Total, present, and absent counts; list of present students.
- **Search**: Filter students by name or registration number.

## Prerequisites
- Python 3.9+
- Flutter 3.24+ (Dart SDK 3.6+) — see `file_sender/pubspec.yaml`

## Backend setup (Flask)
1. Create and activate a virtual environment.
   - Windows (PowerShell):
     ```powershell
     python -m venv .venv
     .\.venv\Scripts\Activate.ps1
     ```
2. Install dependencies:
   ```bash
   pip install flask pandas
   ```
3. Run the server (default: `0.0.0.0:5000`):
   ```bash
   python Server_regNoSend.py
   ```

### CSV format
The uploaded CSV must include at least these headers:
- `Registration Number`
- `Name`

Example (first few rows):
```csv
Registration Number,Name
20K-0001,Ayesha Khan
20K-0002,Ali Raza
```

### API endpoints (Server_regNoSend.py)
- `POST /upload_csv`
  - multipart form field: `file` (CSV)
  - Response: `{ "message": "CSV uploaded successfully" }`

- `GET /get_user/<unique_id>`
  - Returns `{ Registration Number, Name }` or `{ warning: "Attendance already marked" }` if already present.

- `POST /upload_unique_id/<unique_id>`
  - Marks attendance for the given registration number with timestamp and IP.
  - Prevents multiple attempts from same IP or duplicate IDs.

- `POST /mark_attendance`
  - JSON body: `{ "registrationNumber": "20K-0001" }`
  - Marks attendance after validating the registration number exists in the CSV.

- `GET /attendance_stats`
  - Returns `{ total, present, absent, PresentStudents: [...] }`.

- `GET /students`
  - Returns `{ students: [ { name, registrationNumber, isPresent, initial } ], present_students: [...] }`.

- `GET /search_students/<query>`
  - Case-insensitive search on `Name` or `Registration Number`.

Note: `server.py` contains a simple `/upload` example and is not used by the Flutter client.

## Flutter app setup
1. Install Flutter per official docs and ensure `flutter doctor` passes.
2. Fetch dependencies:
   ```bash
   cd file_sender
   flutter pub get
   ```
3. Configure server base URL inside the app as needed (see files under `file_sender/lib/`).
4. Run the app:
   - Android: `flutter run -d android`
   - iOS (on macOS): `flutter run -d ios`
   - Web: `flutter run -d chrome`
   - Windows/Linux/macOS desktop targets are also available depending on your toolchain.

### Notable Flutter dependencies
Defined in `file_sender/pubspec.yaml`:
- `http`, `file_picker`, `image_picker`, `path_provider`
- `tflite_flutter`, `tflite_flutter_helper` (ML helpers if needed in future)
- `firebase_core`, `firebase_auth` (auth scaffolding)

## Typical workflow
1. Start Flask server: `python Server_regNoSend.py`.
2. Admin uploads class CSV via the app or an API client to `/upload_csv`.
3. Students enter their Registration Number in the app.
4. Server validates and records attendance, preventing duplicates.
5. Faculty view stats and student lists in the app.

## Security and data notes
- IP-based duplicate prevention is basic and can be bypassed on shared networks; consider stronger device/account auth for production.
- CSVs are stored on the server host; ensure proper access control and backups as needed.
- Avoid exposing the server publicly without TLS and authentication in front (e.g., reverse proxy with auth).

## Troubleshooting
- "Invalid CSV format": Ensure headers `Registration Number` and `Name` exist and are spelled exactly.
- "CSV not uploaded yet": Upload the CSV before hitting lookup or mark endpoints.
- CORS issues (for web): Serve the Flutter web app from the same origin or add CORS handling to Flask.
- Port conflicts: Change the Flask port in `Server_regNoSend.py` if `5000` is in use.

## License
This project is for educational use. Add a suitable open-source license if you plan to distribute.
