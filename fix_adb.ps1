# Fix ADB Daemon Issue
# This script kills existing ADB processes and restarts the ADB server

Write-Host "Fixing ADB daemon issue..." -ForegroundColor Yellow

# Set ADB path (adjust if your Android SDK is in a different location)
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Check if ADB exists
if (-not (Test-Path $adbPath)) {
    Write-Host "ERROR: ADB not found at $adbPath" -ForegroundColor Red
    Write-Host "Please check your Android SDK installation and ANDROID_HOME environment variable" -ForegroundColor Red
    exit 1
}

Write-Host "Found ADB at: $adbPath" -ForegroundColor Green

# Kill any existing ADB processes
Write-Host "`nKilling existing ADB processes..." -ForegroundColor Yellow
Get-Process -Name "adb" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Kill ADB server explicitly
Write-Host "Stopping ADB server..." -ForegroundColor Yellow
& $adbPath kill-server 2>&1 | Out-Null
Start-Sleep -Seconds 1

# Start ADB server
Write-Host "Starting ADB server..." -ForegroundColor Yellow
& $adbPath start-server

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nADB server started successfully!" -ForegroundColor Green
    
    # Verify ADB is working
    Write-Host "`nVerifying ADB connection..." -ForegroundColor Yellow
    $devices = & $adbPath devices
    Write-Host $devices
    
    Write-Host "`nADB is now ready. You can run 'flutter run' again." -ForegroundColor Green
} else {
    Write-Host "`nERROR: Failed to start ADB server" -ForegroundColor Red
    Write-Host "Try the following:" -ForegroundColor Yellow
    Write-Host "1. Make sure no other programs are using ADB" -ForegroundColor Yellow
    Write-Host "2. Restart your computer if the issue persists" -ForegroundColor Yellow
    Write-Host "3. Check if port 5037 is being used by another process" -ForegroundColor Yellow
    exit 1
}
