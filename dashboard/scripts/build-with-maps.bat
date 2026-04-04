@echo off
REM build-with-maps.bat — Injects Google Maps API key from .env.local and builds
setlocal enabledelayedexpansion

cd /d "%~dp0.."

REM Read API key from .env.local
set API_KEY=
for /f "tokens=1,* delims==" %%a in ('findstr /i "GOOGLE_MAPS_API_KEY=" .env.local 2^>nul') do set API_KEY=%%b

if "!API_KEY!"=="" (
    echo [ERROR] .env.local not found or GOOGLE_MAPS_API_KEY not set
    echo Copy .env.example to .env.local and add your key, then try again.
    exit /b 1
)

echo [1/3] Google Maps API key loaded from .env.local
echo [2/3] Injecting key into web/index.html ...

REM Replace whatever Maps key is present with the local key.
python -c "import pathlib,re; p=pathlib.Path('web/index.html'); s=p.read_text(encoding='utf-8'); s=re.sub(r'(https://maps.googleapis.com/maps/api/js\?key=)[^\"\']+', r'\1' + '!API_KEY!', s); p.write_text(s, encoding='utf-8')"
if errorlevel 1 (
    echo [ERROR] Failed to inject API key into web/index.html
    exit /b 1
)

echo [3/3] Building Flutter Web ...
flutter build web
set BUILD_EXIT=%ERRORLEVEL%

REM Restore placeholder regardless of build result.
python -c "import pathlib,re; p=pathlib.Path('web/index.html'); s=p.read_text(encoding='utf-8'); s=re.sub(r'(https://maps.googleapis.com/maps/api/js\?key=)[^\"\']+', r'\1YOUR_GOOGLE_MAPS_API_KEY', s); p.write_text(s, encoding='utf-8')"
if errorlevel 1 (
    echo [ERROR] Failed to restore placeholder key in web/index.html
    exit /b 1
)

if not "%BUILD_EXIT%"=="0" (
    echo [ERROR] flutter build web failed with exit code %BUILD_EXIT%
    exit /b %BUILD_EXIT%
)

echo [done] index.html restored — safe to commit
