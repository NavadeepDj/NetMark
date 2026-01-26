from flask import Flask, request, jsonify
import pandas as pd
import os
import datetime
import logging
import time
import threading
from collections import defaultdict

app = Flask(__name__)

CSV_FILE = "user_data.csv"
VERIFIED_IDS_FILE = "verified_ids.csv"
IP_TRACKING_FILE = "ip_tracking.csv"
LOGS_FILE = "logs.csv"
SCALABILITY_METRICS_FILE = "scalability_metrics.csv"

# Set up logging
logging.basicConfig(level=logging.INFO)

# In-memory metrics storage for scalability testing
_scalability_metrics = {
    'response_times': defaultdict(list),  # endpoint -> [response_times]
    'concurrent_requests': 0,
    'total_requests': 0,
    'failed_requests': 0,
    'start_time': None,
    'test_active': False
}
_metrics_lock = threading.Lock()

def _ensure_logs_file():
    """Ensure logs.csv exists with the correct header."""
    header = "Registration Number,Timestamp,Face Verification Time (Seconds)\n"
    if not os.path.exists(LOGS_FILE):
        with open(LOGS_FILE, "w", encoding="utf-8") as f:
            f.write(header)
        return
    # If file exists but is empty, add header
    if os.path.getsize(LOGS_FILE) == 0:
        with open(LOGS_FILE, "w", encoding="utf-8") as f:
            f.write(header)

@app.route('/log_face_verification', methods=['POST'])
def log_face_verification():
    """Append one face verification cycle timing to logs.csv."""
    try:
        data = request.get_json(force=True, silent=True) or {}
        registration_number = str(data.get('registrationNumber', '')).strip()
        time_seconds = data.get('timeSeconds', None)
        timestamp = data.get('timestamp', None)

        if not registration_number:
            return jsonify({"error": "registrationNumber is required"}), 400
        if time_seconds is None:
            return jsonify({"error": "timeSeconds is required"}), 400

        # Timestamp: use client-provided ISO string if present, else server time
        if not timestamp:
            timestamp = datetime.datetime.now().isoformat()

        # Normalize time to 3 decimal places string
        try:
            time_seconds_val = float(time_seconds)
        except Exception:
            return jsonify({"error": "timeSeconds must be a number"}), 400

        _ensure_logs_file()

        with open(LOGS_FILE, "a", encoding="utf-8") as f:
            f.write(f"{registration_number},{timestamp},{time_seconds_val:.3f}\n")

        return jsonify({"message": "logged", "status": "success"}), 200
    except Exception as e:
        logging.exception("Error logging face verification")
        return jsonify({"error": f"Error logging face verification: {e}"}), 500

# Middleware to track response times for scalability analysis
@app.before_request
def before_request():
    if _scalability_metrics['test_active']:
        request.start_time = time.perf_counter()

@app.after_request
def after_request(response):
    if _scalability_metrics['test_active'] and hasattr(request, 'start_time'):
        response_time = time.perf_counter() - request.start_time
        endpoint = request.endpoint or request.path
        with _metrics_lock:
            _scalability_metrics['response_times'][endpoint].append(response_time)
            _scalability_metrics['total_requests'] += 1
            if response.status_code >= 400:
                _scalability_metrics['failed_requests'] += 1
    return response

@app.route('/upload_csv', methods=['POST'])
def upload_csv():
    """Admin uploads the CSV file."""
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        file.save(CSV_FILE)
        return jsonify({"message": "CSV uploaded successfully"}), 200
    except Exception as e:
        return jsonify({"error": f"Error uploading CSV: {e}"}), 500


