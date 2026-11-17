@echo off
title HomeStyle AI Backend - Setup
cd /d "%~dp0"
echo This will rebuild the Python environment using Python found on this PC.
echo.
set "PYEXE="

if exist "%USERPROFILE%\anaconda3\python.exe" set "PYEXE=%USERPROFILE%\anaconda3\python.exe"
if exist "C:\ProgramData\Anaconda3\python.exe" set "PYEXE=C:\ProgramData\Anaconda3\python.exe"
if exist "C:\Users\Azrar Link\anaconda3\python.exe" set "PYEXE=C:\Users\Azrar Link\anaconda3\python.exe"
if "%PYEXE%"=="" (
    echo [ERROR] No Anaconda Python found. Install Anaconda first.
    pause
    exit /b 1
)

if exist ".venv" rmdir /s /q ".venv"
echo Using: %PYEXE%
"%PYEXE%" -m venv .venv
if errorlevel 1 goto :fail

.venv\Scripts\python.exe -m pip install -q --upgrade pip
.venv\Scripts\python.exe -m pip install -q -r requirements.txt
if errorlevel 1 goto :fail

echo.
echo Setup complete. Run start_ai.bat to launch the server.
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Setup failed. Make sure you have internet access.
pause
exit /b 1
