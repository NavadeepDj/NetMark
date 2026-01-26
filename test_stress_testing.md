# Quick Test Guide - Stress Testing Features

## ✅ Step-by-Step Testing

### **1. Start Flask Server**
```powershell
# In Terminal 1
python Server_regNoSend.py
```

**Expected Output**:
```
 * Running on http://0.0.0.0:5000
 * Debug mode: on
```

### **2. Run a Simple Load Test**
```powershell
# In Terminal 2
python load_test.py --users 5 --requests 5 --server-tracking
```

**What to Check**:
- ✅ Script runs without errors
- ✅ Console output shows test progress
- ✅ Log file created in `stress_test_logs/`
- ✅ JSON results file created (`load_test_results.json`)
- ✅ Server responds to requests

### **3. Verify Logs Are Saved**
```powershell
# Check if log file exists
Get-ChildItem stress_test_logs\*.log

# View the log
Get-Content stress_test_logs\load_test_5users_*.log
```

**Expected**:
- Log file contains timestamped messages
- Test configuration is logged
- Results are logged

### **4. Check Server Metrics**
```powershell
# Get metrics
curl http://127.0.0.1:5000/scalability_metrics

# Generate report
curl http://127.0.0.1:5000/scalability_report
```

**Expected**:
- JSON response with metrics
- `scalability_metrics.csv` file created/updated

### **5. Verify CSV File**
```powershell
# Check CSV file
Get-Content scalability_metrics.csv
```

**Expected**:
- CSV file exists
- Contains header row
- Contains test data rows

---

## 🎯 Quick Test Command

Run this single command to test everything:

```powershell
# Start server in background, run test, check results
Start-Process python -ArgumentList "Server_regNoSend.py" -WindowStyle Hidden
Start-Sleep -Seconds 3
python load_test.py --users 5 --requests 5 --server-tracking
curl http://127.0.0.1:5000/scalability_metrics
```

---

## ⚠️ Troubleshooting

### **If server doesn't start**:
- Check if port 5000 is already in use
- Verify Python and Flask are installed
- Check for syntax errors in `Server_regNoSend.py`

### **If load test fails**:
- Ensure server is running first
- Check server URL is correct (default: http://127.0.0.1:5000)
- Verify `requests` library is installed: `pip install requests`

### **If logs aren't saved**:
- Check write permissions in project directory
- Verify `stress_test_logs/` directory is created
- Check disk space

---

## ✅ Success Indicators

You'll know everything works when:
1. ✅ Server starts without errors
2. ✅ Load test completes successfully
3. ✅ Log file exists in `stress_test_logs/`
4. ✅ JSON results file created
5. ✅ CSV metrics file created/updated
6. ✅ Server endpoints return data

---

## 🚀 Next Steps After Testing

Once everything works:
1. Run full test suite: `.\run_stress_tests.ps1`
2. Review logs in `stress_test_logs/`
3. Analyze results in `scalability_metrics.csv`
4. Include results in your documentation