@app.route('/get_user/<unique_id>', methods=['GET'])  
def get_user(unique_id):
    """Fetch user details by registration number."""
    if not os.path.exists(CSV_FILE):
        return jsonify({"error": "CSV not uploaded yet"}), 400

    try:
        df = pd.read_csv(CSV_FILE)

        # Ensure the column exists and compare as strings
        if 'Registration Number' not in df.columns:
            return jsonify({"error": "Invalid CSV format"}), 400
        
        user_row = df[df['Registration Number'].astype(str).str.strip() == unique_id.strip()]

        if user_row.empty:
            return jsonify({"error": "User not found"}), 404

        user_name = user_row.iloc[0]['Name']
        
        # Check if user has already marked attendance
        if os.path.exists(VERIFIED_IDS_FILE):
            verified_df = pd.read_csv(VERIFIED_IDS_FILE)
            if str(unique_id) in verified_df['Registration Number'].astype(str).values:
                return jsonify({
                    "Registration Number": unique_id,
                    "Name": user_name,
                    "warning": "Attendance already marked"
                }), 200

        return jsonify({"Registration Number": unique_id, "Name": user_name}), 200  

    except Exception as e:
        return jsonify({"error": f"Error reading CSV: {e}"}), 500


@app.route('/upload_unique_id/<unique_id>', methods=['POST'])
def upload_unique_id(unique_id):
    try:
        client_ip = request.remote_addr

        # Check IP tracking
        if os.path.exists(IP_TRACKING_FILE):
            ip_df = pd.read_csv(IP_TRACKING_FILE)
            if client_ip in ip_df['IP'].values:
                return jsonify({
                    "error": "Multiple attendance attempts detected",
                    "message": "Attendance has already been marked from this device. Multiple attempts are not allowed."
                }), 403

        # Check if ID already verified
        if os.path.exists(VERIFIED_IDS_FILE):
            verified_df = pd.read_csv(VERIFIED_IDS_FILE)
            if str(unique_id) in verified_df['Registration Number'].astype(str).values:
                return jsonify({
                    "error": "Duplicate attendance",
                    "message": "Your attendance has already been marked. Multiple attempts are not allowed."
                }), 403

        # Record new attendance
        current_time = datetime.datetime.now()
        
        # Save verified ID
        new_verification = pd.DataFrame({
            'Registration Number': [unique_id],
            'Timestamp': [current_time],
            'IP': [client_ip]
        })

        if os.path.exists(VERIFIED_IDS_FILE):
            verified_df = pd.read_csv(VERIFIED_IDS_FILE)
            verified_df = pd.concat([verified_df, new_verification], ignore_index=True)
        else:
            verified_df = new_verification
        verified_df.to_csv(VERIFIED_IDS_FILE, index=False)

        # Track IP
        new_ip = pd.DataFrame({
            'IP': [client_ip],
            'Timestamp': [current_time]
        })
        
        if os.path.exists(IP_TRACKING_FILE):
            ip_df = pd.read_csv(IP_TRACKING_FILE)
            ip_df = pd.concat([ip_df, new_ip], ignore_index=True)
        else:
            ip_df = new_ip
        ip_df.to_csv(IP_TRACKING_FILE, index=False)

        return jsonify({
            "message": "Attendance marked successfully",
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({"error": f"Error recording attendance: {e}"}), 500


@app.route('/attendance_stats', methods=['GET'])
def get_attendance_stats():
    """Get attendance statistics."""
    try:
        if not os.path.exists(CSV_FILE) or not os.path.exists(VERIFIED_IDS_FILE):
            return jsonify({
                "error": "Required files not found"
            }), 404

        # Read total students
        total_df = pd.read_csv(CSV_FILE)
        total_students = len(total_df)

        # Read present students
        present_df = pd.read_csv(VERIFIED_IDS_FILE, dtype={"Registration Number": str})  # Ensure reading as string
        present_student = set(
            str(reg_no).strip().split(".")[0]  # Convert to string and remove ".0"
            for reg_no in present_df['Registration Number'].dropna()  # Drop NaN values
        )

        present_students = len(present_student)

        return jsonify({
            "PresentStudents": list(present_student),  # Convert set to list
            "total": total_students,
            "present": present_students,
            "absent": total_students - present_students
        }), 200

    except Exception as e:
        return jsonify({"error": f"Error getting stats: {e}"}), 500


@app.route('/students', methods=['GET'])
def get_students():
    """Get all students with their attendance status."""
    try:
        if not os.path.exists(CSV_FILE):
            return jsonify({"error": "Student list not found"}), 404

        # Read all students
        students_df = pd.read_csv(CSV_FILE)

        # Read attendance data
        present_students = set()
        if os.path.exists(VERIFIED_IDS_FILE):
            present_df = pd.read_csv(VERIFIED_IDS_FILE, dtype={"Registration Number": str})  # Read as string
            present_students = set(
                str(reg_no).strip().split(".")[0]  # Remove ".0" if present
                for reg_no in present_df['Registration Number'].dropna()  # Drop NaN values
            )

        # Prepare student list with attendance status
        students_list = []
        for _, row in students_df.iterrows():
            reg_no = str(row['Registration Number']).strip().split(".")[0]  # Remove ".0"
            name = row['Name'].strip()
            students_list.append({
                "name": name,
                "registrationNumber": reg_no,
                "isPresent": reg_no in present_students,
                "initial": name[0].upper() if name else "?"
            })

        return jsonify({
            "students": students_list,
            "present_students": list(present_students)  # Return as a list for JSON compatibility
        }), 200

    except Exception as e:
        return jsonify({"error": f"Error getting students: {e}"}), 500

@app.route('/search_students/<query>', methods=['GET'])
def search_students(query):
    """Search students by name or registration number."""
    try:
        if not os.path.exists(CSV_FILE):
            return jsonify({"error": "Student list not found"}), 404

        # Read all students
        students_df = pd.read_csv(CSV_FILE)
        
        # Read attendance data
        present_students = set()
        if os.path.exists(VERIFIED_IDS_FILE):
            present_df = pd.read_csv(VERIFIED_IDS_FILE, dtype={"Registration Number": str})  # Read as string
            present_students = set(
                str(reg_no).strip().split(".")[0]  # Remove ".0" if present
                for reg_no in present_df['Registration Number'].dropna()  # Drop NaN values
            )

        # Filter students based on search query
        query = query.lower()
        filtered_students = students_df[
            students_df['Name'].str.lower().str.contains(query) |
            students_df['Registration Number'].astype(str).str.lower().str.contains(query)
        ]

        # Prepare filtered student list
        students_list = []
        for _, row in filtered_students.iterrows():
            reg_no = str(row['Registration Number']).strip().split(".")[0]  # Remove ".0"
            name = row['Name'].strip()
            students_list.append({
                "name": name,
                "registrationNumber": reg_no,
                "isPresent": reg_no in present_students,
                "initial": name[0].upper() if name else "?"
            })

        return jsonify({
            "students": students_list
        }), 200
    except Exception as e:
        return jsonify({"error": f"Error searching students: {e}"}), 500

@app.route('/mark_attendance', methods=['POST'])
def mark_attendance():
    """Mark attendance for a given registration number."""
    try:
        data = request.get_json()
        unique_id = data.get('registrationNumber')

        if not unique_id:
            logging.error("Registration number is required")
            return jsonify({"error": "Registration number is required"}), 400

        # Verify if the registration number exists in the CSV
        if not os.path.exists(CSV_FILE):
            logging.error("CSV file not found")
            return jsonify({"error": "CSV file not found"}), 404

        df = pd.read_csv(CSV_FILE)
        if 'Registration Number' not in df.columns:
            logging.error("Invalid CSV format")
            return jsonify({"error": "Invalid CSV format"}), 400

        if unique_id not in df['Registration Number'].astype(str).values:
            logging.warning(f"Registration number {unique_id} not found in CSV")
            return jsonify({"error": "Registration number not found"}), 404

        # Record new attendance
        current_time = datetime.datetime.now()
        
        # Save verified ID
        new_verification = pd.DataFrame({
            'Registration Number': [unique_id],
            'Timestamp': [current_time],
            'IP': [request.remote_addr]  # Optional: track the IP if needed
        })

        if os.path.exists(VERIFIED_IDS_FILE):
            verified_df = pd.read_csv(VERIFIED_IDS_FILE)
            verified_df = pd.concat([verified_df, new_verification], ignore_index=True)
        else:
            verified_df = new_verification
        verified_df.to_csv(VERIFIED_IDS_FILE, index=False)

        logging.info(f"Attendance marked successfully for {unique_id}")
        return jsonify({
            "message": f"Attendance marked successfully for {unique_id}",
            "status": "success"
        }), 200

    except Exception as e:
        logging.error(f"Error recording attendance: {e}")
        return jsonify({"error": f"Error recording attendance: {e}"}), 500

@app.route('/stress_test/start', methods=['POST'])
def start_stress_test():
    """Start tracking metrics for stress testing."""
    try:
        data = request.get_json() or {}
        concurrent_users = int(data.get('concurrentUsers', 10))
        
        if concurrent_users < 1 or concurrent_users > 1000:
            return jsonify({"error": "concurrentUsers must be between 1 and 1000"}), 400
        
        # Reset and start metrics tracking
        with _metrics_lock:
            _scalability_metrics['response_times'].clear()
            _scalability_metrics['concurrent_requests'] = concurrent_users
            _scalability_metrics['total_requests'] = 0
            _scalability_metrics['failed_requests'] = 0
            _scalability_metrics['start_time'] = time.perf_counter()
            _scalability_metrics['test_active'] = True
        
        logging.info(f"Stress test tracking started: expecting {concurrent_users} concurrent users")
        
        return jsonify({
            "message": "Stress test tracking started",
            "concurrentUsers": concurrent_users,
            "status": "tracking",
            "instructions": "Send requests to any endpoint. Metrics will be tracked automatically."
        }), 200
        
    except Exception as e:
        logging.exception("Error starting stress test tracking")
        return jsonify({"error": f"Error starting stress test: {e}"}), 500

@app.route('/stress_test/stop', methods=['POST'])
def stop_stress_test():
    """Stop tracking metrics and generate report."""
    try:
        with _metrics_lock:
            _scalability_metrics['test_active'] = False
        
        logging.info("Stress test tracking stopped")
        
        return jsonify({
            "message": "Stress test tracking stopped",
            "status": "stopped",
            "metrics_available": "/scalability_metrics",
            "report_available": "/scalability_report"
        }), 200
        
    except Exception as e:
        logging.exception("Error stopping stress test")
        return jsonify({"error": f"Error stopping stress test: {e}"}), 500

@app.route('/scalability_metrics', methods=['GET'])
def get_scalability_metrics():
    """Get current scalability metrics."""
    try:
        with _metrics_lock:
            metrics = {}
            
            # Calculate statistics for each endpoint
            for endpoint, times in _scalability_metrics['response_times'].items():
                if times:
                    times_sorted = sorted(times)
                    n = len(times)
                    metrics[endpoint] = {
                        'total_requests': n,
                        'mean_response_time': sum(times) / n,
                        'median_response_time': times_sorted[n // 2] if n > 0 else 0,
                        'min_response_time': min(times),
                        'max_response_time': max(times),
                        'p95_response_time': times_sorted[int(n * 0.95)] if n > 1 else times[0],
                        'p99_response_time': times_sorted[int(n * 0.99)] if n > 1 else times[0],
                    }
            
            return jsonify({
                'concurrent_users': _scalability_metrics['concurrent_requests'],
                'total_requests': _scalability_metrics['total_requests'],
                'failed_requests': _scalability_metrics['failed_requests'],
                'success_rate': (_scalability_metrics['total_requests'] - _scalability_metrics['failed_requests']) / max(_scalability_metrics['total_requests'], 1),
                'test_active': _scalability_metrics['test_active'],
                'endpoint_metrics': metrics,
                'elapsed_time': time.perf_counter() - _scalability_metrics['start_time'] if _scalability_metrics['start_time'] else 0
            }), 200
            
    except Exception as e:
        logging.exception("Error getting scalability metrics")
        return jsonify({"error": f"Error getting metrics: {e}"}), 500

@app.route('/scalability_report', methods=['GET'])
def generate_scalability_report():
    """Generate comprehensive scalability report."""
    try:
        with _metrics_lock:
            if not _scalability_metrics['response_times']:
                return jsonify({"error": "No metrics collected yet. Run stress test first."}), 400
            
            report = {
                'timestamp': datetime.datetime.now().isoformat(),
                'test_summary': {
                    'concurrent_users': _scalability_metrics['concurrent_requests'],
                    'total_requests': _scalability_metrics['total_requests'],
                    'failed_requests': _scalability_metrics['failed_requests'],
                    'success_rate': (_scalability_metrics['total_requests'] - _scalability_metrics['failed_requests']) / max(_scalability_metrics['total_requests'], 1),
                    'elapsed_time': time.perf_counter() - _scalability_metrics['start_time'] if _scalability_metrics['start_time'] else 0
                },
                'endpoint_analysis': {}
            }
            
            # Analyze each endpoint
            for endpoint, times in _scalability_metrics['response_times'].items():
                if times:
                    times_sorted = sorted(times)
                    n = len(times)
                    mean_time = sum(times) / n
                    
                    # Calculate throughput (requests per second)
                    elapsed = report['test_summary']['elapsed_time']
                    throughput = n / elapsed if elapsed > 0 else 0
                    
                    # Calculate standard deviation
                    variance = sum((t - mean_time) ** 2 for t in times) / n
                    std_dev = variance ** 0.5
                    
                    report['endpoint_analysis'][endpoint] = {
                        'total_requests': n,
                        'mean_response_time_ms': mean_time * 1000,
                        'median_response_time_ms': times_sorted[n // 2] * 1000,
                        'std_dev_ms': std_dev * 1000,
                        'min_response_time_ms': min(times) * 1000,
                        'max_response_time_ms': max(times) * 1000,
                        'p95_response_time_ms': times_sorted[int(n * 0.95)] * 1000 if n > 1 else times[0] * 1000,
                        'p99_response_time_ms': times_sorted[int(n * 0.99)] * 1000 if n > 1 else times[0] * 1000,
                        'throughput_rps': throughput,
                        'error_rate': _scalability_metrics['failed_requests'] / max(n, 1)
                    }
            
            # Save report to CSV
            _save_scalability_report(report)
            
            return jsonify(report), 200
            
    except Exception as e:
        logging.exception("Error generating scalability report")
        return jsonify({"error": f"Error generating report: {e}"}), 500

def _save_scalability_report(report):
    """Save scalability report to CSV file."""
    try:
        import csv
        
        # Append to CSV file (don't overwrite, accumulate results)
        file_exists = os.path.exists(SCALABILITY_METRICS_FILE)
        
        with open(SCALABILITY_METRICS_FILE, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            
            # Write header if file is new
            if not file_exists:
                writer.writerow([
                    'Timestamp',
                    'Endpoint',
                    'Concurrent Users',
                    'Total Requests',
                    'Failed Requests',
                    'Success Rate',
                    'Mean Response Time (ms)',
                    'Median Response Time (ms)',
                    'P95 Response Time (ms)',
                    'P99 Response Time (ms)',
                    'Throughput (req/s)',
                    'Error Rate'
                ])
            
            # Append data rows
            for endpoint, metrics in report['endpoint_analysis'].items():
                writer.writerow([
                    report['timestamp'],
                    endpoint,
                    report['test_summary']['concurrent_users'],
                    metrics['total_requests'],
                    report['test_summary']['failed_requests'],
                    f"{report['test_summary']['success_rate']:.4f}",
                    f"{metrics['mean_response_time_ms']:.3f}",
                    f"{metrics['median_response_time_ms']:.3f}",
                    f"{metrics['p95_response_time_ms']:.3f}",
                    f"{metrics['p99_response_time_ms']:.3f}",
                    f"{metrics['throughput_rps']:.2f}",
                    f"{metrics['error_rate']:.4f}"
                ])
        
        logging.info(f"Scalability report saved to {SCALABILITY_METRICS_FILE}")
    except Exception as e:
        logging.error(f"Error saving scalability report: {e}")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
