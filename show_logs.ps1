# Script to show recent face verification logs
Write-Host "=== Face Verification Logs ===" -ForegroundColor Cyan
Write-Host ""

# Check project root
$rootLog = "d:\NetMark\logs.csv"
if (Test-Path $rootLog) {
    Write-Host "📁 Found logs.csv in project root:" -ForegroundColor Green
    Write-Host "   Path: $rootLog" -ForegroundColor Gray
    Write-Host ""
    
    $content = Get-Content $rootLog
    if ($content.Count -le 1) {
        Write-Host "⚠️  File exists but only contains header (no logs yet)" -ForegroundColor Yellow
        Write-Host "   Header: $($content[0])" -ForegroundColor Gray
    } else {
        Write-Host "📊 Recent logs (showing last 20 entries):" -ForegroundColor Green
        Write-Host ""
        # Show header
        Write-Host $content[0] -ForegroundColor Cyan
        # Show last 20 entries
        $maxEntries = if ($content.Count - 1 -lt 20) { $content.Count - 1 } else { 20 }
        $content[1..$maxEntries] | ForEach-Object {
            Write-Host $_ -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Total entries: $($content.Count - 1)" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ logs.csv not found in project root" -ForegroundColor Red
    Write-Host ""
    Write-Host "Note: On mobile devices, logs may be written to app documents directory." -ForegroundColor Yellow
    Write-Host "Check the console output for the actual file path." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== End of Logs ===" -ForegroundColor Cyan
