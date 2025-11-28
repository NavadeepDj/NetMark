from flask import Flask, request, jsonify
import pandas as pd
import os
import datetime
import logging

app = Flask(__name__)

CSV_FILE = "user_data.csv"
VERIFIED_IDS_FILE = "verified_ids.csv"
IP_TRACKING_FILE = "ip_tracking.csv"

# Set up logging
logging.basicConfig(level=logging.INFO)

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
