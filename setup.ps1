# =============================================================
#  Rocket Game 2 – Flutter Setup Script
#  Runs in PowerShell (Admin nicht nötig)
# =============================================================

$ErrorActionPreference = "Stop"
$flutterDir = "C:\flutter"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Rocket Game 2 – Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1) Flutter SDK installieren (via git clone, stable branch)
if (Test-Path "$flutterDir\bin\flutter.bat") {
    Write-Host "[1/4] Flutter gefunden: $flutterDir" -ForegroundColor Green
} else {
    Write-Host "[1/4] Flutter SDK wird geklont (~400 MB, bitte warten)..." -ForegroundColor Yellow
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $flutterDir
    Write-Host "      Flutter SDK installiert." -ForegroundColor Green
}

# 2) Flutter zu PATH hinzufügen (für diese Session)
$env:PATH = "$flutterDir\bin;$env:PATH"

# Flutter dauerhaft zu PATH hinzufügen (User-Level)
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$flutterDir\bin*") {
    [System.Environment]::SetEnvironmentVariable(
        "PATH",
        "$flutterDir\bin;$userPath",
        "User"
    )
    Write-Host "      Flutter dauerhaft zu PATH hinzugefügt." -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/4] Flutter Version:" -ForegroundColor Yellow
flutter --version

# 3) Flutter-Projektstruktur generieren (android/, ios/, etc.)
Write-Host ""
Write-Host "[3/4] Flutter-Projekt wird generiert..." -ForegroundColor Yellow

# Unsere Dateien sichern
$libBackup  = Get-Content "lib\main.dart" -Raw -ErrorAction SilentlyContinue
$pubBackup  = Get-Content "pubspec.yaml"  -Raw -ErrorAction SilentlyContinue

# flutter create erzeugt android/, ios/, usw.
flutter create . --project-name rocket_game_v2 --org com.rocketsoftware --platforms android,ios --no-pub

# Unsere Dateien wiederherstellen (flutter create überschreibt sie)
if ($pubBackup)  { Set-Content "pubspec.yaml"  $pubBackup  -Encoding UTF8 -NoNewline }
if ($libBackup)  { Set-Content "lib\main.dart" $libBackup  -Encoding UTF8 -NoNewline }

Write-Host "      Projektstruktur erstellt." -ForegroundColor Green

# 4) Abhängigkeiten installieren
Write-Host ""
Write-Host "[4/4] Abhängigkeiten werden installiert..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Setup abgeschlossen!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Cyan
Write-Host "  1. Android Studio installieren (für Android-Build):"
Write-Host "     https://developer.android.com/studio"
Write-Host "  2. Android-Emulator starten oder Gerät per USB anschließen"
Write-Host "  3. flutter doctor  (zeigt was noch fehlt)"
Write-Host "  4. flutter run     (Spiel starten)"
Write-Host ""
