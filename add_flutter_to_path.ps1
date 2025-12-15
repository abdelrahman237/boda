# Quick script to add Flutter to PATH for current session
# Usage: .\add_flutter_to_path.ps1 "C:\path\to\flutter"

param(
    [Parameter(Mandatory=$true)]
    [string]$FlutterPath
)

$flutterBin = Join-Path $FlutterPath "bin"
$flutterBat = Join-Path $flutterBin "flutter.bat"

if (-not (Test-Path $flutterBat)) {
    Write-Host "Error: Flutter not found at: $FlutterPath" -ForegroundColor Red
    Write-Host "Expected flutter.bat at: $flutterBat" -ForegroundColor Yellow
    exit 1
}

# Add to current session PATH
if ($env:Path -notlike "*$flutterBin*") {
    $env:Path += ";$flutterBin"
    Write-Host "✓ Added Flutter to PATH: $flutterBin" -ForegroundColor Green
} else {
    Write-Host "✓ Flutter already in PATH" -ForegroundColor Green
}

# Test Flutter
Write-Host ""
Write-Host "Testing Flutter installation..." -ForegroundColor Yellow
flutter --version

Write-Host ""
Write-Host "You can now run:" -ForegroundColor Cyan
Write-Host "  flutter run -d chrome -t lib/vendor/main_vendor.dart" -ForegroundColor White

