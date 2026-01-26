#!/bin/bash
# Stress Testing Script for NetMark
# Runs multiple load tests with increasing concurrent users

echo "=========================================="
echo "NetMark Stress Testing Suite"
echo "=========================================="
echo ""

BASE_URL="http://127.0.0.1:5000"
ENDPOINT="/attendance_stats"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="stress_test_logs"

# Create logs directory
mkdir -p "$LOG_DIR"

echo "Test logs will be saved to: $LOG_DIR"
echo ""

# Test configurations: (concurrent_users, requests_per_user)
declare -a TEST_CONFIGS=(
    "5 10"
    "10 10"
    "20 10"
    "50 10"
    "100 5"
)

echo "Running stress tests with increasing load..."
echo ""

for config in "${TEST_CONFIGS[@]}"; do
    read -r users requests <<< "$config"
    echo "----------------------------------------"
    echo "Test: $users concurrent users, $requests requests each"
    echo "----------------------------------------"
    
    LOG_FILE="$LOG_DIR/load_test_${users}users_${TIMESTAMP}.log"
    
    python load_test.py \
        --url "$BASE_URL" \
        --endpoint "$ENDPOINT" \
        --users "$users" \
        --requests "$requests" \
        --delay 0.05 \
        --output "load_test_${users}users.json" \
        --log-file "$LOG_FILE" \
        --server-tracking
    
    echo ""
    sleep 2  # Brief pause between tests
done

echo "=========================================="
echo "All stress tests completed!"
echo "=========================================="
echo ""
echo "Results saved to:"
echo "  - load_test_*users.json files (test results)"
echo "  - $LOG_DIR/load_test_*users_*.log files (test logs)"
echo "  - scalability_metrics.csv (server-side)"
echo ""
echo "View server metrics: $BASE_URL/scalability_metrics"
echo "Generate report: $BASE_URL/scalability_report"
