# Script to find Flutter installation and add to PATH

Write-Host "Searching for Flutter installation..." -ForegroundColor Yellow

# Common locations to check
$searchPaths = @(
    "$env:USERPROFILE\flutter",
    "$env:USERPROFILE\Downloads\flutter",
    "C:\src\flutter",
    "C:\flutter",
    "D:\flutter",
    "C:\Program Files\flutter",
    "C:\tools\flutter"
)

$foundFlutter = $null

foreach ($path in $searchPaths) {
    $flutterBat = Join-Path $path "bin\flutter.bat"
    if (Test-Path $flutterBat) {
        $foundFlutter = $path
        Write-Host "Found Flutter at: $foundFlutter" -ForegroundColor Green
        break
    }
}

if (-not $foundFlutter) {
    Write-Host "Flutter not found in common locations." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please provide the path where Flutter is installed:" -ForegroundColor Yellow
    Write-Host "Example: C:\src\flutter or C:\Users\YourName\flutter" -ForegroundColor Gray
    $manualPath = Read-Host "Enter Flutter path"
    
    if ($manualPath) {
        $flutterBat = Join-Path $manualPath "bin\flutter.bat"
        if (Test-Path $flutterBat) {
            $foundFlutter = $manualPath
            Write-Host "Flutter found at: $foundFlutter" -ForegroundColor Green
        } else {
            Write-Host "Flutter not found at: $manualPath" -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "No path provided. Exiting." -ForegroundColor Red
        exit
    }
}

# Add to current session PATH
$flutterBin = Join-Path $foundFlutter "bin"
if ($env:Path -notlike "*$flutterBin*") {
    $env:Path += ";$flutterBin"
    Write-Host "Added Flutter to current session PATH" -ForegroundColor Green
}

# Test Flutter
Write-Host ""
Write-Host "Testing Flutter..." -ForegroundColor Yellow
flutter --version

Write-Host ""
Write-Host "To make this permanent, add this to your PATH:" -ForegroundColor Yellow
Write-Host "$flutterBin" -ForegroundColor Cyan

