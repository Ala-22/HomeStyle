@echo off
title HomeStyle AI Room Designer Server
cd /d "%~dp0"
echo ============================================
echo  HomeStyle AI Room Designer - Server
echo ============================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Python environment not found ^(venv^).
    echo Please run setup_ai.bat first, or reinstall Anaconda.
    echo.
    pause
    exit /b 1
)

echo Starting AI server on http://localhost:8000 ...
echo Keep this window OPEN while using the app.
echo.
.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
echo.
echo Server stopped. Press any key to close.
pause >nul
