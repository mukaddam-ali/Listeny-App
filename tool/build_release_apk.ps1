<#
.SYNOPSIS
    Builds Listeny's one-and-only distributable Android artifact: a single
    universal release APK containing every ABI Listeny ships (armeabi-v7a,
    arm64-v8a, x86_64), signed with the real release key.

.DESCRIPTION
    Listeny distributes exactly ONE Android APK - no separate per-ABI
    (armeabi-v7a/arm64-v8a/x86_64) split APKs. This script is the canonical
    way to build that artifact so a release never accidentally staples in
    stale split APKs from an earlier `--split-per-abi` build sitting in
    build/app/outputs/flutter-apk/.

    Equivalent to:
        flutter build apk --release --target-platform android-arm,android-arm64,android-x64

    (no --split-per-abi). Requires android/key.properties with real release
    signing credentials - android/app/build.gradle.kts refuses to build a
    release variant without it (never falls back to debug signing).

.EXAMPLE
    ./tool/build_release_apk.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path "android/key.properties")) {
    throw "android/key.properties not found - see android/key.properties.example. " +
        "A real release build requires real signing credentials; this script " +
        "refuses to proceed (matching the Gradle-level guard in android/app/build.gradle.kts)."
}

$flutterApkDir = "build/app/outputs/flutter-apk"

# Clean stale artifacts first so a leftover split-APK build (or a previous
# run's universal APK) can never be mistaken for this run's output below.
if (Test-Path $flutterApkDir) {
    Remove-Item -Recurse -Force "$flutterApkDir" -Confirm:$false
}

Write-Host "Building universal release APK (armeabi-v7a + arm64-v8a + x86_64)..." -ForegroundColor Cyan
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed (exit $LASTEXITCODE)" }

$apks = Get-ChildItem -Path $flutterApkDir -Filter "*.apk" -ErrorAction Stop
if ($apks.Count -eq 0) {
    throw "No APK produced in $flutterApkDir"
}
if ($apks.Count -gt 1) {
    throw "Expected exactly one universal APK but found $($apks.Count): " +
        "$($apks.Name -join ', ') - this usually means --split-per-abi got " +
        "applied somewhere. Refusing to stage multiple artifacts."
}
$apk = $apks[0]
if ($apk.Name -match "-(armeabi-v7a|arm64-v8a|x86_64)-") {
    throw "$($apk.Name) looks like a per-ABI split APK, not a universal one. Refusing to stage it."
}

# Pull version/applicationId straight from pubspec.yaml so the staged
# filename and the printed report can never drift from what was actually
# built.
$pubspecVersion = (Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(\S+)").Matches[0].Groups[1].Value
$versionName, $versionCode = $pubspecVersion -split "\+"

$stagingDir = "build/release_staging"
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null
# Remove any previously staged APKs so this directory never accumulates
# stale artifacts from earlier releases either.
Get-ChildItem -Path $stagingDir -Filter "*.apk" -ErrorAction SilentlyContinue | Remove-Item -Force -Confirm:$false

$stagedName = "Listeny-$versionName-$versionCode-universal.apk"
$stagedPath = Join-Path $stagingDir $stagedName
Copy-Item $apk.FullName $stagedPath -Force

$sha256 = (Get-FileHash -Path $stagedPath -Algorithm SHA256).Hash
$sizeBytes = (Get-Item $stagedPath).Length
$sizeMb = [Math]::Round($sizeBytes / 1MB, 1)

Write-Host ""
Write-Host "Universal release APK staged:" -ForegroundColor Green
Write-Host "  Path:          $stagedPath"
Write-Host "  Size:          $sizeBytes bytes (~$sizeMb MB)"
Write-Host "  versionName:   $versionName"
Write-Host "  versionCode:   $versionCode"
Write-Host "  SHA-256:       $sha256"
Write-Host ""
Write-Host "This is the ONLY artifact that should be uploaded for release - do not" -ForegroundColor Yellow
Write-Host "upload anything else from $flutterApkDir." -ForegroundColor Yellow
