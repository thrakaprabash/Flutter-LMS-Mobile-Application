# Build and open the Flutter LMS Android app with one build worker.
param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
$previousJavaHome = $env:JAVA_HOME
$runExitCode = 1
Push-Location $projectDirectory
try {
    $buildTemp = Join-Path $projectDirectory '.build-tmp'
    New-Item -ItemType Directory -Force $buildTemp | Out-Null
    $env:TEMP = $buildTemp
    $env:TMP = $buildTemp
    $studioJava = Join-Path $env:ProgramFiles 'Android/Android Studio/jbr'
    if (Test-Path $studioJava) { $env:JAVA_HOME = $studioJava }
    $sdkLine = Get-Content android/local.properties | Where-Object { $_ -like 'sdk.dir=*' } | Select-Object -First 1
    if (-not $sdkLine) { throw 'Run flutter pub get first to generate Android local.properties.' }
    $androidSdk = $sdkLine.Substring(8).Replace('\\', '\').Replace('\:', ':')
    $adb = Join-Path $androidSdk 'platform-tools/adb.exe'
    Push-Location android
    try {
        ./gradlew.bat assembleDebug --no-daemon --max-workers=1 '-Ptarget=lib/main.dart' '-Ptarget-platform=android-x64'
        if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    } finally { Pop-Location }
    & $adb -s $Device install -r build/app/outputs/flutter-apk/app-debug.apk
    if ($LASTEXITCODE -ne 0) { throw 'Android installation failed. Check that the emulator is running.' }
    & $adb -s $Device shell am start -n com.example.flutter_lms/.MainActivity
    $runExitCode = $LASTEXITCODE
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
    $env:JAVA_HOME = $previousJavaHome
    Pop-Location
}
exit $runExitCode
