@echo off
REM run-with-maps.bat - Injects Google Maps API key from .env.local and runs Flutter Web
setlocal enabledelayedexpansion

set FLUTTER_DEVICE=%~1
if "!FLUTTER_DEVICE!"=="" set FLUTTER_DEVICE=edge

cd /d "%~dp0.."

REM Read API key from .env.local
set API_KEY=
for /f "tokens=1,* delims==" %%a in ('findstr /i "GOOGLE_MAPS_API_KEY=" .env.local 2^>nul') do set API_KEY=%%b

if "!API_KEY!"=="" (
    echo [ERROR] .env.local not found or GOOGLE_MAPS_API_KEY not set
    echo Copy .env.example to .env.local and add your key, then try again.
    exit /b 1
)

echo [1/4] Google Maps API key loaded from .env.local
echo [2/4] Injecting key into web/index.html ...

python scripts\maps_key_patch.py inject --key "!API_KEY!"
if errorlevel 1 (
    echo [ERROR] Failed to inject API key into web/index.html
    exit /b 1
)

echo [3/4] Running Flutter on device (!FLUTTER_DEVICE!) ...
call flutter run -d !FLUTTER_DEVICE!
set RUN_EXIT=%ERRORLEVEL%

echo [4/4] Restoring placeholder key in web/index.html ...
python scripts\maps_key_patch.py restore
if errorlevel 1 (
    echo [ERROR] Failed to restore placeholder key in web/index.html
    exit /b 1
)

if not "%RUN_EXIT%"=="0" (
    echo [ERROR] flutter run failed with exit code %RUN_EXIT%
    exit /b %RUN_EXIT%
)

echo [done] index.html restored - safe to commit
