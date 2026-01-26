# Stress Testing Script for NetMark (PowerShell)
# Runs multiple load tests with increasing concurrent users

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "NetMark Stress Testing Suite" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$BASE_URL = "http://127.0.0.1:5000"
$ENDPOINT = "/attendance_stats"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_DIR = "stress_test_logs"

# Create logs directory
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null

Write-Host "Test logs will be saved to: $LOG_DIR" -ForegroundColor Yellow
Write-Host ""

# Test configurations: (concurrent_users, requests_per_user)
$TEST_CONFIGS = @(
    @(5, 10),
    @(10, 10),
    @(20, 10),
    @(50, 10),
    @(100, 5)
)

Write-Host "Running stress tests with increasing load..." -ForegroundColor Yellow
Write-Host ""

foreach ($config in $TEST_CONFIGS) {
    $users = $config[0]
    $requests = $config[1]
    
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Test: $users concurrent users, $requests requests each" -ForegroundColor White
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $logFile = "$LOG_DIR\load_test_${users}users_${TIMESTAMP}.log"
    
    python load_test.py `
        --url $BASE_URL `
        --endpoint $ENDPOINT `
        --users $users `
        --requests $requests `
        --delay 0.05 `
        --output "load_test_${users}users.json" `
        --log-file $logFile `
        --server-tracking
    
    Write-Host ""
    Start-Sleep -Seconds 2  # Brief pause between tests
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "All stress tests completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results saved to:" -ForegroundColor Yellow
Write-Host "  - load_test_*users.json files (test results)"
Write-Host "  - $LOG_DIR\load_test_*users_*.log files (test logs)"
Write-Host "  - scalability_metrics.csv (server-side)"
Write-Host ""
Write-Host "View server metrics: $BASE_URL/scalability_metrics" -ForegroundColor Cyan
Write-Host "Generate report: $BASE_URL/scalability_report" -ForegroundColor Cyan
